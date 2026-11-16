# Packages and aliases

The .chezmoidata YAML files that declare every installed package and every shared shell alias, and how they render.

Files in `.chezmoidata/` are merged into chezmoi's template data on every run. Nothing in the directory is written to `$HOME`; the data only reaches the machine through templates and scripts.

| File | Data key | Consumed by |
| --- | --- | --- |
| `.chezmoidata/packages.yaml` | `.packages` | [`run_onchange_before_10-packages.sh.tmpl`](scripts.md#10-packages), [`run_onchange_after_15-tools.sh.tmpl`](scripts.md#15-tools), [`run_onchange_after_20-gh-extensions.sh.tmpl`](scripts.md#20-gh-extensions) |
| `.chezmoidata/aliases.yaml` | `.aliases` | `dot_config/shell/aliases.sh.tmpl` (bash and zsh) |
| `.chezmoidata/skills.yaml` | `.skills` | [`run_onchange_after_25-skills.sh.tmpl`](scripts.md#25-skills) |
| `.chezmoidata/user.yaml` | `.name`, `.email` | `dot_gitconfig.tmpl` (git identity; one user, so not prompted) |

## packages.yaml

`packages.tools` is one list with an entry per tool saying how each OS gets it, plus a `shared` block that is the same on every OS. What a machine installs is the manifest minus the software unticked at `chezmoi init` ([Software selection](config.md#software-selection)); `.chezmoitemplates/packages` does the filtering, and the install scripts render the resulting lists, so a manifest edit or a new choice re-runs them on the next `chezmoi apply`. Installs are idempotent (`pacman --needed`, only missing Homebrew formulae, `apt-get install`). The lists are derived from what the configs actually invoke: tmux-palette items, television cable `requirements`, fish functions, and `~/.local/bin` scripts. Desktop-only packages (Wayland utilities, GUI apps) are not here; they belong to [env/omarchy-desktop](https://prad.codes/env/omarchy-desktop).

### Tools

Each `packages.tools` entry is a flow map, for example `{name: fd, arch: fd, brew: fd, mise: fd}`. A key left out means the tool is not installed on that OS.

| Key | Meaning |
| --- | --- |
| `name` | The choice in the init picker. Entries sharing a name are one choice: `mdfried` covers the tool and its Ubuntu build libraries |
| `core` | `true` for what the install scripts need themselves (git, curl, `base-devel` / `build-essential`, jq, mise): always installed, not offered |

| Key | Used on | Installed by |
| --- | --- | --- |
| `arch` | Arch | pacman, only names no installed package provides (`pacman -T`) |
| `aur` | Arch | `yay` or `paru` (`yay` bootstrapped if neither exists) |
| `brew` | macOS | `brew install` (formula) |
| `cask` | macOS | `brew install --cask` |
| `apt` | Ubuntu | `apt-get install` |
| `mise` | Ubuntu, when the entry has no `apt` | `mise use -g <spec>` in [15-tools](scripts.md#15-tools); a registry short name or a backend spec such as `aqua:owner/repo` |

`mise` is the Ubuntu fallback for tools apt lacks, ships years behind, or installs under another binary name (`batcat`, `fdfind`). Names were verified against pacman and the AUR, formulae.brew.sh and Ubuntu 24.04 (noble).

### Per-OS install keys

The groups below show what `packages.tools` covers. Deviations by OS:

| Group | Tools | Differences |
| --- | --- | --- |
| Shell and build | `fish`, `zsh`, `git`, `curl`, `wget`, `base-devel` / `build-essential` | `fish` on Ubuntu comes from `ppa:fish-shell/release-4` (noble ships 3.7). macOS ships zsh and curl. `pkg-config`, `libchafa-dev` and `libglib2.0-dev` are Ubuntu-only (the `mdfried` build). On macOS the Xcode command line tools come with Homebrew |
| Editors | `neovim`, `helix`, `micro`, `tmux` | Ubuntu: `neovim` and `helix` through mise (`aqua:` specs), `tmux` through mise (static `tmux/tmux-builds`: noble's 3.4 rejects `extended-keys-format` in `tmux.conf`) |
| Terminals | `ghostty`, `kitty` | `ghostty` has no Ubuntu 24.04 package. `kitty` is a cask on macOS |
| TUI tools | `yazi`, `lazygit`, `lazydocker`, `docker`, `docker-compose`, `btop`, `fastfetch`, `onefetch`, `television`, `serie`, `tig`, `gitui`, `tldr`, `navi`, `mdfried` | Ubuntu: apt where it has the tool, else mise. `docker` is `docker.io` on Ubuntu; on macOS it is the CLI only (the daemon needs Docker Desktop, colima or OrbStack). `tldr` is `tealdeer` on Homebrew and apt |
| VCS and forge | `git`, `github-cli`, `git-delta`, `diffnav`, `tea` | `github-cli` is `gh` on Homebrew and mise. `tea` uses a pinned `aqua:` spec on Ubuntu (apt's `tea` is an unrelated editor) |
| Search and files | `fzf`, `fd`, `ripgrep`, `zoxide`, `eza`, `bat`, `jq`, `duf` | `fzf`, `fd`, `eza`, `bat` through mise on Ubuntu (apt's fzf predates `--fish`/`--tmux`; `fd` and `bat` install as `fdfind`/`batcat`) |
| Media and preview | `ffmpeg`, `ffmpegthumbnailer`, `poppler`, `resvg`, `imagemagick`, `chafa`, `7zip`, `unzip` | `poppler` is `poppler-utils` on apt. `imagemagick` is `conda:imagemagick` on Ubuntu (apt has ImageMagick 6, no `magick`). `7zip` is `sevenzip` on Homebrew |
| Remote | `mosh`, `sshfs`, `tailscale` | `sshfs` is not installed on macOS (it needs macFUSE). `tailscale` on Ubuntu comes from the pkgs.tailscale.com apt repo |
| Misc CLI | `mise`, `gum`, `glow`, `atuin`, `starship`, `zsh-syntax-highlighting`, `topgrade`, `portop` | `mise` on Ubuntu is installed by [15-tools](scripts.md#15-tools) from `https://mise.run`. `topgrade` and `portop` are AUR packages on Arch |
| Fonts | Victor Mono Nerd Font | `ttf-victor-mono-nerd` (Arch), `font-victor-mono-nerd-font` cask (macOS), a nerd-fonts release download into `~/.local/share/fonts/VictorMonoNerdFont` (Ubuntu, in [10-packages](scripts.md#10-packages)) |

Names some installed package already provides are skipped on Arch, and yay is bootstrapped when no helper exists ([10-packages](scripts.md#10-packages)).

### Shared

`packages.shared.gh_extensions`, installed by the gh-extensions script:

| Extension | Purpose |
| --- | --- |
| `davidraviv/gh-clean-branches` | `gh clean-branches`: delete local branches whose upstream is gone |
| `prdlk/gh-commit` | `gh commit` |
| `dlvhdr/gh-dash` | `gh dash`: PR and issue dashboard |
| `meiji163/gh-notify` | `gh notify`: notifications in the terminal |

`packages.shared.cargo` lists `suvadu`, `mandible` (the tmux-palette "mandible" item runs `~/.local/bin/mandible-pick`), and `worktrunk` (`wt`, git worktree management for parallel agent work). [`run_onchange_after_15-tools.sh.tmpl`](scripts.md#15-tools) installs rustup when `cargo` is missing, then any crate `cargo install --list` lacks.

`packages.shared.mise` lists the global mise tools on every OS: `ghq`, `bun`, `node`, `uv`, `opencode`, `crush`, and omp as `github:can1357/oh-my-pi` (omp is not in the mise registry, so it uses the GitHub-releases backend, which installs the release binary as `omp`). The same script runs `mise use -g` for each one not yet in the global config (`~/.config/mise/config.toml`, local per machine), then `mise install` on the list. On Ubuntu the `mise` specs of `packages.tools` entries without an `apt` key are added to the list. A tool already there keeps its pinned version. topgrade's mise step (`mise upgrade`) updates them.

> [!NOTE]
> On Arch, AUR packages need `yay` or `paru`. The package script bootstraps `yay` when neither exists; only when that is impossible (running as root with no repo shipping yay) does it print a warning listing the skipped AUR packages and continue.

## aliases.yaml

The single source for aliases shared across shells. Each entry has a `section` and a list of `{ name, cmd }` items.

### Editors / file managers

| Alias | Command |
| --- | --- |
| `e` | `nvim` |
| `e.d` | `cd ~/.config/dotstate/storage/Rogz/.config && yazi` |
| `e.f` | `cd ~/.config/fish && yazi` |
| `e.k` | `yazi ~/.config/kitty` |
| `e.v` | `yazi ~/.config/nvim/lua` |
| `e.y` | `yazi ~/.config/yazi` |
| `e.t` | `nvim ~/.config/tmux/tmux.conf` |
| `hx` | `helix` |

### Quick directory jumps

| Alias | Command |
| --- | --- |
| `cdc` | `cd ~/.config && yazi` |
| `cdd` | `cd ~/Developer && yazi` |
| `cdk` | `cd ~/Documents/Knowledge && obsidian` |
| `cdl` | `cd ~/.local && yazi` |
| `cds` | `cd ~/.local/share/services && ls` |
| `cdw` | `cd ~/Downloads && yazi` |

### Tools

| Alias | Command |
| --- | --- |
| `dd` | `lazydocker` |
| `gg` | `lazygit` |
| `ff` | `exec fish` |
| `npx` | `bunx` |
| `sm` | `sudo micro` |
| `sd` | `ssh prad@<lan-host>` |
| `oc` | `opencode` |
| `dss` | `dotstate sync` |
| `fabric` | `fabric-ai` |
| `bk` | `bead-kanban` |
| `lc` | `leetcode` |
| `tk` | `task` |

`dd` shadows coreutils `dd` in interactive shells.

## How aliases render

### bash and zsh

`dot_config/shell/aliases.sh.tmpl` renders to `~/.config/shell/aliases.sh`. Because it is a template it is written as a real file, not a symlink; edit the YAML and run `chezmoi apply` to regenerate it.

**dot_config/shell/aliases.sh.tmpl**

```sh
{{- range .aliases }}

# {{ .section }}
{{- range .items }}
alias {{ .name }}='{{ .cmd }}'
{{- end }}
{{- end }}
```

After the generated block the file adds shell-specific pieces that are not in the YAML:

| Name | Definition |
| --- | --- |
| `cpy` / `pst` | `wl-copy` / `wl-paste` when `wl-copy` exists |
| `q` | Function: if `$YAZI_ID` is set and `ya` exists, runs `ya emit quit` so the parent yazi also exits, then `exit` |
| `celar`, `claer` | Typo guards for `clear` |
| `ls` | `eza --icons`, when `eza` is installed |

`~/.bashrc` and `~/.zshrc` source it for interactive shells:

**dot_bashrc**

```sh
[ -f "$HOME/.config/shell/aliases.sh" ] && . "$HOME/.config/shell/aliases.sh"
```

See [bash and zsh](../shell/README.md) for the rest of those files.

### fish

`dot_config/fish/conf.d/20-aliases.fish` is not a template. It is a hand-maintained plain file (symlinked into `~/.config/fish/conf.d/`) whose header says it is generated from the YAML; the YAML header likewise names a `20-aliases.fish.tmpl` that does not exist. The fish file has drifted from `aliases.yaml`:

| Alias | aliases.yaml (bash/zsh) | fish |
| --- | --- | --- |
| `e.d` | `cd ~/.config/dotstate/storage/Rogz/.config && yazi` | not defined |
| `e.f` | `cd ~/.config/fish && yazi` | `cd ~/.local/share/chezmoi/dot_config/fish && yazi` |
| `e.h` | not defined | `cd ~/.local/share/omarchy-desktop/dot_config/hypr && yazi` (the [desktop layer's](https://prad.codes/env/omarchy-desktop) Hyprland config) |
| `e.k` | `yazi ~/.config/kitty` | ✓ |
| `e.y` | `yazi ~/.config/yazi` | ✓ |
| `e.t` | `nvim ~/.config/tmux/tmux.conf` | ✓ |
| `cdd` | `cd ~/Developer && yazi` | not defined |
| `,,` | not defined | `cd ~/.local/share/chezmoi && yazi` |
| `..` | not defined | `cd ..` |

fish-only Bun aliases:

| Alias | Command |
| --- | --- |
| `br` | `bun run` |
| `br.d` | `bun run dev` |
| `br.b` | `bun run build` |
| `br.t` | `bun run test` |
| `bi` | `bun install` |
| `bg` | `bun install -g` (shadows fish's `bg` job-control builtin) |
| `bx` | `bunx` |

Every other YAML alias (`e`, `e.v`, `hx`, `cdc`, `cdk`, `cdl`, `cds`, `cdw`, and the whole Tools section) is defined identically in fish. The file ends with the same extras as the sh version: `cpy`/`pst` clipboard detection, the `q` function, and, in interactive sessions only, `celar`/`claer` and `ls` → `eza --icons`. `clear` itself is an autoloaded function (`functions/clear.fish`), which is why it is not aliased. See [fish](../shell/fish.md).

> [!TIP]
> To add an alias for every shell, add it to `aliases.yaml` for bash/zsh and to `20-aliases.fish` by hand for fish.

## skills.yaml

Declares where agent skills come from. `skills.cli` is the pinned CLI (`skills@1.7.0`, run with `npx -y`), `skills.agents` the install targets (`[universal, claude-code]`), and `skills.source` the single source, `prdlk/skills`: every skill in it is installed and skills from any other source are removed. See the [Skills](../ai/skills.md) page.
