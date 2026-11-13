-- Neovim init for the treemux sidebar (kiyoon/treemux, see tmux.conf): a
-- Neo-tree file explorer in a tmux pane right of the shell. It runs as
-- `NVIM_APPNAME=nvim-treemux nvim -u <this file>`, so its plugins, lockfile,
-- shada and state live under ~/.local/share/nvim-treemux and never touch the
-- editor's lazy-lock.json.
--
-- This is the only Neo-tree: the editor (~/.config/nvim) has it disabled.
-- The editor's lua/ directory is still on package.path for the shared
-- config.ignore_patterns filters (also used by its snacks pickers).
--
-- How the tree talks to the rest of the window:
--   * opening a file goes to an editor in the shell's pane through
--     nvim-tree-remote (Neo-tree's file_open_requested event): `<cr>` opens it
--     in the nvim already running there, or in an nvim split of the shell's
--     pane; `t` opens it in the shell's pane itself, without a split
--   * the editor's own keymap works here: every normal-mode key of
--     ~/.config/nvim/lua/plugins/astrocore.lua (and the chords of its plugin
--     specs) is forwarded to the editor nvim of this window, which then gets
--     focus; see `editor` below. Pickers, lazygit, terminals and images open
--     there, at full width, instead of inside this narrow pane
--   * `-` / `_` send the path under the cursor (with / without Enter) to the
--     shell's pane, `N-` to pane N of the window instead; ctrl+_ copies it to
--     a tmux buffer for prefix + ] (tmux-send)
--   * ctrl+h/j/k/l (and alt+h/j/k/l resize) go through smart-splits, so the
--     vim-aware tmux binds can leave the sidebar; ctrl+e focuses the editor
--     (the editor's ctrl+e comes back); Q, q, ctrl+q, ZZ, alt+q close the
--     sidebar from any buffer
--   * ctrl+m swaps the tree for the repository's changed files (Neo-tree's
--     git_status source) and back

local main = vim.fn.expand "~/.config/nvim"
package.path = ("%s/lua/?.lua;%s/lua/?/init.lua;%s"):format(main, main, package.path)

vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.o.termguicolors = true
vim.o.laststatus = 0
vim.o.cursorline = true
vim.o.showmode = false

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system { "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath }
end
vim.opt.rtp:prepend(lazypath)

local ignore_patterns = require "config.ignore_patterns"

--- The same plugin versions as the editor: a plugin the editor also has is
--- pinned to the branch and commit in its lazy-lock.json (unpinned
--- smart-splits/snacks masters broke the sidebar). After a `:Lazy update` in
--- the editor, `:Lazy sync` in the tree follows it. Plugins only the tree
--- uses follow the tree's own lockfile. Neo-tree is one of them: the editor
--- has it disabled, and lazy keeps a disabled plugin's lock entry frozen.
local lock = vim.json.decode(table.concat(vim.fn.readfile(main .. "/lazy-lock.json"), "\n"))
local tree_only = { ["neo-tree.nvim"] = true }
local function pinned(specs)
  for _, spec in ipairs(specs) do
    local name = spec[1]:match "[^/]+$"
    local entry = not tree_only[name] and lock[name]
    if entry then
      spec.branch, spec.commit = entry.branch, entry.commit
    end
  end
  return specs
end

--- neo-tree rewrites these lists in place at `setup()` time (glob -> Lua
--- pattern), so hand it copies.
--- @param list string[]
--- @return string[]
local function copy(list) return vim.list_extend({}, list) end

--- tmux-send key: send the selection or the path under the cursor, then
--- leave visual mode. Without a count tmux-send targets the previously used
--- pane, which is unset at first; target the shell's pane instead (treemux
--- passes it as g:nvim_tree_remote_tmux_pane). A count keeps tmux-send's
--- own `N-` = pane N targeting.
local function send(opts)
  return function()
    local send_opts = vim.tbl_extend("force", {}, opts or {})
    if vim.v.count == 0 then send_opts.pane_identifier = vim.g.nvim_tree_remote_tmux_pane end
    require("tmux_send").send_to_pane(send_opts)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)
  end
end

local function smart(fn)
  return function() require("smart-splits")[fn]() end
end

