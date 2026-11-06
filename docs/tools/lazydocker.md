# Lazydocker

Lazydocker with rounded borders and the cyberdream border and selection colors shared with lazygit.

[Lazydocker](https://github.com/jesseduffield/lazydocker) is a terminal UI for Docker containers, images, volumes, and compose projects. The config only restyles it to match [lazygit](lazygit.md).

| | |
| --- | --- |
| Source | `dot_config/lazydocker/config.yml` |
| Target | `~/.config/lazydocker/config.yml` |
| Packages | `lazydocker` (pacman) |

## Settings

**~/.config/lazydocker/config.yml**

```yaml
gui:
  border: rounded
  theme:
    activeBorderColor:
      - "#5ef1ff"
    inactiveBorderColor:
      - "#7b8496"
    selectedLineBgColor:
      - "#3c4048"
    optionsTextColor:
      - "#3c4048"
```

| Key | Value | Palette |
| --- | --- | --- |
| `gui.border` | `rounded` | |
| `activeBorderColor` | `#5ef1ff` | cyberdream cyan |
| `inactiveBorderColor` | `#7b8496` | cyberdream grey |
| `selectedLineBgColor` | `#3c4048` | cyberdream selection |
| `optionsTextColor` | `#3c4048` | cyberdream selection |

Everything else (keybindings, commands, log settings) is left at lazydocker's defaults.

## Launching

| Entry point | Behavior |
| --- | --- |
| `dd` | Alias for `lazydocker` in fish, bash, and zsh. It shadows the coreutils `dd` binary wherever the aliases are loaded; use `command dd` for the real one. |

tmux-resurrect lists `lazydocker` among the processes it restores, and the kitty tab bar shows a Docker icon while it runs.
