# dotfiles

prdlk's cross-platform developer environment for Arch, macOS and Ubuntu, managed with chezmoi. On [Omarchy](https://omarchy.org) machines (Arch Linux + Hyprland) the desktop layer from [env/omarchy-desktop](https://prad.codes/env/omarchy-desktop) is applied on top. One command installs chezmoi and applies the whole setup.

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/prdlk/dotfiles.git
```

That command installs chezmoi, clones [prdlk/dotfiles](https://github.com/prdlk/dotfiles), asks two questions (name, email), installs packages with the OS package manager, and applies every config. See [Installation](installation.md) for prerequisites, the age key step, and the options.

## Table of contents

- [Installation](installation.md): prerequisites per OS, the one-liner, the age key, what differs per OS, the Omarchy desktop layer, and updating.
- [How it works](chezmoi/README.md): chezmoi layout, the OS-family template, symlink mode, age encryption, package manifests, apply scripts, and externals.
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
- [AI agents](ai/README.md): Claude Code, omp, and the shared agent skill library.
  - [Overview](ai/README.md)
  - [Skills](ai/skills.md)

The Omarchy desktop layer (Hyprland, Waybar, fonts and default apps, the `omarchy-*` scripts, free-router) is documented in the [env/omarchy-desktop docs](https://prad.codes/env/omarchy-desktop/src/branch/main/docs/README.md).

## What differs per OS

There are no machine roles. The first apply asks for name and email only; the OS decides the rest.

| OS | Packages | Desktop layer |
| --- | --- | --- |
| Arch / Omarchy | pacman and AUR | Applied when `omarchy` is on `PATH` |
| macOS | Homebrew formulae and casks | None |
| Ubuntu | apt, with mise for tools apt lacks | None |

See [Installation](installation.md#what-differs-per-os) and [Configuration](chezmoi/config.md#os-family).

## Theme

The terminal and agent palette is **cyberdream** ([cyberdream.nvim](https://github.com/scottmckendry/cyberdream.nvim); background `#16181a`, foreground `#ffffff`, accent `#5ea1ff`). Ghostty selects its `cyberdream` theme, tmux colors its tab bar, popups, and command palette with it, atuin selects `cyberdream`, television selects `cyberdream-transparent` (no background, so the terminal's shows through), lazygit and lazydocker use its border and selection colors, Starship selects its `cyberdream` palette, omp selects its `cyberdream` dark theme, and nvim, bat, and yazi select it too; fish ships a cyberdream theme but does not select it. kitty takes its colors from the active Omarchy theme on Omarchy machines (also cyberdream). The CherryBlossom variants stay shipped but unselected for ghostty, atuin, television, yazi, and omp, as do the koda and ii-auto variants for ghostty, kitty, and yazi. The font is **Victor Mono Nerd Font**.
