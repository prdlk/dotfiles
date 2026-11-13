# Installation

Install chezmoi and apply these dotfiles with one command on Arch, macOS or Ubuntu.

## Before you run it

1. **Prerequisites per OS**

   | OS | Needs |
   | --- | --- |
   | Arch / [Omarchy](https://omarchy.org) | `sudo` for pacman. Omarchy provides `yay` and a working AUR setup; on plain Arch the package script bootstraps `yay`. |
   | macOS | `curl`. The package script installs Homebrew, which brings the Xcode command line tools. |
   | Ubuntu (24.04) | `sudo`, `curl`, `git`. |

   On Omarchy the desktop layer (Hyprland config, Waybar, uwsm, the `omarchy-*` scripts) is a second chezmoi source, [env/omarchy-desktop](https://prad.codes/env/omarchy-desktop), applied automatically after these dotfiles. It layers on top of the Omarchy install and does not replace it. See [Omarchy desktop layer](#omarchy-desktop-layer).

2. **age key**

   chezmoi is configured for age encryption with the identity at `~/.config/chezmoi/key.txt`. The key is never committed. Copy it from an existing machine before applying:

   ```sh
   mkdir -p ~/.config/chezmoi
   scp <existing-machine>:.config/chezmoi/key.txt ~/.config/chezmoi/key.txt
   chmod 600 ~/.config/chezmoi/key.txt
   ```

3. **GitHub credentials (all OSes)**

   Several GitHub repos this setup pulls are private: the prdlk/kitty, ghostty, television, yazi and omp externals (cloned on the first apply). On Omarchy the desktop layer adds prdlk/hypr (submodule) and prdlk/omarchy. prdlk/nvim and prdlk/herdr are public. An unauthenticated clone fails with `could not read Username for https://github.com`. Before the one-liner, install `gh` and run `gh auth login` (it sets up git's HTTPS credential helper), or configure another credential helper or a token.

4. **Repository access**

   [env/omarchy](https://prad.codes/env/omarchy) is a public repository on the prad.codes Gitea, so its HTTPS clone needs no credentials. Use the SSH remote (`git@prad.codes:env/omarchy.git`) if you plan to push.

## One-liner

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://prad.codes/env/omarchy.git
```

This is chezmoi's official install script. It installs chezmoi to `./bin` (run it from `~` or pass `-b ~/.local/bin`), clones the repo into `~/.local/share/chezmoi`, and runs `chezmoi apply`.

## Options

Arguments after `--` go to chezmoi:

**SSH**

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply git@prad.codes:env/omarchy.git
```

**Dry run**

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init https://prad.codes/env/omarchy.git
chezmoi diff
chezmoi apply
```

**chezmoi only**

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin --version
```

| Flag | Effect |
| --- | --- |
| `-b <dir>` | Install directory (default `./bin`) |
| `-t <tag>` | chezmoi release tag (default `latest`) |
| `-d` | Debug logging |

## What differs per OS

There are no machine roles. The OS decides, through the [`os-family` template](chezmoi/config.md#os-family): `arch` for Arch and anything with `ID_LIKE=arch` (Omarchy), `debian` for Ubuntu and Debian, `darwin` for macOS.

| | Arch / Omarchy | macOS | Ubuntu |
| --- | --- | --- | --- |
| System packages | pacman, plus AUR through `yay`/`paru` | Homebrew formulae and casks | apt |
| Package source in `packages.tools` | `arch`, `aur` | `brew`, `cask` | `apt`, else `mise` |
| Package manager bootstrap | `yay` if no AUR helper | Homebrew | mise (`mise.run`), the fish PPA and the tailscale repo |
| Victor Mono Nerd Font | `ttf-victor-mono-nerd` package | `font-victor-mono-nerd-font` cask | Downloaded into `~/.local/share/fonts/VictorMonoNerdFont` |
| Font cache | `fc-cache` | n/a | `fc-cache` |
| Omarchy desktop layer | Applied when `omarchy` is on `PATH` | Not applied | Not applied |

Known gaps: no ghostty on Ubuntu 24.04; `sshfs` is not installed on macOS (it needs macFUSE); macOS gets the docker CLI only, no daemon; `mdcp` and the `cpy`/`pst` aliases use `wl-copy`/`wl-paste` (Wayland); lazygit's link opener is Omarchy-specific.

## First apply

1. **Prompts**

   `.chezmoi.toml.tmpl` asks once for **name** and **email**. Answers are stored in `~/.config/chezmoi/chezmoi.toml` and not asked again. See [Configuration](chezmoi/config.md).

2. **Packages**

   `run_onchange_before_10-packages` installs the `packages.tools` entries of `.chezmoidata/packages.yaml` with the OS package manager (pacman and yay, Homebrew, or apt) before any file is written. See [Scripts](chezmoi/scripts.md).

3. **Files and externals**

   Configs are linked into `$HOME` (symlink mode). The neovim config and the kitty, ghostty, television, yazi, herdr and omp configs are cloned as externals. Where something already sits at one of those paths (Omarchy ships its own `~/.config/kitty`, for example), `run_before_05-externals` asks whether to replace it (the old copy is kept as `<dir>.bak-<time>`); answering no aborts the apply. See [Externals and ignore rules](chezmoi/externals-and-ignore.md).

4. **Post-apply scripts**

   rustup and cargo crates, mise itself on Ubuntu, the global mise tools (`ghq`, `bun`, `node`, `uv`, `opencode`, `crush`, omp), then gh extensions (from a fish session), skills, the bat cache, the font cache on Linux, yazi plugins, and on Omarchy the desktop layer. tpm arrives earlier as an external.

> [!NOTE]
> The gh extension script skips with a warning until `gh auth login` has run. A skipped run still exits 0, so a plain `chezmoi apply` does not retry it. See [Scripts](chezmoi/scripts.md#20-gh-extensions) for how to re-run it.

## Omarchy desktop layer

The Omarchy overrides live in [env/omarchy-desktop](https://prad.codes/env/omarchy-desktop), a separate chezmoi source at `~/.local/share/omarchy-desktop`. `~/.local/bin/chezmoi-desktop` runs chezmoi against it with its own config and state:

```sh
chezmoi --source ~/.local/share/omarchy-desktop \
         --config ~/.config/chezmoi/omarchy-desktop.toml \
         --persistent-state ~/.config/chezmoi/omarchy-desktop.boltdb
```

Use it like chezmoi: `chezmoi-desktop diff`, `chezmoi-desktop apply`, `chezmoi-desktop cd`.

`run_after_50-omarchy-desktop.sh` runs after every `chezmoi apply` when `omarchy` is on `PATH`. The first time it clones the layer with `chezmoi-desktop init --apply https://prad.codes/env/omarchy-desktop.git`; afterwards it runs `chezmoi-desktop apply`. It never pulls the checkout. Machines without Omarchy skip it. See the [desktop layer's README](https://prad.codes/env/omarchy-desktop/src/branch/main/README.md) and [docs](https://prad.codes/env/omarchy-desktop/src/branch/main/docs/README.md).

## Updating

```sh
chezmoi update   # git pull + apply
chezmoi diff     # what apply would change
```

On Omarchy, `chezmoi update` also applies the desktop layer through the 50 script. To pull the layer itself, run `git pull` in `~/.local/share/omarchy-desktop` (or `chezmoi-desktop update`).