--- Close this sidebar: kill its own pane. That is all treemux's toggle.sh
--- does for a right sidebar (its width memory is /dev/null, see tmux.conf),
--- minus a toggle.sh run; the watcher exits once the pane is gone, and the
--- neighbouring column takes the space.
local function close_sidebar() vim.system { "tmux", "kill-pane", "-t", vim.env.TMUX_PANE } end

--- The editor: the nvim in another pane of this tmux window (the one
--- nvim-tree-remote opens files in). Found the way nvim-tree-remote finds it,
--- by a process in the pane listening on nvim's default server address
--- ($XDG_RUNTIME_DIR/nvim.<pid>.N); the tree itself listens elsewhere
--- (treemux's --listen), so it never matches. Linux only (/proc).
local editor = {}

--- @param pid string
--- @return string[]
local function children(pid)
  local f = io.open(("/proc/%s/task/%s/children"):format(pid, pid))
  if not f then return {} end
  local ids = vim.split(vim.trim(f:read "*a"), " ", { trimempty = true })
  f:close()
  return ids
end

--- @return { pane: string, addr: string }|nil
function editor.find()
  local own = vim.env.TMUX_PANE
  local runtime = vim.env.XDG_RUNTIME_DIR or ""
  for _, line in ipairs(vim.fn.systemlist { "tmux", "list-panes", "-t", own, "-F", "#{pane_id} #{pane_pid}" }) do
    local pane, pid = line:match "^(%%%d+) (%d+)$"
    if pane and pane ~= own then
      local queue = { pid } -- the TUI nvim's server is its `nvim --embed` child
      while #queue > 0 do
        local p = table.remove(queue, 1)
        local addr = vim.fn.glob(("%s/nvim.%s.*"):format(runtime, p), false, true)[1]
        if addr then return { pane = pane, addr = addr } end
        vim.list_extend(queue, children(p))
      end
    end
  end
end

--- No editor yet: start one in a split above the shell's pane, where
--- nvim-tree-remote would (treemux's editor position/size), and register this
--- sidebar with it so prefix + Tab from that pane closes the sidebar too.
--- TREEMUX_EDITOR tells its VimEnter not to restore a session or open the
--- file picker: the forwarded key decides what it shows.
--- @return { pane: string, addr: string }|nil
function editor.spawn()
  local shell = vim.g.nvim_tree_remote_tmux_pane
  local cwd = vim.trim(vim.fn.system { "tmux", "display-message", "-p", "-t", shell, "#{pane_current_path}" })
  local pane = vim.trim(vim.fn.system {
    "tmux", "split-window", "-v", "-b", "-l", vim.g.nvim_tree_remote_tmux_split_size or "70%",
    "-t", shell, "-c", cwd, "-e", "TREEMUX_EDITOR=1", "-P", "-F", "#{pane_id}", "nvim",
  })
  if vim.v.shell_error ~= 0 then return nil end
  vim.fn.system { vim.g.nvim_tree_remote_treemux_path .. "/scripts/register_sidebar.sh", pane, vim.env.TMUX_PANE }
  local found
  vim.wait(5000, function()
    found = editor.find()
    return found ~= nil
  end, 50)
  return found
end

--- Focus the editor (starting one if needed) and run `fn(channel)` on an RPC
--- channel to it.
--- @param fn fun(chan: integer)
function editor.run(fn)
  local target = editor.find() or editor.spawn()
  if not target then
    vim.notify("No editor nvim in this tmux window", vim.log.levels.ERROR, { title = "treemux" })
    return
  end
  vim.fn.system { "tmux", "select-pane", "-t", target.pane }
  local ok, chan = pcall(vim.fn.sockconnect, "pipe", target.addr, { rpc = true })
  if not ok or chan == 0 then
    vim.notify("Cannot reach the editor at " .. target.addr, vim.log.levels.ERROR, { title = "treemux" })
    return
  end
  local done, err = pcall(fn, chan)
  vim.fn.chanclose(chan)
  if not done then vim.notify(tostring(err), vim.log.levels.ERROR, { title = "treemux" }) end
end

--- A mapping that types `lhs` into the editor, so its own mapping runs there.
--- <C-\><C-n> first leaves insert/terminal mode; <Leader> is the editor's
--- leader, Space.
--- @param lhs string
function editor.keys(lhs)
  local keys = "<C-\\><C-n>" .. (lhs:gsub("<[Ll]eader>", "<Space>"))
  return function()
    editor.run(function(chan) vim.rpcrequest(chan, "nvim_input", keys) end)
  end
end

--- A mapping that runs Lua in the editor; `args` reaches the code as `args`.
--- Scheduled there, so the RPC call returns before a picker or terminal opens.
--- @param code string
--- @param args? fun(state: table|nil): any[] built when the key is pressed
function editor.lua(code, args)
  return function(state)
    local values = args and args(state) or {}
    editor.run(function(chan)
      vim.rpcrequest(chan, "nvim_exec_lua", "local args = ... vim.schedule(function() " .. code .. " end)", { values })
    end)
  end
end

--- A snacks terminal running `cmd` in the editor (hidden, interactive).
--- @param cmd string|fun(state: table): string
--- @param opts? table extra snacks.terminal options
function editor.term(cmd, opts)
  opts = vim.tbl_extend("force", { hidden = true, interactive = true }, opts or {})
  return editor.lua('require("snacks").terminal(args[1], args[2])', function(state)
    return { type(cmd) == "function" and cmd(state) or cmd, opts }
  end)
end

--- Focus the editor's pane, or the shell's when there is no editor.
function editor.focus()
  local target = editor.find()
  vim.fn.system { "tmux", "select-pane", "-t", target and target.pane or vim.g.nvim_tree_remote_tmux_pane }
end

--- Normal-mode keys of the editor that are not forwarded: they act on the
--- text under the editor's cursor (fold, diagnostic jumps, select all, paste,
--- close buffer), or the tree has its own meaning for them (H/L, <Tab> =
--- <C-i> selects nodes, and the focus/close keys mapped below).
local not_forwarded = {
  F = true, J = true, K = true, T = true, vv = true, ["<C-p>"] = true, ["<C-c>"] = true,
  H = true, L = true, ["<C-i>"] = true,
  ["<C-e>"] = true, ["<C-q>"] = true, ZZ = true, ["<A-q>"] = true,
}

--- Every key to forward: astrocore.lua's normal-mode mappings (group labels
--- have no rhs), the <C-…>/<Leader>… chords of the plugin specs' `keys`
--- (single letters such as flash's s/S are motions, which stay the tree's),
--- and the <Leader>u prefix, whose toggles config.toggles maps at runtime
--- (the editor's which-key takes the next key once it has focus).
--- @return string[]
function editor.mappings()
  local lhs = { "<Leader>u" }
  local ok, spec = pcall(dofile, main .. "/lua/plugins/astrocore.lua")
  if ok then
    for key, map in pairs(vim.tbl_get(spec, "opts", "mappings", "n") or {}) do
      if type(map) == "table" and map[1] ~= nil and not not_forwarded[key] then table.insert(lhs, key) end
    end
  end
  for _, file in ipairs(vim.fn.glob(main .. "/lua/plugins/*.lua", false, true)) do
    local loaded, specs = pcall(dofile, file)
    specs = loaded and type(specs) == "table" and (type(specs[1]) == "string" and { specs } or specs) or {}
    for _, plugin in ipairs(specs) do
      for _, key in ipairs(type(plugin) == "table" and type(plugin.keys) == "table" and plugin.keys or {}) do
        local mode = type(key) == "table" and key.mode or "n"
        local n = mode == "n" or (type(mode) == "table" and vim.tbl_contains(mode, "n"))
        if type(key) == "table" and type(key[1]) == "string" and n and key[1]:match "^<[CcLl]" then
          table.insert(lhs, key[1])
        end
      end
    end
  end
  return lhs
end

local neotree_opts = {
  -- git_status: the repository's changed files only, toggled by <C-m>
  sources = { "filesystem", "git_status" },
  close_if_last_window = false,
  popup_border_style = "rounded",
  enable_diagnostics = true,
  git_status_async = true,
  -- treemux reveals the shell's cwd and, when the cursor does not land on it,
  -- assumes it is filtered and toggles hidden files on. The cwd is the root at
  -- first, and a hidden root node is never landed on, so every new sidebar
  -- came up showing everything ignore_patterns hides.
  hide_root_node = false,
  sort_case_insensitive = false,
  source_selector = { winbar = false, statusline = false },
  -- AstroNvim's Neo-tree commands, which the editor's tree had
  commands = {
    system_open = function(state) vim.ui.open(state.tree:get_node():get_id()) end,
    parent_or_close = function(state)
      local node = state.tree:get_node()
      if node:has_children() and node:is_expanded() then
        state.commands.toggle_node(state)
      else
        require("neo-tree.ui.renderer").focus_node(state, node:get_parent_id())
      end
    end,
    child_or_open = function(state)
      local node = state.tree:get_node()
      if not node:has_children() then
        state.commands.open(state)
      elseif not node:is_expanded() then
        state.commands.toggle_node(state)
      elseif node.type == "file" then
        state.commands.open(state)
      else
        require("neo-tree.ui.renderer").focus_node(state, node:get_child_ids()[1])
      end
    end,
    copy_selector = function(state)
      local node = state.tree:get_node()
      local filepath, filename, modify = node:get_id(), node.name, vim.fn.fnamemodify
      local vals = {
        ["BASENAME"] = modify(filename, ":r"),
        ["EXTENSION"] = modify(filename, ":e"),
        ["FILENAME"] = filename,
        ["PATH (CWD)"] = modify(filepath, ":."),
        ["PATH (HOME)"] = modify(filepath, ":~"),
        ["PATH"] = filepath,
        ["URI"] = vim.uri_from_fname(filepath),
      }
      local options = vim.tbl_filter(function(val) return vals[val] ~= "" end, vim.tbl_keys(vals))
      table.sort(options)
      vim.ui.select(options, {
        prompt = "Choose to copy to clipboard:",
        format_item = function(item) return ("%s: %s"):format(item, vals[item]) end,
      }, function(choice)
        if not vals[choice] then return end
        vim.notify(("Copied: `%s`"):format(vals[choice]))
        vim.fn.setreg("+", vals[choice])
      end)
    end,
    -- Swap the tree for the repository's changed files (git_status: modified,
    -- staged, untracked, ...) and back. Both render in this window; the
    -- shell's next cd follows it in the filesystem tree again.
    toggle_git_modified = function(state)
      local command = require "neo-tree.command"
      if state.name == "git_status" then
        command.execute { source = "filesystem", position = "current" }
      else
        command.execute { source = "git_status", position = "current", dir = state.path }
      end
    end,
  },
  window = {
    auto_expand_width = false,
    -- keys must be spelled exactly like neo-tree's own defaults: setup() does
    -- not case-normalize them, so `<CR>` would sit next to the default `<cr>`
    -- and whichever `pairs()` reached last would win. Filesystem-only
    -- commands go in filesystem.window.mappings: these apply to git_status
    -- too, where they would be invalid.
    mappings = {
      -- AstroNvim's layer (<S-CR> was overridden to "open" in the editor)
      ["O"] = "system_open",
      ["Y"] = "copy_selector",
      ["h"] = "parent_or_close",
      ["l"] = "child_or_open",
      -- Space is the leader (forwarded editor keys), not toggle_node
      ["<space>"] = "none",
      -- <C-m> is its own key, apart from <cr>, through tmux's extended-keys
      ["<C-m>"] = "toggle_git_modified",
      -- the open commands fire file_open_requested, handled below
      ["<cr>"] = "open",
      ["<S-CR>"] = "open",
      -- Git keybindings, mirroring the editor's astrocore.lua; pickers,
      -- lazygit and terminals run in the editor
      ["<C-g>o"] = function() vim.cmd "!gh repo view --web" end,
      ["<C-g>h"] = editor.term("gh dash", { auto_close = false }),
      ["<C-g>g"] = editor.lua 'require("snacks").lazygit()',
      ["<C-g>d"] = editor.lua 'require("snacks").picker.git_diff()',
      ["<C-g>b"] = editor.lua 'require("snacks").picker.git_branches()',
      ["<C-t>l"] = editor.term("lazydocker", { auto_close = true, start_in_insert = true }),
      ["<C-t>."] = editor.term("yazi", { auto_close = true, start_in_insert = true }),
      ["<C-t>t"] = editor.lua 'require("snacks").terminal()',
      ["Q"] = close_sidebar,
      -- neo-tree's close_window would leave an empty nvim in the pane
      ["q"] = close_sidebar,
      -- Open yazi in a detached kitty OS window at the node's directory
      ["N"] = function(state)
        local node = state.tree:get_node()
        local path = node.type == "directory" and node.path or vim.fs.dirname(node.path)
        vim.fn.jobstart { "kitty", "--detach", "--directory", path, "yazi" }
      end,
    },
    fuzzy_finder_mappings = {
      ["<C-J>"] = "move_cursor_down",
      ["<C-K>"] = "move_cursor_up",
    },
  },
  default_component_configs = {
    container = { enable_character_fade = true },
    indent = {
      indent_size = 2,
      padding = 1,
      with_markers = true,
      indent_marker = "│",
      last_indent_marker = "└",
      highlight = "NeoTreeIndentMarker",
      expander_collapsed = "",
      expander_expanded = "",
      expander_highlight = "NeoTreeExpander",
    },
    name = { trailing_slash = false, use_git_status_colors = true, highlight = "NeoTreeFileName" },
    git_status = {
      symbols = {
        -- change type: empty where the name already carries git colors
        added = "",
        modified = "",
        deleted = "✖",
        renamed = "󰁕",
        -- status type
        untracked = "",
        ignored = "",
        unstaged = "󰄱",
        staged = "",
        conflict = "",
      },
    },
    -- extra columns, each only rendered once the pane is wide enough
    file_size = { enabled = true, width = 12, required_width = 48 },
    type = { enabled = true, width = 10, required_width = 122 },
    last_modified = { enabled = true, width = 20, required_width = 88 },
    created = { enabled = true, width = 20, required_width = 110 },
    symlink_target = { enabled = false },
  },
  filesystem = {
    window = {
      mappings = {
        ["H"] = "navigate_up",
        ["L"] = "set_root",
        ["<bs>"] = "toggle_hidden",
        ["."] = "toggle_hidden",
        ["/"] = "fuzzy_finder",
        ["f"] = "filter_on_submit",
        ["<C-x>"] = "clear_filter",
        ["<leader>p"] = "image_kitty",
      },
    },
    commands = {
      -- Preview an image with kitty's icat kitten in a snacks terminal in the
      -- editor (this pane is too narrow for it)
      image_kitty = function(state)
        local node = state.tree:get_node()
        if node and node.type == "file" then
          editor.term("kitten icat --hold " .. vim.fn.shellescape(node.path), { auto_close = false })()
        else
          vim.notify("Not a file", vim.log.levels.WARN, { title = "Neo-tree" })
        end
      end,
    },
    bind_to_cwd = true,
    -- treemux starts nvim on the root directory; the tree comes from its
    -- +Neotree, not from hijacking that directory buffer. Following the
    -- "current file" would then chase that directory buffer, which is the
    -- root node, and neo-tree recursed until the stack overflowed; treemux
    -- itself keeps the tree on the shell's cwd.
    hijack_netrw_behavior = "disabled",
    follow_current_file = { enabled = false },
    use_libuv_file_watcher = true,
    filtered_items = {
      force_visible_in_empty_folder = false,
      show_hidden_count = false,
      hide_dotfiles = false,
      hide_gitignored = true,
      -- gitignore-style ignore files, read per directory by neo-tree
      hide_ignored = true,
      ignore_files = { ".neotreeignore", ".ignore", ".rgignore" },
      -- hide_by_pattern / never_show / never_show_by_pattern are seeded from
      -- config.ignore_patterns in `config` below
    },
  },
  event_handlers = {
    {
      event = "file_open_requested",
      handler = function(args)
        local remote = require "nvim_tree_remote"
        local tmux_opts = remote.tmux_defaults()
        local open_cmd = args.open_cmd
        -- `t` (open_tabnew): open in the shell's pane itself, no split
        if open_cmd == "tabnew" then
          tmux_opts.split_position = ""
          open_cmd = "edit"
        end
        remote.remote_nvim_open(nil, open_cmd, args.path, tmux_opts)
        return { handled = true }
      end,
    },
  },
}

