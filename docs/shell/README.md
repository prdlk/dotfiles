# Shell

fish, bash, and zsh with shared aliases, the starship prompt, atuin history, and the ~/.local/bin scripts.

fish is the main interactive shell. bash and zsh are set up to feel the same: they share aliases, the prompt, atuin history, and ports of the cd-style helper functions. General-purpose tools are POSIX or bash scripts in `~/.local/bin`, so each has a single implementation that all three shells call.

| Page | Covers |
| --- | --- |
| [fish](fish.md) | `~/.config/fish`: `config.fish`, every `conf.d/` file (PATH, env, aliases, ssh-agent, tool init, secrets by name), vi-mode key bindings, the cyberdream theme, completions, the nvm.fish plugin, and every function in `functions/` |
| [bash and zsh](bash-zsh.md) | `~/.bashrc`, `~/.zshrc`, zsh and bash key bindings, `~/.config/shell/aliases.sh`, per-shell function ports |
| [Aliases](aliases.md) | Every alias from `.chezmoidata/aliases.yaml` plus the fish-only and shell-specific ones |
| [Scripts](scripts.md) | Every general-purpose executable in `~/.local/bin` (`pj`, `ghn`, `gop`, `mtime-sort`, `atuin-pick`, …) |
| [Starship](starship.md) | `~/.config/starship.toml`: format, modules, symbols, cyberdream palette |
| [atuin](atuin.md) | `~/.config/atuin`: history search settings, AI inline integration, cyberdream theme |

## Shared across shells

| Concern | fish | bash | zsh |
| --- | --- | --- | --- |
| Aliases | `conf.d/20-aliases.fish` (hand-maintained) | `~/.config/shell/aliases.sh` (rendered from YAML) | same as bash |
| Prompt | starship + transient prompt | starship | starship + transient prompt |
| History | atuin (hishtory also sourced if installed) | atuin | atuin, plus suvadu if installed |
| Key bindings | vi mode plus custom binds | atuin defaults only | emacs keymap plus ports of the fish binds |
| cd-style helpers | `functions/*.fish` | `~/.config/bash/functions/*.bash` | `~/.config/zsh/functions/*.zsh` |
| Directory jumping | `cd` wrapper with zoxide fallback, `zoxide init` | `cd` wrapper | `cd` wrapper |

## Theme

fish syntax colors, `FZF_DEFAULT_OPTS`, the starship palette, and the atuin theme all use **cyberdream** ([cyberdream.nvim](https://github.com/scottmckendry/cyberdream.nvim)). In fish, `40-tools.fish` also replays quickshell's wallpaper-generated terminal color sequences if that file exists.

## Role gating

Everything in this section applies on every role (`desktop`, `laptop`, `server`). The desktop helpers in `~/.local/bin` are the exception; they come with the rest of the [desktop layer](../desktop/README.md).

## Packages

`.chezmoidata/packages.yaml` supplies the shell tooling through pacman: `fish`, `starship`, `atuin`, `zoxide`, `fzf`, `fd`, `ripgrep`, `eza`, `bat`, `jq`, `gum`, `glow`, `yazi`, `lazygit`, and `zsh-syntax-highlighting`. See [chezmoi scripts](../chezmoi/scripts.md).
