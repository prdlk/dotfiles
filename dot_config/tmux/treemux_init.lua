-- Neovim init for the treemux sidebar (kiyoon/treemux, see tmux.conf): a
-- Neo-tree file explorer in a tmux pane left of the shell. It runs as
-- `NVIM_APPNAME=nvim-treemux nvim -u <this file>`, so its plugins, lockfile,
-- shada and state live under ~/.local/share/nvim-treemux and never touch the
-- editor's lazy-lock.json.
--
-- This is the only Neo-tree: the editor (~/.config/nvim) has it disabled.
-- The editor's lua/ directory is still on package.path for the shared
-- config.ignore_patterns filters (also used by its snacks pickers).
--
-- How the tree talks to the rest of the session:
--   * opening a file goes to the editor (see `editor` below): the nvim in
--     another pane of this tmux window, else a new nvim split off the
--     shell's pane in this window (@treemux-editor-position / -size).
--     `<cr>` opens it there and focuses it; `t` opens it in the shell's
--     pane itself
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
--     sidebar from any buffer, in every window when it is persistent
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

--- Split glob lists into plain names and real globs. Neo-tree tests every
--- entry against each `*_by_pattern` Lua pattern in turn (most of the shared
--- list is plain names), but looks `hide_by_name` / `never_show` up in a
--- table, so a plain name costs one hash lookup instead of a pattern scan.
--- @param globs string[]
--- @return string[] names, string[] patterns
local function split_globs(globs)
  local names, patterns = {}, {}
  for _, glob in ipairs(globs) do
    table.insert(glob:find "[%*%?%[{/]" and patterns or names, glob)
  end
  return names, patterns
end

--- File icons from mini.icons, without paying its per-name
--- vim.filetype.match() fallback (~0.1 ms) for every file: that was a third
--- of the render time in a 5000-entry directory like /usr/lib or /usr/bin.
--- Names mini lists get its own icon; otherwise the last extension decides
--- (trailing version numbers dropped: libfoo.so.1.2 -> so), which mini
--- caches per extension. Only names that can carry a filename-based
--- filetype (capitalised like Makefile / Dockerfile, dotfiles like
--- .gitignore, and a few lower-case build files) go through the full lookup;
--- binaries and versioned libraries get the default file icon.
local explicit_files
local lower_build_files = {
  makefile = true, gnumakefile = true, justfile = true, dockerfile = true,
  containerfile = true, rakefile = true, gemfile = true, brewfile = true,
}
local function file_icon(name)
  local icons = require "mini.icons"
  if not explicit_files then
    explicit_files = {}
    for _, n in ipairs(icons.list "file") do explicit_files[n] = true end
  end
  if explicit_files[name] then return icons.get("file", name) end
  local ext = name:gsub("%.%d[%d.]*$", ""):match "^.+%.([^.]+)$"
  if ext then
    local icon, hl, is_default = icons.get("extension", ext)
    if not is_default then return icon, hl end
  end
  if name:find "^[%u.]" or lower_build_files[name] then return icons.get("file", name) end
  return icons.get("default", "file")
end

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
--- does for a sidebar (its width memory is /dev/null, see tmux.conf),
--- minus a toggle.sh run; the watcher exits once the pane is gone, and the
--- neighbouring column takes the space. A persistent sidebar (one in every
--- window) would come straight back, so there it closes all of them, as
--- workmux's sidebar quit does; tmux runs that, since it kills this nvim.
local function close_sidebar()
  if vim.trim(vim.fn.system { "tmux", "show-option", "-gqv", "@treemux-persistent" }) == "on" then
    local script = vim.g.nvim_tree_remote_treemux_path .. "/scripts/persistent.sh"
    vim.system { "tmux", "run-shell", "-b", vim.fn.shellescape(script) .. " off" }
  else
    vim.system { "tmux", "kill-pane", "-t", vim.env.TMUX_PANE }
  end
