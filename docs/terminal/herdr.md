# herdr

herdr, an agent-aware terminal multiplexer, with its keys, theme, plugins and Claude Code hook.

herdr is a terminal multiplexer with workspaces, tabs and panes, a sidebar, a prefix key (`ctrl+b`), and a plugin system. It tracks coding agents running in its panes: agent-state colors, next/previous agent keys, and an integration that reports Claude Code sessions to it.

| | |
| --- | --- |
| Source | [prdlk/herdr](https://github.com/prdlk/herdr) via `.chezmoiexternals/herdr.toml` (`~/.config/herdr/`); `dot_config/herdr-nvim/config.toml` |
| Target | `~/.config/herdr/`, `~/.config/herdr-nvim/config.toml` |
| Install | Not in `packages.yaml`; updated by topgrade (`herdr update`) |
| Launch | kitty `super+a` (see [kitty](kitty.md)) |

## config.toml

`onboarding = false`.

### UI and theme

| Setting | Value |
| --- | --- |
| `ui.pane_borders`, `ui.pane_outer_borders` | `false` (panes separated by gaps only) |
| `ui.prompt_new_tab_name` | `false` |
| `ui.accent` | `#5ea1ff` |
| `ui.status_indicators` | `symbols` |
| `ui.toast.delivery` | `system` |
| `theme.name` | `terminal`, `auto_switch = false` |
| `theme.custom.panel_bg` | `reset` (keeps kitty's translucency and compositor blur) |
| `sidebar_bg` / `active_row_bg` / `selection_bg` | `#16181a` / `#1e2124` / `#3c4048` |
| `accent` / `surface_dim` | `#243348` / `#5ea1ff` (active tab plate matches kitty's tab bar) |
| Agent-state colors | green `#5eff6c`, yellow `#f1ff5e`, red `#ff6e5e`, peach `#ffbd5e`, mauve `#bd5eff` |
| `experimental.kitty_graphics` | `true`; `pane_history = false` |
| `switch_ascii_input_source_in_prefix` | `true` |

These are cyberdream colors.

### Keys

| Key | Action |
| --- | --- |
| `prefix %` | Split vertical |
| `prefix "` | Split horizontal |
| `prefix d` | Detach |
| `prefix s` | Workspace picker |
| `prefix shift+s` | Settings |
| `k` / `j` | Move up / down in the workspace picker (pane up/down in navigate mode unbound) |
| `prefix .` / `prefix ,` | Next / previous agent |
| `prefix j` / `prefix k` | Next / previous workspace |
| `prefix up/down/left/right` | Focus pane |
| `ctrl+h/j/k/l` | `vim-herdr-navigation` left/down/up/right |
| `prefix e` | `chmarax.herdr-nvim.toggle` (nvim sidebar) |
| `prefix o` | `chmarax.herdr-nvim.pick-file` (open file from agent output) |
| `prefix t` | `switchboard.menu` |
| `prefix shift+p` | `switchboard.commands` |
| `prefix shift+l` | `switchboard.git` |
| `prefix shift+k` | `switchboard.projects` |
| `prefix y` | Open `official.browser` plugin in a right split |
| `prefix shift+o` | Open `official.browser` as an overlay |

## Plugins

`plugins.json` is herdr's plugin registry. `.plugins.lock` is committed empty. `plugins/config/official.browser/` and `plugins/config/vim-herdr-navigation/` hold placeholder `.keep` files for per-plugin config. `plugins/github/`, where herdr installs plugin checkouts, is gitignored in the repo.

| Plugin | Description (from its manifest) |
| --- | --- |
| `chmarax.herdr-nvim` | Full-height nvim sidebar with agent annotations |
| `herdr-automatic-rename` | Names tabs after the foreground program, adds 1–9 jump numbers |
| `io.github.salemsayed.omaherd` | Tells the Omarchy bar when an agent changes state |
| `official.browser` | Open and inspect real browser pages from herdr |
| `oh-my-opencode-slim` | OpenCode agent orchestration with a herdr adapter |
| `persiyanov.reviewr` | Review agent-written diffs beside the chat |
| `rjyo.window-title-sync` | Syncs the outer terminal title to the focused workspace, tab and agent |
| `switchboard` | Command palette: projects, commands, ports, git, clone, settings |
| `vim-herdr-navigation` | Vim-aware `ctrl+h/j/k/l` pane movement |

[fish](../shell/fish.md) sources `herdr-automatic-rename`'s `shell/hook.fish` if present.

## herdr-nvim

**~/.config/herdr-nvim/config.toml**

```toml
[sidebar]
position = "left"
```

The nvim sidebar opens to the left of existing panes (default is right).

## herdr/kitty.conf

A legacy kitty config kept in the herdr folder. It runs `tmux new-session -A -s main`, listens on `unix:@mykitty`, includes `current-theme.conf`, maps `super`/`alt` keys to tmux prefix bytes, and has a copy of an older `tmux.conf` appended. The active herdr host is `~/.config/kitty/herdr.conf`.
