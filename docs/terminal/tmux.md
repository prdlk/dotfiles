# tmux

tmux prefix, bindings, kitty-style window tabs with Nerd Font icons, and resurrect/continuum persistence.

Terminal multiplexer. [Ghostty](ghostty.md) runs nothing but tmux, and Ghostty's `ctrl+shift` chords are tmux bindings. tmux is also used through the kitty tmux host and remotely on goliath.

| | |
| --- | --- |
| Source | [prdlk/tmux](https://github.com/prdlk/tmux) via `.chezmoiexternals/tmux.toml`: `tmux.conf`, `tmux-nerd-font-window-name.yml`, `tab-label.sh` |
| Target | `~/.config/tmux/` |
| Install | `tmux` in `.chezmoidata/packages.yaml` (pacman) |

`~/.config/tmux` is a `git-repo` external checkout, not chezmoi-managed contents; edit it in place and commit and push from there. tpm is a separate `git-repo` external in `.chezmoiexternal.toml`, cloned to `~/.config/tmux/plugins/tpm` inside that checkout when missing. `tmux.conf` ends with `run '~/.config/tmux/plugins/tpm/tpm'`. Plugins installed by tpm (`prefix I`) land next to it; the tmux repo's `.gitignore` excludes `plugins/` and chezmoi ignores them. [prdlk/tmux-palette](https://github.com/prdlk/tmux-palette) (`.chezmoiexternals/tmux-palette.toml`, → `~/.config/tmux-palette/`) holds the [palette](#command-palette) config.

## Options

The prefix is `ctrl+b` (the byte Ghostty's `ctrl+shift` chords send). `ctrl+space` is not a prefix: it opens the [command palette](#command-palette).

| Option | Value |
| --- | --- |
| `default-command` | `exec fish -l`, or the login shell (`$SHELL -l`) where fish is missing. `default-shell` stays the login shell (bash), so `run-shell`, `if-shell` and `#()` jobs keep running under a POSIX shell |
| `default-terminal` | `tmux-256color`; `RGB` override for every terminal; `clipboard` and `hyperlinks` (OSC 8) features; `extkeys` for xterm-kitty. Features apply after `tmux kill-server` |
| `extended-keys` | `on`, format `csi-u` |
| `base-index` / `pane-base-index` | `1` / `1`; `renumber-windows on` |
| `status-position` | `top`, `status-interval 5` |
| `allow-passthrough` / `set-clipboard` / `mouse` / `focus-events` | `on` |
| `update-environment` | `TERM` and `TERM_PROGRAM` appended, so programs see the outer terminal (Ghostty/kitty) |
| `mode-keys` | `vi` |
| `set-titles` | `on`, `#S`: the terminal window title is the session name, so compositor window groups list sessions (one per Ghostty window) instead of `host:window` |
| `automatic-rename-format` | `#{window_icon} <label>`: Nerd Font icon, then the dynamic label described under [Window tabs](#window-tabs) |
| `history-limit` | `50000` |
| `detach-on-destroy` | `no-detached` (killing a session switches only to a detached session, else detaches, so a Ghostty window never lands on another window's session) |

These settings are what [yazi](../tools/yazi.md) needs inside tmux. `allow-passthrough` carries image previews through to the terminal, `set-clipboard` copies paths via OSC 52, and the two environment variables let yazi detect the outer terminal's graphics support. Nothing binds `M-[`: tmux would read the `ESC [` that starts yazi's terminal-query replies as that key and break yazi's capability detection.

## Keybindings

`prefix ?` opens all of them in a popup: `omarchy-menu-tmux-keybindings` on Omarchy machines, `tmux list-keys -N` everywhere else.

| Key | Action |
| --- | --- |
| `prefix q` | Reload config |
| `prefix /` | Copy mode, then search upward |
| `prefix o` | Sessions palette ([`tmux-sessions`](../shell/scripts.md#tmux-sessions)): fuzzy-find the other sessions, every window of every session, zoxide's and `~/.config`'s directories, and Rename/Kill items per session. Typed text that is not a session starts one by that name in its zoxide match |
| `prefix t` | Project Tasks palette ([`pj-palette`](../shell/scripts.md#pj-palette)): install/dev/sync/make/compose quick actions plus every `pj` task. One-off tasks run in a full-width bottom split (25% of the window); dev servers and `docker compose up` run in a background `<session>:<tool-and-command>` session shown in a popup (`q` hides, `ctrl-c` asks `y/n` then stops), listed under Running to reopen |
| `prefix y` / `prefix e` | Yazi / Neovim in a new window in the pane cwd (Ghostty `ctrl+shift+f` / `ctrl+shift+e`) |
| `prefix g` | Lazygit in a 90% popup in the pane cwd (Ghostty `ctrl+shift+g`) |
| `prefix a` | omp in a background session `<session>:omp` (pane cwd), shown in a popup docked bottom-right (35% × 60%) and listed in the [omp palette](../shell/scripts.md#pj-palette) and under Running in the tasks palette. In the popup, `ctrl-c` hides it and `ctrl-q` quits omp. Inside any background-task popup, `prefix a` hides it too, so Ghostty `ctrl+shift+a` toggles omp |
| `prefix h` / `prefix v` | Split below / right, pane cwd |
| `prefix x` | Kill pane |
| `S-Enter` (no prefix) | Sends `ESC[13;2u` to the pane unchanged. With `extended-keys on`, tmux would otherwise turn Shift+Enter into plain Enter for apps that never requested extended keys, and coding agents (omp, Claude Code) would submit instead of inserting a newline |
| `C-MouseDown1Pane` (ctrl+click) | Opens the OSC 8 hyperlink under the mouse (`#{mouse_hyperlink}`) with `xdg-open`; without one, the click goes to the pane. Plain-text URLs: `ctrl+shift+click`, handled by Ghostty |
| `M-Enter` / `M-S-Enter` / `M-Escape` (no prefix) | Split below / split right / kill pane |
| `C-h` / `C-j` / `C-k` / `C-l` (no prefix) | Vim-aware pane focus. In an nvim/vim/fzf pane (`@pane-is-vim`, set by smart-splits.nvim, or the pane's command), the key goes to nvim. nvim's `config.pane_nav` hands tmux to smart-splits, which moves between nvim splits and, at its outer edge, runs `tmux select-pane`. Elsewhere tmux moves directly; both wrap at the outer edge. Also bound in copy mode |
| `M-h` / `M-j` / `M-k` / `M-l` (no prefix) | Vim-aware resize. In an `@pane-is-vim` pane the key goes to smart-splits, which resizes nvim splits and, when nvim has no split on that axis, the tmux pane. Elsewhere `resize-pane` by 3, so shells and other programs never see these keys |
| `prefix C-l` | Send `C-l` (clear screen) |
| `C-M-arrows` / `C-M-S-arrows` (no prefix) | Focus pane / resize pane by 5 |
| `prefix c` / `prefix k` / `prefix r` | New window in pane cwd / kill window / rename window |
| `M-1` … `M-9` (no prefix) | Select window 1–9 |
| `M-Left` / `M-Right` (no prefix) | Previous / next window |
| `M-S-Left` / `M-S-Right` (no prefix) | Move window left / right |
| `prefix C` / `prefix K` / `prefix R` | New / kill / rename session |
| `prefix P` / `prefix N`, `M-Up` / `M-Down` | Previous / next session |
| Copy mode `v` / `y` | Begin selection / copy and exit |

## Window tabs

The status line copies kitty's tab bar (`tab_bar_style powerline`, `tab_powerline_style angled`). The current window is an accent-tinted plate with accent text. The other windows use `bg=default` and muted text, so the terminal's transparency shows through them, as with kitty's `tab_bar_background none`. That only works while every `window-status-*-style` stays `default`: inside a tab format, `bg=default` means that style's background, not the terminal's. `tmux.conf` therefore sets all of them explicitly, because a reload never clears a value a removed plugin left behind. As in kitty, a solid arrow leads into the current window and a thin one sits between two inactive windows. The arrow into the current window is a plain `U+E0B0` in `@tab-bg`, the window background. Ghostty draws that glyph as a built-in sprite that fills the whole cell even with `adjust-cell-height`. The session name is an accent pill on the far left (`status-justify left`); its arrow points straight into the first tab, so the pill and tabs read as one chain of arrows. The right side shows `COPY`/`PREFIX`/`ZOOM` flags and the hostname.

Colors are the user options `@tab-bg` (window background: the notch arrow and the session pill's text), `@tab-fg`, `@tab-active-bg`, and `@tab-active-fg`. They are a fixed cyberdream palette (the same one Ghostty's `cyberdream` theme uses), so the bar looks identical on every machine and does not depend on Omarchy. Active background = accent mixed 20% into background, the same derivation as the kitty tab bar: `#243348` from accent `#5ea1ff` over `#16181a`.

Popups (`prefix g`, `prefix t`, `prefix ?`, tmux-palette) set `popup-style` to `bg=@tab-bg` and `popup-border-style` to `@tab-active-fg` on that background with rounded lines. The explicit background matters under Ghostty: `background-opacity` only applies to cells with the default background, so a default-bg popup shows the pane behind it through the blur.

### Tab labels

Each window reads `<index> <icon> <label>`, updating as you work, the same rule as kitty's `tab_bar.py`:

| Pane runs | Label | Source |
| --- | --- | --- |
| `nvim`/`vim`/`hx`/`helix`, editing a file | The file name | The title nvim sets (`<file> \| <org/repo>`, astrocore `custom_title`), read from `#{pane_title}` by the format itself, so a buffer switch relabels the tab immediately |
| Anything else, or an editor with no file | Repo the cwd belongs to (walks up for `.git`); the directory name outside a repo; `~` at home | `tab-label.sh`, run as an async `#()` job. When its output differs from the current name, it re-arms `automatic-rename` so tmux relabels right after a `cd` instead of on the next keystroke |

Labels longer than 27 characters end in `…`. The icon comes from tmux-nerd-font-window-name.

## Plugins

| Plugin | Settings |
| --- | --- |
| `tmux-plugins/tpm` | Plugin manager |
| `tmux-plugins/tmux-sensible` | Defaults |
| `joshmedeski/tmux-nerd-font-window-name` | Fills `#{window_icon}` from `tmux-nerd-font-window-name.yml` |
| `tmux-plugins/tmux-resurrect` | `@resurrect-capture-pane-contents on` |
| `tmux-plugins/tmux-continuum` | `@continuum-save-interval 10`, `@continuum-restore on` |
| `prdlk/tmux-palette-plugin` | Fork of [eduwass/tmux-palette](https://github.com/eduwass/tmux-palette) that adds a custom palette `query` item (an item for the typed text, listed after the matches). `@palette-key C-Space` (root table, no prefix). Needs [Bun](https://bun.sh); tpm runs `bun install` on first load |

### Command palette

`ctrl+space` opens tmux-palette, a fuzzy command list in a popup. Its user config lives in `~/.config/tmux-palette/` (the [prdlk/tmux-palette](https://github.com/prdlk/tmux-palette) external):

| File | Contents |
| --- | --- |
| `commands.json` | The kitty launchers ported as palette items: **Lazygit** (90% popup in the pane's cwd; kitty `ctrl+shift+g`), **Yazi** (new window; kitty `ctrl+shift+f`), **Neovim Split** (nvim in a split to the left, 60% of the pane; alias `nv`; kitty `ctrl+shift+e`), **Shell History (atuin)** (`atuin-pick` in a 25% split below; kitty `ctrl+shift+p`). Also **btop** (80% popup; aliases `top`, `htop`), **Lazydocker** (90% popup in the pane's cwd; alias `dd`), **mandible** (80% popup running [`mandible-pick`](../shell/scripts.md#mandible-pick); alias `man`), **television** (`tv channels`, the [channel picker](../tools/television.md), in a new window in the pane's cwd; alias `tv`), **gitframe** (git diff viewer in a new window in the pane's cwd; alias `gf`), **omp** (opens the omp palette; aliases `agent`, `ai`), **Project Tasks** (opens the tasks palette), **Sessions** (opens the sessions palette; aliases `sx`, `ss`), **Save Sessions**, and **Restore Sessions** (resurrect). Programs are started with `exec`, so the tab icon is the program's, not the shell's |
| `palettes/tasks.json` | The **Project Tasks** palette (`prefix t`, Ghostty `ctrl+shift+p` / `ctrl+shift+space`), fed by [`pj-palette`](../shell/scripts.md#pj-palette): running background tasks under Running, then `bun install`, `bun run dev`, `uv sync`, `uv run python`, `make`, `go run .`, `cargo run`, `docker compose up` as Quick items when the project has them, then every task `pj` finds, grouped by tool. One-off tasks run in a full-width split along the bottom (25% of the window) in their directory; `ctrl-c` stops a running task, and once it has exited, `enter` or `ctrl-c` closes the pane. Dev servers (`dev`/`start`/`serve`/`watch`/`preview` tasks) and `docker compose up` run in a background session `<session>:<tool-and-command>` shown in a popup: `q` hides it with the task still running, `ctrl-c` asks `Stop <session>? (y/n)` and on `y` stops the task and closes it |
| `palettes/omp.json` | The **omp** palette, fed by [`pj-palette --omp`](../shell/scripts.md#pj-palette): this tmux session's `<session>:omp` (open it, or start it when not running), every other tmux session's running omp, and a Quit item per session. Running agents have a green icon and show `open` or `hidden` |
| `palettes/sessions.json` | The **Sessions** palette (`prefix o`, Ghostty `ctrl+shift+o`), fed by [`tmux-sessions`](../shell/scripts.md#tmux-sessions): Sessions (the last one first, attached ones green), Windows, Zoxide, Config, Rename, Kill. Its `query` item lists the typed text last; `enter` on it runs `tmux-sessions --new <text>` |
| `hidden.json` | Hides the built-in **Switch Theme...** item, and with it the Appearance section: the palette stays on the fixed cyberdream `theme.json` |
| `shortcuts.json` | Ghostty `ctrl+shift` chords shown next to the built-in items they trigger (New Window → `Ctrl+Shift+T`, …) |
| `theme.json` | cyberdream: bg `#16181a`, panel `#1e2124`, selected `#243348` (the active-tab plate), fg `#ffffff`, muted `#7b8496`, accent `#5ea1ff` |

### Persistence

resurrect saves sessions, windows, panes, cwds, pane contents, and a default set of programs (nvim, less, man, …). Keys: `prefix C-s` saves, `prefix C-r` restores. continuum saves automatically every 10 minutes. When a tmux server starts and no other tmux server is running, continuum restores the last save. In practice that means the first Ghostty window after login or a reboot.

## tmux-nerd-font-window-name.yml

`show-name: false`, because `automatic-rename-format` supplies the label. The icon sits on the left, with a fallback icon and a blank multi-pane icon. Icons are defined for `mprocs`, `mm`, `macmon`, `make`, `zsh`, `nvim`, `devbox`, `psql`, `yazi`, `lazygit`, `gh`, `tv`, `docker`, `bun`, `node`, `npm`, `pnpm`, `go`, `bunx`, `claude`, `omp`, and `gitframe`. The plugin parses the YAML with awk and does not interpret `\U` escapes, so the glyphs are literal characters.

