# Topgrade

Topgrade config for Omarchy (Arch) machines, with yay as the package manager, chezmoi re-add before upgrades, and post-upgrade hooks.

[Topgrade](https://github.com/topgrade-rs/topgrade) runs every updater on the machine in one pass: system packages, cargo, firmware, git repos, flatpak, and custom commands. The config is written for an Omarchy (Arch) box running fish; most keys are left at topgrade's defaults.

| | |
| --- | --- |
| Source | `dot_config/topgrade.toml` |
| Target | `~/.config/topgrade.toml` |
| Packages | `topgrade` (AUR, via yay) |

> [!NOTE]
> The file's comments say topgrade on the owner's machine is cargo-installed, and that `cargo install-update` keeps it current. That is why self-update is off.

## [misc]

| Key | Value | Why |
| --- | --- | --- |
| `pre_sudo` | `true` | Caches sudo credentials up front so an unattended run does not stop at a password prompt partway through. |
| `no_self_update` | `true` | The `[cargo]` step already updates the topgrade binary; two updaters would fight over it. |
| `cleanup` | `true` | Runs distro cleanup afterwards (paccache needs `pacman-contrib`; skipped if absent). |
| `show_distribution_summary` | `true` | Surfaces `*.pacnew` / `*.pacsave` files to merge. |
| `disable` | `["containers", "config_update"]` | Skips pulling `:latest` for every local container image, and skips topgrade's config-update step. |
| `ignore_failures` | `["uv", "containers"]` | Failures in these steps do not fail the run. |

The Python pip/conda steps stay off (topgrade's default), which protects a pinned ROCm build of torch from blind upgrades. A `remote_topgrades` entry for another host is present but commented out.

## [linux]

| Key | Value | Why |
| --- | --- | --- |
| `arch_package_manager` | `"yay"` | Pins Omarchy's AUR helper so topgrade does not fall back to bare `pacman`, which would skip the AUR. |
| `show_arch_news` | `true` | Prints archlinux.org news before upgrading; Omarchy tracks Arch, so manual-intervention notices still apply. |

## Other steps

| Section | Key | Value | Effect |
| --- | --- | --- | --- |
| `[cargo]` | `git` | `true` | Also updates git-sourced cargo installs, not only crates.io ones. Needs `cargo-update`. |
| `[firmware]` | `upgrade` | `false` | fwupd updates are listed, not flashed, so firmware is reviewed before applying. |
| `[git]` | (none active) | | Predefined repos are still pulled; custom `repos` and `arguments` are commented out to avoid tripping over dirty working trees. |
| `[flatpak]` | (none active) | | User-scope flatpaks update without sudo; `use_sudo` is commented out. |

## Pre- and post-commands

Pre-commands run before any upgrade step:

| Name | Command | Purpose |
| --- | --- | --- |
| Chezmoi Re-Add | `chezmoi re-add` | Pulls local edits to managed dotfiles back into the chezmoi source repo before anything changes them. Only re-adds files chezmoi already manages; review and commit in `~/.local/share/chezmoi` afterwards. |
| GHQ Update | see below | Updates every ghq-managed repo. |

**~/.config/topgrade.toml**

```toml
[pre_commands]
"Chezmoi Re-Add" = "chezmoi re-add"
"GHQ Update" = "ghq list | ghq get -u -s"
```

Post-commands run after everything else:

| Name | Command |
| --- | --- |
| Hermes Update | `hermes update --backup --yes` |
| Herdr Update | `herdr update` |

The post-commands assume the owner's own CLIs (`hermes`, `herdr`); on machines without them those steps fail. omp has no post-command: it is a global mise tool, so topgrade's built-in mise step (`mise upgrade`) updates it, and `omp update` would overwrite the binary inside mise's install directory.

> [!NOTE]
> `chezmoi re-add` does not overwrite templates, so edits made directly to rendered files such as `~/.gitconfig` are not captured; change the `.tmpl` source instead.
