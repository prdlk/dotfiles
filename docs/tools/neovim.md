# Neovim

Neovim config pulled from its own repository as a chezmoi external, plus the editor hooks the dotfiles wire into it.

Neovim is the default editor everywhere in this setup. Its configuration (AstroNvim-based, per the repo README) lives in a separate repository, [prdlk/nvim](https://github.com/prdlk/nvim). This repo only clones it and wires other tools to it; the Lua config itself is not documented here.

| | |
| --- | --- |
| Source | `.chezmoiexternal.toml` entry `.config/nvim` |
| Target | `~/.config/nvim` (a git checkout) |
| Remote | `https://github.com/prdlk/nvim.git` |
| Packages | `neovim` (pacman) |

## How the external works

**.chezmoiexternal.toml**

```toml
[".config/nvim"]
    type = "git-repo"
    url = "https://github.com/prdlk/nvim.git"
    [".config/nvim".pull]
        args = ["--ff-only"]
```

- `type = "git-repo"`: chezmoi runs `git clone` when `~/.config/nvim` does not exist, so a fresh machine gets the config on first apply.
- No `refreshPeriod` is set, so a normal `chezmoi apply` never pulls. The local checkout always wins; commit and push nvim changes from `~/.config/nvim` directly.
- A forced refresh (`chezmoi apply --refresh-externals`) runs `git pull --ff-only`, which refuses to merge if local history has diverged.

See [externals and ignore rules](../chezmoi/externals-and-ignore.md) for how chezmoi handles externals in general.

### Ignored runtime paths

`.chezmoiignore.tmpl` keeps chezmoi away from state that tools write inside the checkout:

| Path | Why |
| --- | --- |
| `.config/nvim/lazy-lock.json` | lazy.nvim lockfile, rewritten on plugin updates |
| `.config/nvim/.git`, `.config/nvim/.git/**` | the checkout's own git metadata |
| `.config/nvim/.omc/**` | agent tooling state |
| `.config/nvim/.crush/**` | agent tooling state |
| `.config/nvim/.understand-anything/**` | agent tooling state |

## Integrations in this repo

| Where | What |
| --- | --- |
| `dot_config/fish/conf.d/10-env.fish` | `EDITOR=nvim`. [gh](github-cli.md) falls back to it because its `editor` key is empty. |
| [Aliases](../shell/aliases.md) | `e` = `nvim`; `e.v` opens `~/.config/nvim/lua` in yazi; `e.t` opens the tmux config in nvim. |
| [Kitty](../terminal/kitty.md) | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>e</kbd> opens nvim in the current directory in a 50/50 vertical split. Kitty's `listen_on` socket lets nvim hand <kbd>Ctrl</kbd>+<kbd>h/j/k/l</kbd> at a window edge back to kitty. |
| [Yazi](yazi.md) | The `edit` opener and <kbd>Ctrl</kbd>+<kbd>v</kbd> / <kbd>Ctrl</kbd>+<kbd>x</kbd> call `~/.local/bin/yazi-nvim-open`. Inside an nvim terminal (`$NVIM` set) files open in the host instance through the nvim-side `EditFromYazi` Lua function; otherwise a blocking `nvim` starts. |
| [Git](git.md) | `git difftool` runs `nvim "$LOCAL" "$REMOTE" +"CodeDiff file $LOCAL $REMOTE"`. |
| [LeetCode](leetcode.md) | The default workspace sets `"editor": "nvim"`. |

> [!NOTE]
> `yazi-nvim-open` depends on `_G.EditFromYazi`, which the nvim repo defines (its header points at `lua/config/yazi_session.lua`). If that function is missing, the remote call fails and nothing opens.
