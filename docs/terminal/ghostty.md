# Ghostty

Ghostty as a tmux-only terminal — every window attaches to tmux, and ctrl+shift chords drive tmux.

Ghostty is the default terminal and only a [tmux](tmux.md) client. tmux owns tabs (windows), splits (panes), sessions, and persistence. Ghostty draws the text and handles the clipboard and font size.

It is the default everywhere a desktop picks a terminal: the first entry of `~/.config/xdg-terminals.list` (`dot_config/xdg-terminals.list`, desktop roles only) is what `xdg-terminal-exec` and `omarchy-launch-terminal` launch.

| | |
| --- | --- |
| Source | [prdlk/ghostty](https://github.com/prdlk/ghostty) via `.chezmoiexternals/ghostty.toml`: `config`, `themes/` |
| Target | `~/.config/ghostty/` |
| Install | `ghostty` in `packages.arch.pacman` |

`~/.config/ghostty` is a `git-repo` external checkout, not chezmoi-managed contents; edit it in place and commit and push from there.

`config` holds every setting, ending in `theme = cyberdream`.

## Options

| Option | Value |
| --- | --- |
| `font-family` / `font-size` | `IoskeleyMonoTerm Nerd Font Mono` / `11` |
| `adjust-cell-height` | `20%` (line height) |
| `background-opacity` / `background-blur` | `0.9` / `true` |
| `window-decoration` | `false`; `gtk-titlebar = false` |
| `window-padding-x/y` | `0` |
| `cursor-style` | `underline`, blinking |
| `scrollback-limit` | `3023` (tmux keeps the real scrollback: `history-limit 50000`) |
| `mouse-hide-while-typing` | `true` |
| `copy-on-select` | `false` |
| `confirm-close-surface` | `false` |
| `link-url` / `link-previews` | `true` / `true`. Under tmux (`mouse on`) tmux receives the click, so open links with `ctrl+shift+click`; tmux opens OSC 8 links on a plain `ctrl+click` |
| `app-notifications` | `no-clipboard-copy,no-config-reload` |
| `quit-after-last-window-closed` | `false`, delay `5m` |
| `command` | `shell:$HOME/.local/bin/ghostty-tmux` (see [Sessions](#sessions)) |
| `shell-integration` | `detect`, features `cursor,sudo,title,no-cursor` |
| `gtk-single-instance` | `true` |

## Sessions

Every Ghostty window gets its own tmux session; no two windows mirror the same one. `~/.local/bin/ghostty-tmux` (source `dot_local/bin/executable_ghostty-tmux`) runs for each new window:

1. If a detached session exists (left by a closed window, or restored by continuum after a reboot), it attaches to the oldest one, by session id. Background task sessions from `pj-palette` (`@pj_task` set, named `<session>:<task>`) are never reclaimed.
2. Otherwise it starts a new session.

Before starting tmux, the script puts mise's shims on `PATH`. A server started from a desktop-launched Ghostty therefore finds the tools tmux plugins shell out to: bun for the palette, fzf, and zoxide.

The window title is the tmux session name (`set-titles-string '#S'`), so the compositor's window groups list one entry per session. tmux's tab bar uses its own fixed cyberdream colors, the same `#16181a` background as Ghostty's `cyberdream` theme.

Closing a window only detaches its session; the shells keep running in the tmux server. In tmux, `detach-on-destroy no-detached` means killing a session moves the window to a *detached* session, or closes the window if there is none, so it never lands on another window's session. Across reboots, tmux-continuum saves every 10 minutes. The first Ghostty window starts the server, and that triggers continuum's restore. See [tmux](tmux.md#persistence).

## Keybindings

`keybind = clear` comes first and drops every Ghostty default: tabs, splits, `alt+N` goto_tab, and `ctrl+alt+arrow` goto_split. Those chords then reach tmux, which binds `alt+1…9` and `ctrl+alt+arrows` itself. `ctrl+h/j/k/l` also pass straight through to tmux's vim-aware pane navigation, which hands off to and from nvim's splits (see [tmux](tmux.md#keybindings)). Each `ctrl+shift` chord sends tmux's prefix, `ctrl+b` (`\x02`), followed by a key.

| Key | Ghostty action |
| --- | --- |
| `ctrl+shift+c` / `ctrl+shift+v` | Copy / paste |
| `ctrl+plus` / `ctrl+minus` / `ctrl+zero` | Font size +1 / -1 / reset |
| `ctrl+shift+.` | Reload Ghostty config |
| `shift+enter` | Sends `ESC[13;2u` (CSI-u Shift+Enter), which tmux passes through to the pane, so coding agents such as omp and Claude Code insert a newline instead of submitting. Not `\n`: that is `ctrl+j`, tmux's pane-down key |
| `ctrl+space`, `ctrl+backspace` | Sends NUL (tmux `C-Space`): opens the [tmux command palette](tmux.md#command-palette) |

| Key | Sends | tmux action |
| --- | --- | --- |
| `ctrl+shift+t` | `prefix c` | New window (tab) in pane cwd |
| `ctrl+shift+p` / `ctrl+shift+space` | `prefix t` | Project Tasks palette (pj: install, dev, sync, make, every project task) |
| `ctrl+shift+f` | `prefix y` | Yazi in a new window, pane cwd |
| `ctrl+shift+e` | `prefix e` | Neovim in a new window, pane cwd |
| `ctrl+shift+g` | `prefix g` | Lazygit in a 90% popup, pane cwd |
| `ctrl+shift+a` | `prefix a` | Toggle omp in a background-session popup (`<session>:omp`), pane cwd |
| `ctrl+shift+w` | `prefix k` | Kill window (close tab) |
| `ctrl+shift+r` | `prefix r` | Rename window |
| `ctrl+tab` / `ctrl+page_down` / `ctrl+shift+right` / `ctrl+shift+k` | `prefix n` | Next window |
| `ctrl+shift+tab` / `ctrl+page_up` / `ctrl+shift+left` / `ctrl+shift+h` | `prefix p` | Previous window |
| `ctrl+shift+l` | `prefix v` | Split right |
| `ctrl+shift+j` | `prefix h` | Split below |
| `ctrl+shift+o` / `super+enter` | `prefix o` | Sessions palette: switch session or window, or create one through zoxide |
| `ctrl+shift+x` | `prefix x` | Kill pane |
| `ctrl+shift+enter` / `ctrl+shift+z` | `prefix z` | Zoom pane |
| `ctrl+shift+page_up` | `prefix [` | Copy mode |
| `ctrl+shift+/` | `prefix ?` | Keybinding help popup |
| `ctrl+shift+alt+,` | `prefix q` | Reload tmux config |
| `ctrl+shift+n` | `prefix C` | New session |
| `ctrl+shift+s` | `prefix s` | Session/window tree |
| `ctrl+shift+q` | `prefix d` | Detach (closes the Ghostty window; the session lives on) |

## Themes

| Theme | Notes |
| --- | --- |
| `cherry-blossom` | Static copy of the `CherryBlossom` palette (background `#222120`, foreground `#dcc1b7`, salmon cursor `#cf716f`). Not selected; set `theme = cherry-blossom` to use it. |
| `cyberdream` | Selected. Upstream `extras/ghostty/cyberdream` from [cyberdream.nvim](https://github.com/scottmckendry/cyberdream.nvim), the palette shared with tmux, nvim, yazi, and television. |
| `ii-auto` | Auto-generated by the ii wallpaper theming system; not meant to be edited. |
| `koda-dark` / `koda-light` | Koda palettes with `bold-is-bright = true`. |