end

--- The editor: the nvim in another pane of this tmux window. Found by a
--- process in the pane listening on nvim's default server address
--- ($XDG_RUNTIME_DIR/nvim.<pid>.N), the way nvim-tree-remote finds it; a tree
--- listens elsewhere (treemux's --listen), so it never matches. Linux only
--- (/proc).
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

--- The nvim in another pane of this window.
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

--- The project the tree shows: the git root of its cwd (Neo-tree binds the
--- cwd to the tree root), else the cwd. The editor starts there.
--- @return string
local function project_root()
  local cwd = vim.fn.getcwd()
  local top = vim.trim(vim.fn.system { "git", "-C", cwd, "rev-parse", "--show-toplevel" })
  return vim.v.shell_error == 0 and top ~= "" and top or cwd
end

--- tmux split-window flags per treemux editor position
--- (@treemux-editor-position, passed as g:nvim_tree_remote_tmux_split_position)
local split_flags = { top = { "-v", "-b" }, bottom = { "-v" }, left = { "-h", "-b" }, right = { "-h" } }

--- The editor: the nvim in another pane of this window. With `create`, a
--- missing one is made: nvim split off the shell's pane at
--- @treemux-editor-position / @treemux-editor-size (treemux's defaults: top,
--- 70%), at the project root. TREEMUX_EDITOR tells its VimEnter not to
--- restore a session or open the file picker: the opened file or forwarded
--- key decides what it shows.
--- @param create boolean
--- @return { pane: string, addr: string }|nil
function editor.locate(create)
  local found = editor.find()
  if found or not create then return found end
  local cmd = { "tmux", "split-window", "-d", "-t", vim.g.nvim_tree_remote_tmux_pane }
  vim.list_extend(cmd, split_flags[vim.g.nvim_tree_remote_tmux_split_position] or split_flags.top)
  local size = vim.g.nvim_tree_remote_tmux_split_size
  if size and size ~= "" then vim.list_extend(cmd, { "-l", size }) end
  vim.list_extend(cmd, { "-c", project_root(), "-e", "TREEMUX_EDITOR=1", "nvim" })
  vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then return nil end
  vim.wait(5000, function()
    found = editor.find()
    return found ~= nil
  end, 50)
  return found
end

--- Show the editor's pane.
--- @param pane string
local function show(pane) vim.fn.system { "tmux", "select-pane", "-t", pane } end

--- Focus the editor (creating it if needed) and run `fn(channel)` on an RPC
--- channel to it.
--- @param fn fun(chan: integer)
function editor.run(fn)
  local target = editor.locate(true)
  if not target then
    vim.notify("Could not start an editor nvim", vim.log.levels.ERROR, { title = "treemux" })
    return
  end
  show(target.pane)
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

--- Focus the editor, or the shell's pane when there is none yet.
function editor.focus()
  local target = editor.locate(false)
  if target then
    show(target.pane)
  else
    vim.fn.system { "tmux", "select-pane", "-t", vim.g.nvim_tree_remote_tmux_pane }
  end
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

--- Neo-tree's indent component, without the space the renderer put before
--- the icon of a top-level node: under the hidden root with padding 0 its
--- indent is "", and the renderer pads whatever follows text that does not
--- end in a space. Rendering nothing instead leaves the icon in column 0.
local function indent(config, node, state)
  local result = require("neo-tree.sources.common.components").indent(config, node, state)
  if result.text ~= "" then return result end
end

local neotree_opts = {
  -- git_status: the repository's changed files only, toggled by <C-m>
  sources = { "filesystem", "git_status" },
  close_if_last_window = false,
  popup_border_style = "rounded",
  enable_diagnostics = true,
  git_status_async = true,
  -- No root line: the tree starts at the root's children, flush left
  -- (retain_hidden_root_indent off). treemux's follow.lua does not try to
  -- land on the hidden root, which would read as a filtered directory and
  -- turn hidden files on.
  hide_root_node = true,
  retain_hidden_root_indent = false,
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
    icon = {
      provider = function(icon, node)
        if node.type == "file" then
          icon.text, icon.highlight = file_icon(node.name)
        end
      end,
    },
    indent = {
      indent_size = 2,
      padding = 0,
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
    components = { indent = indent },
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
    -- itself keeps the tree on the shell's cwd. The editor's current file is
    -- revealed by `treemux_reveal` below instead.
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
  git_status = { components = { indent = indent } },
  event_handlers = {
    {
      event = "file_open_requested",
      handler = function(args)
        -- `t` (open_tabnew): open in the shell's pane itself, no split
        if args.open_cmd == "tabnew" then
          local remote = require "nvim_tree_remote"
          local tmux_opts = remote.tmux_defaults()
          tmux_opts.split_position = ""
          remote.remote_nvim_open(nil, "edit", args.path, tmux_opts)
        else
          editor.run(function(chan)
            vim.rpcrequest(chan, "nvim_command", args.open_cmd .. " " .. vim.fn.fnameescape(args.path))
          end)
        end
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
      -- cyberdream or koda-light by the desktop's light/dark mode, swapped
      -- live with 'background', as in the editor (its config.theme)
      vim.cmd.colorscheme(require("config.theme").init())
    end,
  },
  { "oskarnurm/koda.nvim", lazy = true, opts = function() return require("config.theme").koda_opts end },
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
      filtered.hide_by_name, filtered.hide_by_pattern = split_globs(ignore_patterns.patterns)
      local never_names, never_patterns = split_globs(ignore_patterns.never_show_patterns)
      filtered.never_show = vim.list_extend(copy(ignore_patterns.never_show), never_names)
      filtered.never_show_by_pattern = never_patterns
      require("neo-tree").setup(opts)
    end,
  },
}, {
  lockfile = vim.fn.stdpath "data" .. "/lazy-lock.json",
  install = { colorscheme = { "cyberdream", "koda-light" } },
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

--- Follow the editor: its nvim (config.treemux in ~/.config/nvim) pushes the
--- current buffer's real path here on BufEnter / FocusGained. Only the cursor
--- moves, and only within the current root: treemux's watcher owns the root
--- (it follows the shell's cwd and caches what it set), so a file elsewhere
--- is left alone. A filtered file is simply not landed on.
--- @param path string absolute, symlinks resolved
function _G.treemux_reveal(path)
  local manager = require "neo-tree.sources.manager"
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
      local state = manager.get_state_for_window(win)
      local root = state and state.path
      if not root or (state.name ~= "filesystem" and state.name ~= "git_status") then return end
      if root ~= "/" and path:sub(1, #root + 1) ~= root .. "/" then return end
      local node = state.tree and state.tree:get_node()
      if node and node:get_id() == path then return end
      require("neo-tree.sources." .. state.name).navigate(state, root, path)
      return
    end
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  desc = "Publish this sidebar's RPC address, then show the editor's file",
  callback = function()
    if not vim.env.TMUX_PANE or vim.v.servername == "" then return end
    vim.system { "tmux", "set-option", "-p", "-t", vim.env.TMUX_PANE, "@treemux-nvim-addr", vim.v.servername }
    -- after treemux's watcher has put the tree on the shell's cwd (it polls
    -- for the tree every 20 ms), ask an editor already open to push its file
    vim.defer_fn(function()
      local target = editor.locate(false)
      if not target then return end
      local ok, chan = pcall(vim.fn.sockconnect, "pipe", target.addr, { rpc = true })
      if not ok or chan == 0 then return end
      pcall(vim.rpcrequest, chan, "nvim_exec_lua", "local ok, t = pcall(require, 'config.treemux') if ok and t.reveal then t.reveal() end", {})
      vim.fn.chanclose(chan)
    end, 500)
  end,
})
