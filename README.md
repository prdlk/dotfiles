# omarchy

chezmoi source for a cross-platform developer environment (shells, editors, terminals, tmux, TUI tools, agent tooling) on Arch, macOS and Ubuntu, hosted at <https://prad.codes/env/omarchy>.

On an [Omarchy](https://omarchy.org) machine (Arch + Hyprland) the desktop layer from [env/omarchy-desktop](https://prad.codes/env/omarchy-desktop) is applied automatically after the dotfiles.

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://prad.codes/env/omarchy.git
# or over SSH:
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@prad.codes:env/omarchy.git
```

First apply prompts once for name and email. There are no machine roles: what differs per machine is decided by the OS.

| | Arch / Omarchy | macOS | Ubuntu |
| --- | --- | --- | --- |
| System packages | pacman + AUR (`yay`/`paru`, `yay` bootstrapped) | Homebrew (installed if missing): formulae and casks | apt, with the fish PPA and the tailscale repo |
| Tools missing from apt | n/a | n/a | mise (installed from `mise.run`) |
| Victor Mono Nerd Font | `ttf-victor-mono-nerd` | `font-victor-mono-nerd-font` cask | downloaded into `~/.local/share/fonts` |
| Desktop layer | Applied when `omarchy` is on `PATH` | None | None |

## Prerequisites

- **Arch / Omarchy**: `sudo` for pacman. Omarchy provides `yay`; on plain Arch the install script bootstraps it.
- **GitHub credentials (all OSes)**: the prdlk/kitty, ghostty, television, yazi and omp externals are private (on Omarchy, also prdlk/hypr and prdlk/omarchy in the desktop layer; prdlk/nvim and prdlk/herdr are public). Without credentials the first apply fails with `could not read Username for https://github.com`. Before the one-liner, install `gh` and run `gh auth login` (it configures git's credential helper), or set up another credential helper or token.
- **macOS**: `curl`. The package script installs Homebrew, which brings the Xcode command line tools.
- **Ubuntu**: `sudo`, `curl` and `git`.
- **Secrets**: `age`-encrypted files need the key at
  `~/.config/chezmoi/key.txt`. Copy it there **before** `chezmoi apply`
  (distributed manually, never committed):

  ```sh
  mkdir -p ~/.config/chezmoi
  scp <existing-machine>:.config/chezmoi/key.txt ~/.config/chezmoi/key.txt
  chmod 600 ~/.config/chezmoi/key.txt
  ```

## What's managed

fish, bash + zsh (starship prompt, shared aliases), nvim, tmux (+ tmux-palette),
kitty, ghostty, yazi, lazygit, lazydocker, gh (+ extensions), topgrade, git,
ssh config, Claude Code and agent skills.
Packages are declared in `.chezmoidata/packages.yaml` and installed by
`.chezmoiscripts` (idempotent, re-run when the manifest changes).

Aliases are defined once in `.chezmoidata/aliases.yaml` and rendered
into fish (`fish/conf.d/20-aliases.fish`) and bash/zsh
(`~/.config/shell/aliases.sh`, sourced by `.bashrc`/`.zshrc`).

Shell utilities live as standalone sh/bash executables in `~/.local/bin`
so all shells share one implementation; helpers that must mutate shell state
(`cd`-style) are per-shell functions in `fish/functions/`, `bash/functions/`,
and `zsh/functions/`.

Agent skills are not vendored: they all come from
[prdlk/skills](https://github.com/prdlk/skills), and
`.chezmoiscripts/run_onchange_after_25-skills.sh.tmpl` installs every skill in
it with the Skills CLI (removing skills from any other source) whenever
`.chezmoidata/skills.yaml` changes.

## Omarchy desktop layer

Hyprland, Waybar, uwsm, vicinae, fontconfig, default apps, systemd user units, the `omarchy-*` scripts and `~/.config/omarchy` live in a second chezmoi source,
[env/omarchy-desktop](https://prad.codes/env/omarchy-desktop), checked out at `~/.local/share/omarchy-desktop`.
It has its own config and state, so the two never share chezmoi state. `~/.local/bin/chezmoi-desktop` is chezmoi pointed at it:

```sh
chezmoi-desktop diff     # same arguments as chezmoi
chezmoi-desktop apply
chezmoi-desktop cd
```

`.chezmoiscripts/run_after_50-omarchy-desktop.sh` runs after every apply when `omarchy` is on `PATH`: the first time it runs `chezmoi-desktop init --apply https://prad.codes/env/omarchy-desktop.git`, afterwards `chezmoi-desktop apply`. It never pulls the checkout; commit and push there as in this repo. On macOS, Ubuntu and Arch without Omarchy it does nothing. Docs: [Hyprland](https://prad.codes/env/omarchy-desktop/src/branch/main/docs/hyprland.md), [Waybar](https://prad.codes/env/omarchy-desktop/src/branch/main/docs/waybar.md), [fonts and apps](https://prad.codes/env/omarchy-desktop/src/branch/main/docs/fonts-and-apps.md), [free-router](https://prad.codes/env/omarchy-desktop/src/branch/main/docs/free-router.md), [scripts](https://prad.codes/env/omarchy-desktop/src/branch/main/docs/scripts.md).

## Externals

- Externals (`.chezmoiexternals/`): kitty, ghostty, television, yazi, herdr, omp,
  plus nvim, tpm and a bat syntax in `.chezmoiexternal.toml`. Every one pulls with `--ff-only --no-rebase`.
- tmux (`dot_config/tmux`) and tmux-palette (`dot_config/tmux-palette`) are plain files in this repo.

`gh` needs `gh auth login` once per machine; the extension install script
skips gracefully until then and re-runs on the next apply.

## Known OS gaps

- No ghostty package on Ubuntu 24.04.
- `sshfs` is not installed on macOS (it needs macFUSE).
- macOS gets the docker CLI only, no daemon (Docker Desktop, colima or OrbStack).
- `mdcp` and the `cpy`/`pst` aliases use `wl-copy`/`wl-paste` (Wayland).
- lazygit's link opener is Omarchy-specific.

## Docs

See [`docs/README.md`](docs/README.md). Agent rules for working in this repo: [`AGENTS.md`](AGENTS.md).
