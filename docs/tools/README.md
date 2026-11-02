# Tools

CLI and TUI tools the repo installs and configures, with the settings applied to each.

This section covers the command-line and terminal-UI tools outside the shell, terminal, and desktop layers. Every tool here is universal: none of it is gated by machine role, so `desktop`, `laptop`, and `server` machines all get it (see [Installation](../installation.md)).

Packages come from `.chezmoidata/packages.yaml` and are installed by `run_onchange_before_10-packages.sh.tmpl` (pacman plus yay for the AUR). See [chezmoi scripts](../chezmoi/scripts.md).

## Configured tools

| Page | Tool | Source in repo | Theme |
| --- | --- | --- | --- |
| [Git](git.md) | git, delta, diffnav, git-split-diffs | `dot_gitconfig.tmpl` | delta colors hand-tuned (dark) |
| [GitHub CLI](github-cli.md) | gh, gh extensions, gh-dash | `dot_config/gh/`, `dot_config/gh-dash/` | gh-dash defaults |
| [Neovim](neovim.md) | nvim (AstroNvim) | external repo via `.chezmoiexternal.toml` | managed in the nvim repo |
| [Yazi](yazi.md) | yazi file manager | external repo via `.chezmoiexternals/yazi.toml` | cyberdream flavor (ii-auto flavor shipped) |
| [Lazygit](lazygit.md) | lazygit | `dot_config/lazygit/` | cyberdream colors (ii theme file shipped) |
| [Lazydocker](lazydocker.md) | lazydocker | `dot_config/lazydocker/config.yml` | cyberdream colors |
| [bat](bat.md) | bat | `dot_config/bat/` | cyberdream tmTheme |
| [Topgrade](topgrade.md) | topgrade | `dot_config/topgrade.toml` | n/a |
| [Hunk](hunk.md) | hunk diff viewer | `dot_config/hunk/config.toml` | `auto` |
| [drydock](drydock.md) | drydock repo fleet view | `dot_config/drydock/config.toml` | n/a |
| [television](television.md) | tv fuzzy picker, custom cables | external repo via `.chezmoiexternals/television.toml` | `cyberdream-transparent` |
| [LeetCode](leetcode.md) | leetcode CLI, `lc-elir` | `dot_leetcode/` | n/a |

- [Git](git.md): Identity from chezmoi data, diff pagers, gh credential helper.
- [Yazi](yazi.md): Keymap, plugins, bookmarks, and the Neovim bridge.
- [Lazygit](lazygit.md): GUI options, delta renderer, custom gh commands.
- [GitHub CLI](github-cli.md): Aliases, extensions, and the gh-dash dashboard.

## Other packaged CLI tools

These packages are declared in `.chezmoidata/packages.yaml` but have no config file in the repo. The "Wired in" column lists where the repo actually uses them.

| Tool | Role | Wired in |
| --- | --- | --- |
| `fzf` | Fuzzy finder | `FZF_DEFAULT_OPTS` in `dot_config/fish/conf.d/10-env.fish` (rounded border, cyberdream colors: highlight `#5ef1ff`, pointer `#ffaecf`, marker `#5eff6c`). Used by fish functions `c2p`, `cp-appid`, `fab`, `gtm`, `mdp`, `lc-elir`, by `~/.local/bin` scripts (`lc-elir`), and as `fuzzy_cmd` of the yazi bunny plugin. The shell pickers (`gho`, `pj`, <kbd>ctrl-e</kbd>) use [television](television.md). |
| `fd` | File finder | `c2p`, `cp-appid`, `extract_agents`, `mdp`, `lc-elir`, `conf.d/pnpm-filter.fish`. |
| `ripgrep` | Content search | `cp-appid`, `gtm`, `gh-sonr-org-migrate` fish functions. |
| `zoxide` | Frecency `cd` | `zoxide init fish` in `conf.d/40-tools.fish`; the `cd` function in fish/bash/zsh falls back to `zoxide query` when the argument is not a directory, and `ghg-clone` registers new clones. |
| `eza` | `ls` replacement | Interactive shells alias `ls` to `eza --icons` (fish `conf.d/20-aliases.fish`, `~/.config/shell/aliases.sh`). |
| `jq` | JSON processor | `fab`, `gtm`, `gh-sonr-org-migrate`, `pnpm-filter`. |
| `duf` | Disk usage overview | Not referenced by any config. |
| `btop` | Resource monitor | Waybar modules launch it on click (`omarchy-launch-or-focus-tui btop`); kitty tab bar shows an icon for it. |
| `fastfetch` | System info | Not referenced by any config. |
| `gum` | Shell prompts and pickers | `gdc` (confirm before `git reset --hard`), `ghn` (host and org pickers), `gtm`, `ai`, `pnpm-filter`, nvm activation messages. |
| `glow` | Markdown renderer | Kitty tab-bar icon only. |
| `micro` | Terminal editor | Alias `sm` = `sudo micro`. |
| `ffmpeg`, `ffmpegthumbnailer`, `poppler`, `resvg`, `imagemagick`, `7zip`, `unzip` | Media, PDF, SVG, image, and archive backends | Grouped in the manifest as yazi preview dependencies. See [Yazi](yazi.md). |
| `wget` | HTTP downloads | Not referenced by any config. |
| `zsh-syntax-highlighting` | zsh highlighting | Sourced by the zsh setup. See [Shell](../shell/README.md). |
| `ttf-victor-mono-nerd` / `font-victor-mono-nerd-font` | Nerd Font | Terminal font. See [Terminal](../terminal/README.md). |
| `suvadu`, `mandible`, `worktrunk` | Declared under `packages.shared.cargo` | Installed by [`15-tools`](../chezmoi/scripts.md#15-tools), which installs rustup first when `cargo` is missing. `mandible` backs the tmux-palette "mandible" item via `~/.local/bin/mandible-pick`. `worktrunk` is the `wt` git-worktree CLI for parallel agent workflows. |

Tools with their own pages in other sections: [fish](../shell/fish.md), [starship](../shell/starship.md), and [atuin](../shell/atuin.md) under Shell; [kitty](../terminal/kitty.md) and [tmux](../terminal/tmux.md) under Terminal.

> [!NOTE]
> `topgrade` comes from the AUR. See the individual pages for per-tool package details.
