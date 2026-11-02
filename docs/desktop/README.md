# Desktop

The Linux desktop layer: Omarchy, the Hyprland config on top of it, the Waybar bar, fontconfig, and default applications.

> [!NOTE]
> **Role gating**
>
> `.chezmoiignore.tmpl` skips the Linux desktop layer unless the machine runs Linux **and** its role is `desktop` or `laptop`. The gated targets are `~/.config/hypr`, `~/.config/waybar`, `~/.config/uwsm`, `~/.config/fontconfig`, `~/.config/mimeapps.list`, `~/.config/xdg-terminals.list`, `~/.config/systemd`, `~/.local/bin/agent-root`, `~/.local/bin/kitty-day-save`, `~/.local/bin/cp-appid`, and `~/.local/bin/projects-sync`. On the `server` role these are not applied.
>
> The `omarchy-*` scripts in `~/.local/bin` are **not** listed there, so chezmoi applies them on every role.

The desktop is [Omarchy](https://omarchy.org) (Arch Linux with Hyprland). Omarchy provides the compositor, the defaults, the theme, the menus, and the `omarchy-*` commands. This repo only overrides: a Hyprland Lua config (the `dot_config/hypr` submodule), a replacement Waybar layout, the `omarchy-*` helper scripts, the uwsm session environment, and the `~/.config/omarchy` external.

| Page | Covers |
| --- | --- |
| [Hyprland](hyprland.md) | `~/.config/hypr` Lua config on Omarchy: bindings, input, look and feel, monitors, hyprsunset, the portal; every `omarchy-*` script in `~/.local/bin`. `~/.config/omarchy` (shell, hooks, menus, themes) is the [prdlk/omarchy](https://github.com/prdlk/omarchy) external, see [externals](../chezmoi/externals-and-ignore.md#chezmoiexternals) |
| [Waybar](waybar.md) | `~/.config/waybar`: module layout, stylesheet, the `window_pill.py` title module |
| [Fonts and default apps](fonts-and-apps.md) | `~/.config/fontconfig/fonts.conf`, `~/.config/mimeapps.list`, the Victor Mono Nerd Font package |

## Packages

`.chezmoidata/packages.yaml` declares the desktop packages under `packages.arch.desktop`. `.chezmoiscripts/run_onchange_before_10-packages.sh.tmpl` installs them only when the role is `desktop` or `laptop`:

| Source | Packages |
| --- | --- |
| pacman | `uwsm`, `xdg-user-dirs`, Wayland utilities (`wl-clipboard`, `cliphist`, `wtype`, `ydotool`, `grim`, `slurp`, `hyprpicker`, `pamixer`, `brightnessctl`, `libnotify`), the bound apps (`nautilus`, `imv`, `mpv`, `evince`, `chromium`, `obsidian`), and strata's runtime deps |
| AUR via `yay` (a sync repo wins when it has the name) | `tldraw-offline-bin` and the desktop apps `beeper-bin`, `fastmail`, `1password`, `brave-origin-bin`, `claude-desktop`, `spotify` |
| `[omarchy]` repo, when configured | `herdr`, `flea`, `voxtype-bin`, `xdg-terminal-exec`, `hyprland-preview-share-picker` |

AUR names that an installed package already provides are skipped; with no `yay` or `paru` the script bootstraps `yay` first. strata, the default file manager, comes from its own installer in [15-tools](../chezmoi/scripts.md#15-tools). Hyprland, Waybar, and the `omarchy-*` commands that the scripts call (`omarchy-menu`, `omarchy-launch-or-focus`, and others) come from the Omarchy install. This repo does not install them. See [chezmoi scripts](../chezmoi/scripts.md) for the full install flow and [packages.yaml](../chezmoi/data.md#packagesyaml) for the complete lists.
