# kitty

kitty configuration, host variants, custom kittens and the Python tab bar.

GPU terminal emulator and the primary terminal on every role.

| | |
| --- | --- |
| Source | [prdlk/kitty](https://github.com/prdlk/kitty) via `.chezmoiexternals/kitty.toml` |
| Target | `~/.config/kitty/` |
| Install | `kitty` in `.chezmoidata/packages.yaml` (pacman), plus `ttf-victor-mono-nerd` for the font |

```text
~/.config/kitty/
  kitty.conf
  tmux.conf
  herdr.conf
  goliath.conf
  ssh.conf
  current-theme.conf
  tab_bar.py
  pass_keys.py
  day_session.py
  navigate_kitty.py
  select_tab.py
  switchtab.py
  os_window_title.py
  themes/
    cyberdream.conf
    koda-dark.conf
    koda-light.conf
```

`~/.config/kitty` is a `git-repo` external checkout, not chezmoi-managed contents; edit it in place and commit and push from there. The repo's `.gitignore` excludes `__pycache__/` next to `tab_bar.py`.

## Theme and colors

Every config ends with:

**~/.config/kitty/kitty.conf**

```conf
include ~/.local/state/omarchy/current/theme/kitty.conf
```

Colors come from the active Omarchy theme; it is included last so it wins. `current-theme.conf` is a symlink committed in the repo, pointing at `themes/cyberdream.conf`. Only the legacy `~/.config/herdr/kitty.conf` ([prdlk/herdr](https://github.com/prdlk/herdr)) includes `current-theme.conf`; the main config does not. `themes/` holds `cyberdream`, `koda-dark`, and `koda-light` color files.

## kitty.conf

| Option | Value |
| --- | --- |
| `font_family` | `VictorMono Nerd Font`, then overridden in the `BEGIN_KITTY_FONTS` block to `family="VictorMono Nerd Font Mono"`; bold/italic `auto` |
| `font_size` | `10.5`, half a point below Ghostty's `font-size = 11` |
| `window_padding_width` | `8` |
| `hide_window_decorations` | `yes` |
| `background_opacity` | `0.9` |
| `cursor_trail` | `10`, `cursor_trail_start_threshold 0`, `cursor_trail_decay 0.01 0.05` |
| `cursor_blink_interval` | `0` (set to 1, then overridden) |
| `copy_on_select` | `auto` |
| `strip_trailing_spaces` | `smart` |
| `confirm_os_window_close` | `0` |
| `allow_remote_control` | `socket-only` |
| `listen_on` | `unix:@kitty-{kitty_pid}` |
| `enabled_layouts` | `splits:split_axis=vertical,stack` |
| Tab bar | `powerline`, `slanted`, centered, top edge, shown only with two or more tabs (`tab_bar_min_tabs 2`; the stack-layout indicator lives in the bar, so it is hidden with one tab), `tab_title_template "{custom}"` |
| OS window title | The active tab's repo name (`watcher os_window_title.py`), like Ghostty's tmux session title; program titles (fish's path, omp's spinner, nvim's file) only reach the tab bar |

> [!NOTE]
> Transparency uses kitty's own alpha, so text stays opaque. This alpha is also what lets the compositor blur the window: Hyprland enables blur globally and opts out every window except terminal classes.

The socket also exports `KITTY_LISTEN_ON` into each pane. nvim reads it to know kitty owns the panes and hands `ctrl+h/j/k/l` back to kitty at an edge.

### Launch aliases

| Alias | Expands to |
| --- | --- |
| `launch_mn` | `launch --cwd=current --type=overlay-main` |
| `launch_os` | `launch --cwd=current --type=os-window` |
| `launch_ov` | `launch --cwd=current --type=overlay` |
| `launch_tb` | `launch --cwd=current --type=tab` |
| `launch_hs` | `launch --cwd=current --location=hsplit --bias=30` |
| `launch_vs` | `launch --cwd=current --location=vsplit --bias=40` |
| `launch_vs50` | `launch --cwd=current --location=vsplit --bias=50` |

### Keybindings

| Key | Action |
| --- | --- |
| `super+n` | Vertical split 50/50 (`launch_vs50`) |
| `super+z` | Toggle `stack` layout (zoom); the tab title gains a layers icon and pane count (`nf-md-layers 3`) while other panes are hidden |
| `ctrl+shift+t`, `super+enter` | New tab in current cwd |
| `ctrl+space`, `ctrl+shift+j` | Horizontal split, 30% (`launch_hs`) |
| `ctrl+enter`, `ctrl+shift+l` | Vertical split, 40% (`launch_vs`) |
| `ctrl+shift+space` | New OS window |
| `ctrl+shift+h` / `ctrl+shift+k` | Previous / next tab |
| `ctrl+shift+g` | `lazygit` in an overlay |
| `ctrl+shift+f` | `yazi` in a new tab |
| `ctrl+shift+e` | `nvim` in a 50/50 vertical split |
| `ctrl+shift+p` | `atuin-pick` in a horizontal split |
| `super+t` | Spawn a separate kitty (`--class=kitty-tmux`, `--config ~/.config/kitty/tmux.conf`) |
| `super+a` | Spawn a separate kitty (`--class=kitty-herdr`, `--config ~/.config/kitty/herdr.conf`) |
| `ctrl+shift+c` / `ctrl+shift+v` | Copy / paste clipboard |
| `alt+q w e r t y u i o` | Go to tab 1–9 |
| `ctrl+h/j/k/l` | `pass_keys.py`: move to neighbor window left/bottom/top/right, or pass the key through |
| `super+left` / `super+right` | Resize window narrower / wider |
| `super+up` / `super+down` | Resize window taller / shorter (by 3) |

The tmux and herdr hosts are separate kitty processes because `launch` cannot take `--config`.

### Daily sessions

`day_session.py` keeps one kitty session file per day, grouped by week:

```text
~/.local/share/kitty-sessions/<monday YYYY-MM-DD>/<day YYYY-MM-DD>.kitty-session
~/.local/share/kitty-sessions/<monday YYYY-MM-DD>/<day YYYY-MM-DD>.scrollback/<window key>.ansi
```

| Directive | Role |
| --- | --- |
| `geninclude day_session.py` | Creates today's (empty) session file and emits `startup_session <path>` whenever no running kitty owns today's session. Ownership is an `flock` on `$XDG_RUNTIME_DIR/kitty-day-<day>.kitty-session.lock`, held until that kitty exits, so closing kitty and launching it again always reopens the day, even if other kitties (or yesterday's) are still running. A second concurrent instance starts plain instead of duplicating today's tabs. A kitty started with `--session` for another day never takes the lock. |
| `watcher day_session.py` | About 1 s after a window opens, closes, resizes or splits, changes focus or finishes a command (catches `cd`), and every 30 s for output from long-running programs, rewrites the session this instance started with. Title changes are ignored so spinners don't trigger saves. Skips the save once the session has no windows, so closing kitty keeps the last good state. |

Earlier days open with the [`kitty-days`](../tools/television.md#kitty-days) tv cable (`tv kitty-days`), each in its own kitty (`kitty --session <file>`). A past day is a read-only snapshot: nothing in that kitty saves it back. Today's file opened that way, while no kitty owns it, becomes the live day again.

Before shutdown or reboot, the `kitty-day-save.service` user unit runs [`kitty-day-save`](../shell/scripts.md#kitty-day-save) under a logind delay inhibitor. On `PrepareForShutdown(true)` it sends `kitten day_session.py flush` to every `@kitty-<pid>` socket: the owning kitty saves at once (all windows are still alive), then skips saves for 60 s so windows dying during the shutdown can't shrink the file. [`30-user-services`](../chezmoi/scripts.md#30-user-services) enables the unit.

What a restored window gets back:

- **Scrollback**: each window carries a `day_scrollback=<key>` user var (kept by kitty's `launch --var`); its history is dumped as ANSI to `<key>.ansi`, minus the idle prompt, and dumps of closed windows are pruned. On restore, the shell runs `cat <key>.ansi` through kitty's shell-integration startup command, so it needs shell integration (fish here). A dump is only written after the shell has drawn a prompt, so a restored window can't overwrite its history before replaying it.
- **Running program**: saved with `--use-foreground-process` and re-run after the `cat`, so the shell is still there when it exits (`nvim`, `sleep 700`, dev servers). Commands still at shell init when saved (mise/direnv hooks) are ignored. A command is never replayed if any of its words is `rm`, `rmdir`, `mv`, `dd`, `shred`, `truncate`, `mkfs*`, `wipefs`, `fdisk`, `parted`, `sudo`, `doas`, `su`, `run0`, `pkexec`, `kill`, `pkill`, `killall`, `reboot`, `shutdown` or `poweroff` (`NO_REPLAY`).
- Programs launched as the window's own command (`ctrl+shift+e` nvim, `ctrl+shift+g` lazygit) were already restored by kitty; they have no shell, so no scrollback.

Only windows that belong to the session are saved: `new_tab_with_cwd` and the `--cwd=current` launch aliases join it; `new_os_window` (`ctrl+shift+space`) does not.

## Host configs

### tmux.conf — kitty as a tmux host

Launched by `super+t`. kitty stays a dumb terminal; tmux owns panes, windows and sessions. `listen_on unix:@kitty-tmux`, `tab_bar_style hidden`, `shell kitty-tmux` (a launcher script), and `clear_all_shortcuts yes`, so only the bindings below exist. Prefix byte `\x02` is `ctrl+b`; see [tmux](tmux.md) for what each prefix key does.

| Key | Sends / does |
| --- | --- |
| `ctrl+shift+c` / `ctrl+shift+v` | Copy / paste |
| `ctrl+plus` / `ctrl+minus` / `ctrl+0` | Font size +1 / -1 / reset |
| `ctrl+shift+alt+,` | Reload kitty config |
| `ctrl+shift+a` | Spawn a kitty herdr host |
| `super+t`, `super+enter`, `ctrl+shift+t` | `prefix t` (new window) |
| `ctrl+shift+h` / `ctrl+shift+k` | `prefix H` / `prefix L` (previous / next window) |
| `alt+q w e r t y u i o` | `prefix 1`–`9` |
| `ctrl+shift+j` | `prefix "` (split below) |
| `ctrl+shift+l`, `ctrl+enter` | `prefix %` (split right) |
| `ctrl+shift+f` | `prefix z` (zoom) |
| `ctrl+shift+w`, `super+w` | `prefix x` (kill pane) |
| `super+left/right/up/down` | `prefix` + `ctrl+arrow` (resize) |
| `ctrl+shift+g` | `tmux display-popup` 90%×90% running `lazygit` in pane cwd |
| `ctrl+shift+e` | `tmux new-window` running `nvim` in pane cwd |
| `ctrl+shift+p` | `tmux split-window -v -l 25%` running `atuin-pick` |
| `super+n`, `ctrl+shift+space` | New OS window |
| `super+d` | `prefix d` (detach) |

### herdr.conf — kitty as a herdr host

Launched by `super+a`. Class `kitty-herdr`, `tab_bar_style hidden` (herdr draws its own sidebar and tab strip), `shell herdr` (launches or attaches the persistent session; closing the window detaches). Base appearance matches `kitty.conf`, without a `listen_on`. An uppercase letter after `\x02` is the shift variant. See [herdr](herdr.md).

| Key | Sends / does |
| --- | --- |
| `super+c` / `super+v` | Copy / paste |
| `ctrl+plus` / `ctrl+minus` / `ctrl+0` | Font size +1 / -1 / reset |
| `ctrl+shift+alt+,` | Reload kitty config |
| `ctrl+shift+n` | `prefix N` |
| `super+n` | `prefix G` |
| `super+t`, `ctrl+shift+t` | `prefix c` |
| `ctrl+space` | `prefix t` (Switchboard menu) |
| `super+z` | `prefix z` |
| `ctrl+tab` / `ctrl+shift+tab` | `prefix .` / `prefix ,` (next / previous agent) |
| `ctrl+shift+f` | `prefix K` (Switchboard projects) |
| `ctrl+shift+g` | `prefix L` (Switchboard git) |
| `ctrl+shift+e` | `prefix e` (herdr-nvim sidebar toggle) |
| `ctrl+shift+o` | `prefix o` (herdr-nvim pick file) |
| `ctrl+shift+h` / `ctrl+shift+l` | `prefix p` / `prefix n` |
| `ctrl+shift+j` / `ctrl+shift+k` | `prefix j` / `prefix k` (next / previous workspace) |
| `ctrl+shift+w` | `prefix W` |
| `ctrl+shift+r` | `prefix T` |
| `ctrl+shift+,` | `prefix S` (herdr settings) |
| `ctrl+shift+q` | `prefix x` |
| `ctrl+shift+p` | `prefix P` (Switchboard commands) |

### goliath.conf — remote tmux over mosh

Opens straight into the tmux session `main` on host `goliath` via `mosh goliath -- tmux new-session -A -s main`. `font_size 9.0`, `listen_on unix:@kitty-goliath`, `env MOSH_TITLE_NOPREFIX=1` (drops mosh's `[mosh] ` title prefix), `tab_bar_style hidden`.

> [!WARNING]
> mosh bootstraps ssh with `-S none`, so non-interactive key auth to goliath must work. It needs mosh on both ends and UDP 60000–61000 open. mosh sets `TERM=xterm-256color`, so kitty-only capabilities such as undercurl are unavailable inside.

| Key | Sends |
| --- | --- |
| `super+w` | `prefix x` |
| `super+t` | `prefix %` |
| `super+n` | `prefix "` |
| `super+enter`, `alt+n` | `prefix t` |
| `alt+h` / `alt+l` | `prefix H` / `prefix L` |
| `alt+q w e r t y u i o` | `prefix 1`–`9` (`alt+t` is bound twice; the later `prefix 5` wins) |
| `super+left/right/up/down` | `prefix` + `ctrl+arrow` |
| `super+d` | `prefix d` |

### ssh.conf

Kitten `ssh` config: for `hostname goliath`, `share_connections yes`.

## Kittens and Python

| File | Purpose |
| --- | --- |
| `tab_bar.py` | Provides `draw_title` for `{custom}` in the tab template. Title is `<index> <icon> <label>`: the label is the git repo root name of the tab's cwd (walks up for `.git`), or the file nvim is editing (parsed from nvim's title). Icon comes from the foreground process cmdline (editors, AI agents like claude/omp/opencode/codex, git tools, docker, herdr, tmux, yazi, btop, atuin, ssh, chezmoi, …) with a folder fallback. Labels are elided at 28 chars. In the `stack` layout with more than one pane, ` <nf-md-layers> <panes>` is appended; kitty repaints the tab bar on every layout change. No subprocesses or timers. |
| `pass_keys.py` | Bound to `ctrl+h/j/k/l`. If the window's foreground process matches `vim`, `nvim`, `fzf`, `tv`, `tmux` or `herdr`, the key is forwarded; otherwise kitty moves to the neighboring window. |
| `navigate_kitty.py` | No-UI kitten that calls `neighboring_window` with a direction argument; the counterpart nvim can invoke. Not mapped in `kitty.conf`. |
| `select_tab.py` | Full-screen fuzzy tab picker using `kitty @ ls` data; shows cwds zsh-style. Keys: Up/Down/PgUp/PgDn scroll, Enter selects, typing filters, `ctrl+c`/Esc quits. Not mapped in `kitty.conf`. |
| `switchtab.py` | Focuses the tab whose `vt` user var matches the argument, or launches one with that var and reorders tabs by `vt`. Not mapped. |
| `os_window_title.py` | Global watcher. On every `on_tab_bar_dirty` (tab switch, focus change, any program title change; also fires while the bar is hidden) it sets the OS window title to `tab_bar.py`'s `wd_label` for the active window's cwd: the repo root name, `~` at home, the dir name outside a repo. An empty label clears the override, so kitty falls back to the program's title. |
| `day_session.py` | Daily sessions: `geninclude` script, global watcher and the `flush` no-UI kitten in one file. See [Daily sessions](#daily-sessions). |

Related: the [tmux](tmux.md) `is_vim` check and herdr's `vim-herdr-navigation` plugin complete the `ctrl+h/j/k/l` chain. Hyprland window rules can match the `kitty`, `kitty-tmux` and `kitty-herdr` app-ids ([Hyprland](../desktop/hyprland.md)).
