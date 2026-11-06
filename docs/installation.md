# Installation

Install Omarchy, then install chezmoi and apply these dotfiles with one command.

## Before you run it

1. **Omarchy**

   Install [Omarchy](https://omarchy.org) first. It provides Arch Linux, Hyprland, Waybar, the `omarchy-*` commands, the `[omarchy]` pacman repo, and a working AUR helper (`yay`). The desktop layer in this repo (the `dot_config/hypr` submodule, Waybar, `uwsm`, the `omarchy-*` scripts) layers on top of that install and does not replace it.

2. **age key**

   chezmoi is configured for age encryption with the identity at `~/.config/chezmoi/key.txt`. The key is never committed. Copy it from an existing machine before applying:

   ```sh
   mkdir -p ~/.config/chezmoi
   scp <existing-machine>:.config/chezmoi/key.txt ~/.config/chezmoi/key.txt
   chmod 600 ~/.config/chezmoi/key.txt
   ```

3. **Repository access**

   [env/omarchy](https://prad.codes/env/omarchy) is a public repository on the prad.codes Gitea, so the HTTPS clone needs no credentials. The submodules (`dot_config/fish`, `dot_config/hypr`) are cloned by chezmoi on init. Use the SSH remote (`git@prad.codes:env/omarchy.git`) if you plan to push.

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

## Roles

The first apply asks once for a machine role:

| Role | Gets |
| --- | --- |
| `desktop` (default) | Universal toolset plus the Linux desktop layer (Hyprland config, Waybar, `omarchy-*` scripts, fonts, default apps) |
| `laptop` | Same as `desktop` |
| `server` | Universal toolset only; no desktop layer |

See [Configuration](chezmoi/config.md) for how the role is stored and [Ignore rules](chezmoi/externals-and-ignore.md) for what it gates.

## First apply

1. **Prompts**

   `.chezmoi.toml.tmpl` asks once for **name**, **email**, and **role** (`desktop`, `laptop`, `server`). Answers are stored in `~/.config/chezmoi/chezmoi.toml` and not asked again. See [Configuration](chezmoi/config.md).

2. **Packages**

   `run_onchange_before_10-packages` installs everything in `.chezmoidata/packages.yaml` with pacman and yay before any file is written. See [Scripts](chezmoi/scripts.md).

3. **Files and externals**

   Configs are linked into `$HOME` (symlink mode). The neovim config, Omarchy's `~/.config/omarchy` checkout, and the terminal and tool configs are cloned as externals. Where Omarchy already put a directory at one of those paths, `run_before_05-externals` asks whether to replace it (the old copy is kept as `<dir>.bak-<time>`); answering no aborts the apply. See [Externals and ignore rules](chezmoi/externals-and-ignore.md).

4. **Post-apply scripts**

   rustup and cargo crates, the global mise tools (`ghq`, `bun`, `node`, `uv`, `opencode`, `crush`, omp), strata on Linux desktops, then gh extensions (from a fish session), skills, the bat cache, the font cache, yazi plugins, and the systemd user services. tpm arrives earlier as an external.

> [!NOTE]
> The gh extension script skips with a warning until `gh auth login` has run. A skipped run still exits 0, so a plain `chezmoi apply` does not retry it. See [Scripts](chezmoi/scripts.md#20-gh-extensions) for how to re-run it.

## Updating

```sh
chezmoi update   # git pull + apply
chezmoi diff     # what apply would change
```
