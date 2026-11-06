# Hyprland

Hyprland Lua config layered on Omarchy — master layout, terminal-only blur, monitors, and the omarchy-* helper scripts.

[Hyprland](https://hypr.land) is a dynamic tiling Wayland compositor. This config uses Hyprland's Lua configuration and sits on top of [Omarchy](https://omarchy.org), which provides the defaults, theme, menus, and `omarchy-*` commands. The files here only override.

> [!NOTE]
> Linux `desktop` and `laptop` roles only. `.chezmoiignore.tmpl` skips `~/.config/hypr/**` on other roles. The `omarchy-*` scripts are **not** listed there, so chezmoi applies them on every role and OS; they only take effect where Omarchy is installed.
>
> `dot_config/hypr` is a git submodule ([prdlk/hypr](https://github.com/prdlk/hypr)). Edit inside the submodule, commit there, then commit the updated pointer in the chezmoi repo.

## Files

| Source (repo) | Target | Purpose |
| --- | --- | --- |
| `dot_config/hypr/hyprland.lua` | `~/.config/hypr/hyprland.lua` | Entry point, workspace and window rules |
| `dot_config/hypr/autostart.lua` | `~/.config/hypr/autostart.lua` | Extra autostart (empty) |
| `dot_config/hypr/bindings.lua` | `~/.config/hypr/bindings.lua` | Keybindings |
| `dot_config/hypr/input.lua` | `~/.config/hypr/input.lua` | Key repeat, tablet/touch mapping |
| `dot_config/hypr/looknfeel.lua` | `~/.config/hypr/looknfeel.lua` | Layout, decoration, blur |
| `dot_config/hypr/monitors.lua` | `~/.config/hypr/monitors.lua` | Monitor modes and positions |
| `dot_config/hypr/nav.lua` | `~/.config/hypr/nav.lua` | `SUPER + [SHIFT +] H/J/K/L` focus and move |
| `dot_config/hypr/hyprsunset.conf` | `~/.config/hypr/hyprsunset.conf` | Night-light profile |
| `dot_config/hypr/xdph.conf` | `~/.config/hypr/xdph.conf` | xdg-desktop-portal-hyprland |
| `dot_config/hypr/dot_luarc.json` | `~/.config/hypr/.luarc.json` | Lua language server settings |
| `dot_local/bin/executable_omarchy-*` | `~/.local/bin/omarchy-*` | Helper scripts (see [below](#omarchy-scripts)) |

None are templates. Hyprland and Omarchy are not in `.chezmoidata/packages.yaml`. They come from the Omarchy install.

## Entry point

`hyprland.lua` loads Omarchy, then the personal files, then Omarchy's toggles:

**~/.config/hypr/hyprland.lua**

```lua
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")
require("default.hypr.omarchy")

require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

require("default.hypr.toggles")
```

Omarchy's default bindings stay enabled. `omarchy_default_bindings` and `omarchy_preinstalled_bindings` are left commented. `bindings.lua` unbinds each default it replaces.

### Workspace rules

| Workspace | Monitor |
| --- | --- |
| 1 (default), 2, 3, 4 | The main external display: `desc:Apple Computer Inc StudioDisplay 0x984262A7` if connected, else `desc:Samsung Electric Company S34CG50 HNTY501103` (Studio Display while neither is). Chosen at config load; `monitors.lua` reloads the config when the main external changes, and existing workspaces 1–4 are moved over |
| 5 (default), 6, 7, 8 | `eDP-1` |

`default` marks the workspace each monitor shows when it connects.

### Window rules

| Class | Rule |
| --- | --- |
| `^brave-www\.tldraw\.com__-Default$` | Workspace 3 |
| `^tldraw-offline$` | Workspace 5, fullscreen |
| `^so\.stencil\.tern$` | `special:scratchpad silent` |
| `^com\.fastmail\.Fastmail$` | `special:fastmail silent` |
| `^Beeper$` | `special:beeper silent` |
| `^brave-home\.google\.com__.*` | `special:home silent` |
| `^ai\.elementlabs\.lmstudio$` | `special:lmstudio silent` |
| `brave-(www\.)?youtube\.com__.*`, title not matching `.*Picture.?in.?[Pp]icture.*` | Float, pin, size 30% × 30% of the monitor, move to `10, monitor_h*0.7-10` (bottom-left corner) |
| `^kitty(-.*)?$` (kitty and the `kitty-tmux`, `kitty-herdr`, `kitty-goliath` hosts) | `group = "set always"`: opens as a group; with `group.auto_group` on (the default), a kitty opened while a group is focused joins it as a tab |

Scratch residents are placed `silent` so that [`omarchy-toggle-scratch`](#omarchy-toggle-scratch) decides when to reveal them. The YouTube rule matches both `youtube.com` and `www.youtube.com` because Chromium's class changes once a video plays. It excludes the picture-in-picture overlay so Omarchy's own PiP rule still applies. Its size and inset must stay in sync with [`omarchy-pip`](#omarchy-pip).

## Input

`input.lua`:

- `repeat_delay = 250` (Omarchy's value), `repeat_rate = 50` (raised from 40). The file's comments record that 200/50 felt too fast. The typing lag it was meant to fix came from the keyboard's firmware tap-hold handling and was fixed on the keyboard itself.
- Tablet and touch devices are pinned to one output each:

| Device | Output | Extra |
| --- | --- | --- |
| `elan9008:00-04f3:43c7-stylus` (Flow Z13 pen) | `eDP-1` | |
| `elan9008:00-04f3:43c7` (Flow Z13 touchscreen) | `eDP-1` | Taps land on the panel instead of the focused monitor |
| `wacom-intuos-bt-s-pen` | The main external display (Studio Display or Samsung ultrawide) | `active_area_size = { 152, 152 × height / width }` (85.5 on the Studio Display, 63.6 on the ultrawide), `active_area_position = { 0, 0 }` — a full-width band with the display's aspect ratio |

The layout, touchpad, and gesture examples in the file are commented out. Palm rejection is done by a libinput quirks file in `/etc`, which chezmoi does not manage.

## Look and feel

`looknfeel.lua` loads after the Omarchy theme's `hyprland.lua`, so its values override the theme's. The theme sets colors. This file sets everything else. The approach is flat windows by default, with blur only behind terminals.

| Setting | Value |
| --- | --- |
| `general.layout` | `master` (instead of Omarchy's dwindle; per-workspace layouts saved by `omarchy-hyprland-workspace-layout-toggle` still win) |
| `decoration.rounding` | 0 |
| `decoration.dim_special` | 0.33 (darkens the desktop behind any open scratch workspace) |
| `decoration.blur` | enabled; `size 5`, `passes 2`, `brightness 0.8`, `contrast 1.1`, `vibrancy 0.15`, `noise 0.01`, `new_optimizations`, `popups = false` |
| `decoration.shadow` | disabled |
| `group.groupbar.gradient_rounding` | 0 |
| `group.groupbar.disable_when_only` | true: no tab bar on a group of one (kitty always opens as a group); it appears when a second window joins |
| Workspace animation | disabled (`hl.animation({ leaf = "workspaces", enabled = false })`) |

Blur must be enabled globally before any window can use it, so every window tagged `default-opacity` gets `no_blur = true`, and terminals get it back:

**~/.config/hypr/looknfeel.lua**

```lua
o.window({ tag = "default-opacity" }, { no_blur = true })
o.window(
  "^(kitty(-.*)?|Alacritty|com\\.mitchellh\\.ghostty|foot|org\\.codeberg\\.dnkl\\.foot|wezterm)$",
  { no_blur = false }
)
```

Omarchy's stock fade (0.985 active / 0.96 inactive) is kept. Terminals get their transparency from kitty's `background_opacity 0.9` (see [kitty](../terminal/kitty.md)). The comments give the reason for limiting blur: the cyberdream and Spectra themes enabled rounding, blur, and shadow on every window, and that costs frame time on an iGPU driving the laptop panel plus a 5K display.

## Monitors

`monitors.lua`:

| Output | Mode | Position | Scale |
| --- | --- | --- | --- |
| any (fallback) | `preferred` | `auto` | 3.2 |
| `desc:Apple Computer Inc StudioDisplay 0x984262A7` (Studio Display, Thunderbolt; connector name varies, e.g. `DP-4`) | `5120x2880@60` | `0x0` | 2 |
| `eDP-1` (laptop) | `2560x1600@180` | `<external width>x0`: `2560x0` with the Studio Display, `3440x0` with the ultrawide, `0x0` undocked | 2 |
| `desc:Samsung Electric Company S34CG50 HNTY501103` (ultrawide, USB-C to HDMI from the iGPU; shows up as a `DP-n` connector) | `3440x1440@100` | `0x0` | 1 |

`GDK_SCALE=3` is exported. The main external display always sits at `0x0`, left of the laptop panel. `eDP-1`'s x is computed at config load from the connected external's mode width divided by its scale, instead of `auto-right`, so the layout never depends on which monitor Hyprland configured first. Externals are matched by EDID description, because the Studio Display comes back as a different `DP-n` after a replug or on another port, and a connector-name rule would hand it the fallback (`auto`, scale 3.2). `monitors.lua` returns the "main external display" (Studio Display, else Samsung ultrawide) used by the workspace rules, the Wacom mapping, and `omarchy-toggle-scratch`, and reloads the config on hotplug when it changes, which also recomputes `eDP-1`'s position.

`~/.config/uwsm/env-hyprland` (source `dot_config/uwsm/env-hyprland`, Linux desktop/laptop only) is sourced by uwsm before Hyprland starts. It sets `AQ_DRM_DEVICES` to the AMD iGPU, resolved from `/dev/dri/by-path/pci-0000:c4:00.0-card`, so Hyprland never opens the Thunderbolt eGPU (RTX 5060 Ti, compute only: AI models, CUDA). Every display, the Samsung ultrawide included, hangs off the iGPU. It leaves the variable unset if that path is missing. It also sets `__EGL_VENDOR_LIBRARY_FILENAMES` to Mesa's `50_mesa.json`, so neither Hyprland nor session apps load `libEGL_nvidia` and hold `/dev/nvidiactl`; CUDA does not use EGL.

The system side (kernel cmdline, `nvidia` without KMS, `thunderbolt host_reset=0`) lives outside chezmoi.

## hyprsunset and portal

**~/.config/hypr/hyprsunset.conf**

```ini
profile {
    time = 07:00
    identity = true
}
```

The identity profile stops hyprsunset from tinting the screen. A commented 20:00 / 4000 K night profile and an `o.launch_on_start("hyprsunset")` hint remain in the file.

**~/.config/hypr/xdph.conf**

```ini
screencopy {
    allow_token_by_default = true
    custom_picker_binary = hyprland-preview-share-picker
}
```

Screen-share requests get a restore token by default and use `hyprland-preview-share-picker` as the source picker.

## .luarc.json

Configures lua-language-server for the Lua config: the library path is `/usr/share/hypr/stubs`, `checkThirdParty` is off, and `hl` and `o` are declared as globals.

`autostart.lua` contains only a commented `o.launch_on_start` example.

## Keybindings

Every binding defined in `bindings.lua`. Bindings not listed here are Omarchy defaults. The *Replaces* column gives the Omarchy default that was unbound first.

### Windows

| Keys | Action | Replaces |
| --- | --- | --- |
| `SUPER + Q` | Close window | same (made explicit) |
| `SUPER + W` | `omarchy-toggle-layout` — flip workspace layout | close window |
| `SUPER + BACKSPACE` | Focus last window | toggle transparency |
| `SUPER + TAB` | Next window in the active workspace | next workspace |
| `SUPER + SHIFT + TAB` | Previous window in the active workspace | previous workspace |
| `SUPER + H` / `J` / `K` / `L` | Focus left / down / up / right (`nav.focus`); at the edge, the monitor that way | `J`: toggle split, `K`: keybindings menu, `L`: toggle layout |
| `SUPER + D` | Toggle split (dwindle `togglesplit`) | — |
| `SUPER + SHIFT + H` / `L` | Move left / right (`nav.move`): swap the column; at the edge, carry the window to the monitor that way. Floating: bottom-left / bottom-right corner | — |
| `SUPER + SHIFT + J` / `K` | Move down / up: swap within the column; at its bottom / top, carry the window to the next / previous workspace on this monitor. Floating: top-left / top-right corner | — |
| `SUPER + SHIFT + T` | `omarchy-pip` — toggle picture-in-picture | — |
| `SUPER + M` | Unbound | minimize window to the dock |

`SUPER + TAB` walks a ring built only from the active workspace's mapped windows, ordered by `stable_id`. Grouped windows stay in the ring and hidden ones are skipped. It raises the focused window afterwards. It avoids `cyclenext`, which would pull in a hidden scratchpad.

`nav.lua` picks the neighbor itself rather than using Hyprland's directional focus, which searches the whole layout: on the scrolling tape, `J`/`K` with nothing above or below jumped to an off-screen column. A neighbor must lie past the focused window's centre on the move axis and overlap it on the other axis; inactive group tabs share their group's cell and are skipped. So `J`/`K` stay in the column and `H`/`L` walk the columns.

- **Focus:** `H`/`L` step through a group's tabs before leaving the group. At the tape's edge the key focuses the monitor that way (`eDP-1` is right of the external); nothing past the outer edges. Floating windows use Hyprland's directional focus.
- **Move:** a group on either side makes the move group aware (`window.move` with `group_aware`), merging into or leaving a group. Otherwise `H`/`L` on a scrolling workspace swap the whole column (`swapcol`), and other layouts and `J`/`K` swap windows. With no neighbor, `H`/`L` move the window to the monitor that way and `J`/`K` to the previous/next workspace by id on the same monitor, never wrapping; focus follows. Floating windows go to a corner of their monitor without resizing, inside the reserved area (the bar) and inset 10 px (`general:gaps_out`), clockwise from bottom-left.

`binds.movefocus_cycles_groupfirst = true` stays set for Omarchy's `SUPER + arrows`, which still use Hyprland's directional focus.

### Workspaces and monitors

| Keys | Action | Replaces |
| --- | --- | --- |
| `SUPER + CTRL + J` | Next workspace (`e+1`) | — |
| `SUPER + CTRL + K` | Previous workspace (`e-1`) | Herdr keybindings |
| `ALT + Q` / `W` / `E` / `R` | Switch to workspace 1 / 2 / 3 / 4 (main external display) | — |
| `ALT + Y` / `U` / `I` / `O` | Switch to workspace 5 / 6 / 7 / 8 (laptop panel) | — |
| `ALT + SHIFT + Q` / `W` / `E` / `R` / `Y` / `U` / `I` / `O` | Move window to workspace 1–8 | — |
| `SUPER + CTRL + S` | `omarchy-toggle-scratch scratchpad` | share menu |
| `SUPER + A` | `omarchy-toggle-scratch scratchpad` (Tern) | — |
| `SUPER + O`, `SUPER + SHIFT + O` | Unbound | pop window out, Obsidian |
| `ALT + SHIFT + J` | Move window to next monitor | — |
| `ALT + SHIFT + K` | Move window to previous monitor | — |
| `SUPER + SHIFT + CTRL + ALT + W` | Workspace `name:w` | — |
| `SUPER + SHIFT + CTRL + ALT + H` | Workspace `name:h` | — |
| `SUPER + CTRL + ALT + X` | Workspace `name:x` | — |

Named workspaces provide the per-app workspaces. `SUPER + ALT + S` (send to scratchpad) keeps its Omarchy default.

### Sizing

| Keys | Action |
| --- | --- |
| `SUPER + R` | `omarchy-cycle-window-size` — next preset size |
| `SUPER + SHIFT + R` | `omarchy-cycle-window-size prev` |
| `ALT + SHIFT + H` / `SUPER + ,` | Width −100 px |
| `ALT + SHIFT + L` / `SUPER + .` | Width +100 px |
| `SUPER + CTRL + K` | Height −100 px |
| `SUPER + CTRL + J` | Height +100 px |
| `SUPER + ALT + C` | Fit active column (scrolling layout only) |
| `SUPER + SHIFT + ALT + C` | Fit visible columns (scrolling layout only) |

### Applications

| Keys | Action | Replaces |
| --- | --- | --- |
| `SUPER + CTRL + ALT + L` | Claude Desktop: `omarchy-launch-or-focus com.anthropic.Claude claude-desktop`; an ordinary window, no scratch workspace | — |
| `SUPER + CTRL + A` | Unbound | audio panel |
| `SUPER + CTRL + G` | Gemini: `omarchy-launch-or-focus gemini "gtk-launch gemini-desktop"` | — |
| `SUPER + CTRL + ALT + H` | `omarchy-cycle ai` | — |
| `SUPER + CTRL + ALT + J` | `omarchy-cycle-terminal` | — |
| `SUPER + CTRL + ALT + K` | `omarchy-cycle-browser` | — |
| `SUPER + CTRL + ALT + G` | `omarchy-cycle ghostty` | — |
| `SUPER + CTRL + ALT + O` | `omarchy-cycle obsidian` | — |
| `SUPER + CTRL + ALT + F` | strata: `omarchy-launch-or-focus io.github.lgse.Strata "gtk-launch io.github.lgse.Strata"` | — |
| `SUPER + CTRL + ALT + E` | `omarchy-toggle-scratch fastmail` | World clock (`omarchy.elsewhen` panel) |
| `SUPER + CTRL + ALT + M` | `omarchy-toggle-scratch beeper` | — |
| `SUPER + CTRL + L` | `omarchy-toggle-scratch lmstudio` (LM Studio) | toggle window gaps |
| `SUPER + CTRL + ALT + Y` | `omarchy-summon youtube` | web apps cycle |
| `SUPER + SHIFT + Y` | `omarchy-summon youtube` | YouTube desktop entry |
| `SUPER + CTRL + ALT + T` | tldraw offline: `omarchy-launch-or-focus tldraw-offline "gtk-launch tldraw-offline"` | show time |
| `SUPER + CTRL + ALT + W` | tldraw: `omarchy-launch-or-focus tldraw "gtk-launch TLDraw"` | toggle weather |
| `SUPER + CTRL + ALT + SPACE` | Sticky Notes Canvas via `gtk-launch io.github.faridjaff.StickyNotesCanvas` | — |
| `SUPER + SHIFT + G` | Goliath: `kitty --class=kitty-goliath --title=goliath --session=none --config ~/.config/kitty/goliath.conf mosh goliath`; new tabs and splits there are goliath sessions too (see [kitty](../terminal/kitty.md#goliath-super--shift--g), [SSH and mosh](../tools/ssh.md)) | Signal |
| `SUPER + ALT + SHIFT + F` | `uwsm-app -- "$HOME/.local/bin/strata" "$(omarchy-cmd-terminal-cwd)"` — strata in the terminal's cwd | unbound first (default unnamed) |

strata is the default file manager: `inode/directory` in `mimeapps.list` and the `org.freedesktop.FileManager1` D-Bus service both point at it ([15-tools](../chezmoi/scripts.md#15-tools)). The cwd bind uses the absolute path because `~/.local/bin` may be missing from uwsm-app's `PATH`. Omarchy's own file-manager bind on `SUPER + SHIFT + F` is replaced by full screen (below). A rule tagging `com.thisisgm.flea.picker` as `+floating-window` still sits between `flea --picker` marker comments, which the `flea` tool writes and removes itself.

### Screenshots, session, menus

| Keys | Action | Replaces |
| --- | --- | --- |
| `SUPER + S` | `omarchy-capture-screenshot region` | toggle scratchpad |
| `SUPER + SHIFT + S` | `omarchy-capture-screenshot windows` | Google Maps |
| `SUPER + SHIFT + ALT + S` | `omarchy-capture-screenshot fullscreen` | — |
| `SUPER + SHIFT + E` | `omarchy-menu toggle system` | Email |
| `SUPER + SHIFT + Q` | `omarchy-menu toggle system` | — |
| `SUPER + F24` | `voxtype record toggle --profile hermes` — dictation | — |
| `SUPER + CTRL + X` | `omarchy-dictation toggle` (only when `o.dictation_installed()`) | — |
| `F9` (hold) | Push-to-talk: `omarchy-dictation start` on press, `stop` on release (only when `o.dictation_installed()`) | — |
| `SUPER + SHIFT + SPACE` | Emoji picker (`omarchy-shell shell toggle omarchy.emojis`) | toggle top bar |
| `SUPER + P` | Clipboard manager (`omarchy-shell shell toggle omarchy.clipboard`) | pseudo window |
| `ALT + TAB` | ScrollOverview `toggle all` (only when the plugin is loaded) | Omarchy's two `ALT + TAB` binds |

`SUPER + SPACE` (Omarchy menu) and `SUPER + ALT + SPACE` (apps menu) keep their Omarchy defaults. `SUPER + RETURN` (terminal) and `SUPER + SHIFT + RETURN` (browser) are unbound; terminals and browsers live on `SUPER + CTRL + ALT + J` / `K`.

### ScrollOverview plugin

When `hl.plugin.scrolloverview` is present, `bindings.lua` configures it:

| Option | Value |
| --- | --- |
| `gesture_distance` | 300 |
| `scale` | 0.5 |
| `workspace_gap` | 100 |
| `layout` | `vertical` |
| `wallpaper` | 2 (global and per-workspace) |
| `blur` | true |
| `shadow` | enabled, range 50 |

## omarchy scripts

The scripts live in `dot_local/bin/` as `executable_omarchy-*` and deploy to `~/.local/bin/`. Each one calls the Lua dispatcher first (`hyprctl dispatch "hl.dsp…"`) and falls back to the classic dispatcher name on older Hyprland.

### omarchy-cycle

```sh
omarchy-cycle <app|browser|brave|terminal|ai|ghostty|kitty|kitty-CLASS|webapp|webapp-NAME>
```

Focuses an app's window, cycles to the next one on repeated presses, or launches the app when none is open. Windows are matched on `class` or `initialClass` (case-insensitive) and sorted by workspace, then address. If the focused window is not in the set, focus goes to the first one. Launches use `setsid uwsm-app --`.

| Argument | Matches | Launches when none |
| --- | --- | --- |
| `webapp` | `^(webapp-\|chrome-)` | re-runs as `webapp-youtube` |
| `webapp-NAME` | `webapp-NAME` or `^chrome-.*NAME` | `gtk-launch` on the first `WebApp-NAME*.desktop` or `*NAME*.desktop` in `~/.local/share/applications` |
| `kitty` | `^kitty` | `kitty` |
| `kitty-CLASS` | `^kitty-CLASS$` | `kitty --class kitty-CLASS` (command from the empty `KITTY_CMDS` map, if set) |
| `ghostty` | `ghostty` | `ghostty` |
| `browser` | zen, brave, chromium, google-chrome, firefox, librewolf, vivaldi, microsoft-edge, helium — excluding `chrome-`/`webapp-` web apps | `omarchy-launch-browser` |
| `brave` | `^brave` (Brave Origin and its web apps) | `omarchy-launch-browser` |
| `terminal` | kitty, alacritty, ghostty, foot, wezterm (Tern, the scratchpad terminal, does not match) | `omarchy-launch-terminal` (`xdg-terminal-exec`: the OS default terminal from `~/.config/xdg-terminals.list`, in the focused terminal's cwd) |
| `ai` | `claude\|hermes` | `hermes desktop` |
| anything else | `^APP$` | the argument as a command |

Bound to `SUPER + CTRL + ALT + H` (`ai`), `G` (`ghostty`), and `O` (`obsidian`).

### omarchy-cycle-browser / omarchy-cycle-terminal

One-line wrappers: `omarchy-cycle brave` and `omarchy-cycle terminal`. Bound to `SUPER + CTRL + ALT + K` and `SUPER + CTRL + ALT + J`.

### omarchy-launch-browser

```sh
omarchy-launch-browser [--private] [url]
```

Shadows Omarchy's `/usr/bin/omarchy-launch-browser` (`~/.local/bin` comes first on `PATH`) and hands off to it. When Brave Origin is the default browser and not running, it prepends `--restore-last-session --hide-crash-restore-bubble`, so the first launch after a reboot or power-off reopens the last session's windows without the "Restore pages?" prompt. Chromium treats a killed browser as crashed and skips the restore; `--hide-crash-restore-bubble` clears that state. Private launches and launches into a running browser pass through unchanged.

### omarchy-cycle-window-size

```sh
omarchy-cycle-window-size [next|prev]
```

Steps the focused window through preset widths `0.333, 0.5, 0.667` of the monitor.

- **Scrolling layout (tiled):** sends `colresize +conf` / `-conf`, so the layout's own preset list is used.
- **Floating:** resizes to the fraction × monitor width and 0.8 × monitor height, then centers. The index is stored per window.
- **Dwindle/master (tiled):** sets `splitratio` to `2 × fraction`, mirrored when the window is on the right or bottom half, clamped to 0.1–1.9. The index is stored per workspace.

Indices are stored in `$XDG_STATE_HOME/omarchy/window-sizes/`. Bound to `SUPER + R` and `SUPER + SHIFT + R`.

### omarchy-pip

```sh
omarchy-pip [toggle|on] [address:0x...]
```

Picture-in-picture for any window. Floats and pins it, resizes it to 30% of the focused monitor on both axes, and places it in the bottom-left corner with a 10 px inset (matching `general:gaps_out`). `toggle` (the default) unpins and re-tiles a window that is already floating and pinned. `on` always applies the fit. Defaults to the active window. The dispatcher is called with `on`/`off` because `set` toggles on Hyprland 0.56. Bound to `SUPER + SHIFT + T`. `omarchy-summon` also calls it.

### omarchy-summon

```sh
omarchy-summon [youtube]
```

The only profile is `youtube`, which matches class `^brave-(www\.)?youtube\.com__.*$` and skips Picture-in-Picture titles. With no window open, it runs `gtk-launch YouTube`, and the window rule in `hyprland.lua` floats and positions it. With a window open, it moves the window to the focused monitor, runs `omarchy-pip on` to refit it (the two panels differ in logical size), and focuses it. Bound to `SUPER + CTRL + ALT + Y` and `SUPER + SHIFT + Y`.

### omarchy-toggle-layout

```sh
omarchy-toggle-layout [width]
```

Runs `omarchy-hyprland-workspace-layout-toggle`, then polls the workspace layout (6 × 50 ms). If it became `scrolling`, it runs `colresize all <width>` (default `0.75`). Dwindle needs no widths. Bound to `SUPER + W`.

### omarchy-toggle-scratch

```sh
omarchy-toggle-scratch [scratchpad|fastmail|beeper|home|lmstudio]
```

| Profile | Special workspace | Home monitor | Residents (class → launch) |
| --- | --- | --- | --- |
| `scratchpad` | `special:scratchpad` | Studio Display, else Samsung ultrawide | `so.stencil.tern` → `tern` |
| `fastmail` | `special:fastmail` | `eDP-1` | `com.fastmail.Fastmail` → `gtk-launch com.fastmail.Fastmail` |
| `beeper` | `special:beeper` | `eDP-1` | `Beeper` → `gtk-launch beeper` |
| `home` | `special:home` | focused | `brave-home\.google\.com__.*` → `gtk-launch 'Google Home'` |
| `lmstudio` | `special:lmstudio` | focused | `ai\.elementlabs\.lmstudio` → `gtk-launch ai.elementlabs.lmstudio` |

If the workspace is visible, the script hides it. If not, it launches any resident with no window there, waits up to 8 s for the first new window, and reveals the workspace on the home monitor (or the focused one if the home monitor is absent). Launching only missing residents avoids duplicate web-app windows. Bound to `SUPER + CTRL + S`, `SUPER + A`, `SUPER + CTRL + ALT + E`, `SUPER + CTRL + ALT + M`, `SUPER + CTRL + H`, and `SUPER + CTRL + L`.

## Related

- [Waybar](waybar.md): the bar used with this setup.
- [kitty](../terminal/kitty.md): the `herdr` kitty config and the goliath kitty launched here.
