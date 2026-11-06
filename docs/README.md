# dots (omarchy)

prdlk's dotfiles for [Omarchy](https://omarchy.org) (Arch Linux + Hyprland), managed with chezmoi. One command installs chezmoi and applies the whole setup.

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://prad.codes/env/omarchy.git
```

That command installs chezmoi, clones [env/omarchy](https://prad.codes/env/omarchy) together with its submodules, asks three questions (name, email, machine role), installs packages, and applies every config. See [Installation](installation.md) for prerequisites, the age key step, and the options.

## Table of contents

- [Installation](installation.md): Omarchy first, then the one-liner, the age key, roles, and updating.
- [How it works](chezmoi/README.md): chezmoi layout, machine roles, symlink mode, age encryption, package manifests, apply scripts, and externals.
  - [Overview](chezmoi/README.md)
  - [Configuration](chezmoi/config.md)
  - [Data files](chezmoi/data.md)
  - [Scripts](chezmoi/scripts.md)
  - [Externals and ignore rules](chezmoi/externals-and-ignore.md)
- [Shell](shell/README.md): fish, bash, and zsh with shared aliases, starship, atuin, and the `~/.local/bin` scripts.
  - [Overview](shell/README.md)
  - [fish](shell/fish.md)
  - [bash and zsh](shell/bash-zsh.md)
  - [Aliases](shell/aliases.md)
  - [Scripts](shell/scripts.md)
  - [Starship](shell/starship.md)
  - [Atuin](shell/atuin.md)
- [Terminal](terminal/README.md): kitty, ghostty, tmux, and herdr.
  - [Overview](terminal/README.md)
  - [kitty](terminal/kitty.md)
  - [Ghostty](terminal/ghostty.md)
  - [tmux](terminal/tmux.md)
  - [herdr](terminal/herdr.md)
- [Tools](tools/README.md): git, gh and gh-dash, neovim, yazi, lazygit, lazydocker, bat, topgrade, hunk, and more.
  - [Overview](tools/README.md)
  - [Git](tools/git.md)
  - [GitHub CLI](tools/github-cli.md)
  - [Neovim](tools/neovim.md)
  - [Yazi](tools/yazi.md)
  - [lazygit](tools/lazygit.md)
  - [lazydocker](tools/lazydocker.md)
  - [bat](tools/bat.md)
  - [television](tools/television.md)
  - [Topgrade](tools/topgrade.md)
  - [hunk](tools/hunk.md)
  - [drydock](tools/drydock.md)
  - [LeetCode](tools/leetcode.md)
- [Desktop](desktop/README.md): Omarchy, Hyprland, Waybar, fonts, and default apps.
  - [Overview](desktop/README.md)
  - [Hyprland](desktop/hyprland.md)
  - [Waybar](desktop/waybar.md)
  - [Fonts and apps](desktop/fonts-and-apps.md)
- [AI agents](ai/README.md): Claude Code, omp, and the shared agent skill library.
  - [Overview](ai/README.md)
  - [Skills](ai/skills.md)

## Machine roles

The first apply asks for a role. It controls which parts of the repo land on the machine.

| Role | Platform | Gets |
| --- | --- | --- |
| `desktop` | Omarchy (Arch Linux) | Everything: universal toolset plus the Linux desktop layer |
| `laptop` | Omarchy (Arch Linux) | Same as `desktop` |
| `server` | Any Linux | Universal toolset only |

The default is `desktop`. See [Configuration](chezmoi/config.md) and [Ignore rules](chezmoi/externals-and-ignore.md).

## Theme

The terminal and agent palette is **cyberdream** ([cyberdream.nvim](https://github.com/scottmckendry/cyberdream.nvim); background `#16181a`, foreground `#ffffff`, accent `#5ea1ff`). Ghostty selects its `cyberdream` theme, tmux colors its tab bar, popups, and command palette with it, atuin selects `cyberdream`, television selects `cyberdream-transparent` (no background, so the terminal's shows through), lazygit and lazydocker use its border and selection colors, Starship selects its `cyberdream` palette, omp selects its `cyberdream` dark theme, and nvim, bat, and yazi select it too; fish ships a cyberdream theme but does not select it. kitty takes its colors from the active Omarchy theme (also cyberdream). The CherryBlossom variants stay shipped but unselected for ghostty, atuin, television, yazi, and omp, as do the koda and ii-auto variants for ghostty, kitty, and yazi. The font is **Victor Mono Nerd Font**.