-- git reports ignored paths in a second pass, and neo-tree's own
-- GIT_STATUS_CHANGED handler only redraws the nodes it already has, so `!!`
-- entries that land after the first scan stay visible until something
-- rescans. Rescan once per worktree (the flag also keeps this from looping on
-- the status the rescan itself kicks off).
local rescanned = {} ---@type table<string, true>
table.insert(neotree_opts.event_handlers, {
  event = "git_status_changed",
  handler = function(args)
    local root = args and args.git_root
    if root == nil or rescanned[root] then return end
    rescanned[root] = true
    require("neo-tree.sources.manager").refresh "filesystem"
  end,
})

require("lazy").setup(pinned {
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("cyberdream").setup { variant = "muted", transparent = true, hide_fillchars = true }
      vim.cmd.colorscheme "cyberdream"
    end,
  },
  -- Neo-tree asks nvim-web-devicons for icons; mini.icons stands in for it,
  -- as in the editor
  {
    "nvim-mini/mini.icons",
    lazy = false,
    config = function()
      require("mini.icons").setup()
      require("mini.icons").mock_nvim_web_devicons()
    end,
  },
  -- notifier: without one, a long message leaves Neo-tree waiting on "Press
  -- ENTER"
  { "folke/snacks.nvim", lazy = false, priority = 900, opts = { notifier = { enabled = true } } },
  {
    "mrjones2014/smart-splits.nvim",
    -- after the first paint: loading sets @pane-is-vim through tmux calls
    event = "VeryLazy",
    keys = {
      { "<C-h>", smart "move_cursor_left", desc = "Move to left split/pane" },
      { "<C-j>", smart "move_cursor_down", desc = "Move to split/pane below" },
      { "<C-k>", smart "move_cursor_up", desc = "Move to split/pane above" },
      { "<C-l>", smart "move_cursor_right", desc = "Move to right split/pane" },
      { "<M-h>", smart "resize_left", desc = "Resize left" },
      { "<M-j>", smart "resize_down", desc = "Resize down" },
      { "<M-k>", smart "resize_up", desc = "Resize up" },
      { "<M-l>", smart "resize_right", desc = "Resize right" },
    },
  },
  {
    "kiyoon/tmux-send.nvim",
    keys = {
      { "-", send(), mode = { "n", "x" }, desc = "Send to tmux pane" },
      { "_", send { add_newline = false }, mode = { "n", "x" }, desc = "Send to tmux pane (no Enter)" },
      {
        "<C-_>",
        function()
          require("tmux_send").save_to_tmux_buffer()
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)
        end,
        mode = { "n", "x" },
        desc = "Copy to a tmux buffer (paste: prefix ])",
      },
    },
  },
  { "kiyoon/nvim-tree-remote.nvim", lazy = true },
  { "nvim-lua/plenary.nvim", lazy = true },
  { "MunifTanjim/nui.nvim", lazy = true },
  {
    "nvim-neo-tree/neo-tree.nvim",
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    opts = neotree_opts,
    config = function(_, opts)
      -- setup() compiles the glob lists into Lua patterns in place, so seed
      -- them from the shared module on every setup (`:Lazy reload` re-runs
      -- this with the same opts table)
      local filtered = opts.filesystem.filtered_items
      filtered.hide_by_pattern = copy(ignore_patterns.patterns)
      filtered.never_show = copy(ignore_patterns.never_show)
      filtered.never_show_by_pattern = copy(ignore_patterns.never_show_patterns)
      require("neo-tree").setup(opts)
    end,
  },
}, {
  lockfile = vim.fn.stdpath "data" .. "/lazy-lock.json",
  install = { colorscheme = { "cyberdream" } },
  change_detection = { enabled = false },
  rocks = { enabled = false },
  performance = {
    rtp = { disabled_plugins = { "gzip", "matchit", "matchparen", "netrwPlugin", "tarPlugin", "tohtml", "tutor", "zipPlugin" } },
  },
})

-- The editor's keymap, forwarded (see `editor`). Neo-tree's buffer-local
-- maps above win over these where both exist, as they did in the editor.
for _, lhs in ipairs(editor.mappings()) do
  vim.keymap.set("n", lhs, editor.keys(lhs), { desc = "Editor: " .. lhs })
end
-- The editor's keys with a sidebar meaning here
vim.keymap.set("n", "<C-e>", editor.focus, { desc = "Focus the editor (back from the tree)" })
-- Q (and the editor's quit keys) close the sidebar from any buffer here,
-- not only the tree (after :help, a picker, ...)
for _, lhs in ipairs { "Q", "<C-q>", "ZZ", "<A-q>" } do
  vim.keymap.set("n", lhs, close_sidebar, { desc = "Close the treemux sidebar" })
end
vim.keymap.set("n", "T", "gg", { desc = "Go to top of the tree" })
