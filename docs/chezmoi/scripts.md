# Apply scripts

Every run_ script chezmoi executes during apply, when each one fires, and what it does on each OS and role.

Seven scripts run during `chezmoi apply`. Five live in `.chezmoiscripts/`, a directory whose scripts run as if they sat at the source root without creating a matching target directory. Two sit at the repo root. All seven are templates; `20-gh-extensions` is a fish script, the rest use `#!/bin/sh` with `set -eu` (except `25-skills`, which uses `set -u`).

## Execution order

`before_` scripts run before any file is written; `after_` scripts run after every file, symlink, and external is in place. Within a phase chezmoi runs scripts in ASCII order of their target names, so the numeric prefixes come first.

1. **10-packages (before, onchange)**

   Install system packages from `packages.yaml`.

2. **Files, symlinks, externals**

   chezmoi writes the target state.

3. **15-tools (after, onchange)**

   rustup and cargo crates, omp, global mise tools, strata on Linux desktops.

4. **20-gh-extensions (after, onchange)**

   Install gh extensions from a fish session.

5. **25-skills (after, onchange)**

   Install and prune agent skills.

6. **30-user-services (after, once)**

   Enable systemd user units (kitty-day-save, projects-sync.timer).

7. **40-post (after, onchange)**

   bat cache, font cache.

8. **build-bat-cache (after, onchange)**

   Rebuild bat cache when its theme or config changes.

9. **install-yazi-plugins (after, onchange)**

   Reinstall yazi plugins when the manifest changes.

| Script | Phase | Frequency | Re-run trigger |
| --- | --- | --- | --- |
| `.chezmoiscripts/run_onchange_before_10-packages.sh.tmpl` | before | onchange | sha256 of `.chezmoidata/packages.yaml`; also the role and OS, which change the rendered package list |
| `.chezmoiscripts/run_onchange_after_15-tools.sh.tmpl` | after | onchange | sha256 of `packages.shared.cargo` and `packages.shared.mise` as JSON; also the OS and role, which add the strata step |
| `.chezmoiscripts/run_onchange_after_20-gh-extensions.sh.tmpl` | after | onchange | sha256 of `packages.shared.gh_extensions` as JSON |
| `.chezmoiscripts/run_onchange_after_25-skills.sh.tmpl` | after | onchange | sha256 of `.skills` as JSON |
| `.chezmoiscripts/run_once_after_30-user-services.sh.tmpl` | after | once | Runs once per distinct rendered content |
| `.chezmoiscripts/run_onchange_after_40-post.sh.tmpl` | after | onchange | Edits to the script itself or an OS change |
| `run_onchange_after_build-bat-cache.sh.tmpl` | after | onchange | sha256 of `dot_config/bat/themes/cyberdream.tmTheme` and `dot_config/bat/config` |
| `run_onchange_after_install-yazi-plugins.sh.tmpl` | after | onchange | sha256 of `~/.config/yazi/package.toml` (empty when the file is absent) |

`run_onchange_` scripts re-run whenever their rendered content differs from the last successful run. The hash triggers work by writing a checksum of another file into a comment, so editing that file changes the script's content:

```sh
# packages.yaml hash: {{ include ".chezmoidata/packages.yaml" | sha256sum }}
```

`run_once_` scripts run once per unique rendered content and again only if that content changes or the previous run failed.

## 10-packages

`.chezmoiscripts/run_onchange_before_10-packages.sh.tmpl` installs everything in [`packages.yaml`](data.md#packagesyaml). It runs before files are applied so the tools exist when configs land. On a non-Linux OS it renders to just the shebang and does nothing.

### Steps

1. Uses `pacman` directly when running as root, otherwise `sudo pacman`.
2. `pacman -T` filters each list down to names no installed package provides (so `mise-bin` satisfies `mise`, `yazi-git` satisfies `yazi`), then `pacman -S --needed --noconfirm` installs the rest of `packages.arch.pacman`.
3. For roles `desktop` and `laptop`, the same for `packages.arch.desktop.pacman`, and for `packages.arch.desktop.omarchy` when `pacman-conf -l` lists an `omarchy` repo.
4. Builds the AUR list: `packages.arch.desktop.aur` plus `packages.arch.aur` for `desktop`/`laptop`, only `packages.arch.aur` for other roles, then drops every name `pacman -T` says is already provided. Desktop apps already installed from a sync repo (`[omarchy]`) are therefore neither rebuilt nor replaced.
5. If anything is left and neither `yay` nor `paru` is installed, bootstraps `yay`: from a sync repo when `pacman -Si yay` finds one, otherwise by building `yay-bin` from the AUR with `makepkg -si` (installs `git` and `base-devel` first; skipped as root, since makepkg refuses root). Omarchy ships `yay`, so this is normally a no-op.
6. Runs `yay -S --needed --noconfirm` on the remaining names, falling back to `paru`. yay prefers a sync repo over the AUR when both have the name. If no helper could be bootstrapped it prints `warning: no yay/paru and none could be bootstrapped — skipping AUR packages: …` and continues.

## 15-tools

`.chezmoiscripts/run_onchange_after_15-tools.sh.tmpl` installs the tools that do not come from pacman. It prepends `~/.cargo/bin` to `PATH`, since chezmoi's environment can predate the shell config that adds it. Any failing step aborts the script, so chezmoi keeps the old hash and retries on the next apply.

| Step | Condition | Action |
| --- | --- | --- |
| rustup | `cargo` not on `PATH` | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh -s -- -y --no-modify-path`. `-y` because there is no prompt under chezmoi; `--no-modify-path` because the shell rc files are symlinks into this repo and already source `~/.cargo/env` |
| cargo crates | every OS | `cargo install --locked <crate>` for each `packages.shared.cargo` entry missing from `cargo install --list` |
| mise tools | `mise` installed (warning otherwise) | `mise use -g <tools…>` for each `packages.shared.mise` entry absent from `mise ls --global --json`, then `mise install <tools…>`. A tool already in the global config keeps its pinned version. omp and opencode come from here |
| old omp binary | `~/.local/bin/omp` is a regular file and `mise which omp` resolves | Deletes it: a copy from omp's own installer (`omp.sh/install`) sits ahead of mise's shims on `PATH` |
| strata | Linux, roles `desktop`/`laptop`, no `~/.local/bin/strata` | `curl -fsSL https://raw.githubusercontent.com/lgse/strata/main/install.sh \| bash -s -- --with-desktop-entry --with-file-manager` |
| strata file chooser | Linux, roles `desktop`/`laptop`, `~/.local/bin/strata` exists and `~/.local/share/xdg-desktop-portal/portals/strata.portal` does not | `strata --install-portal` |

The strata flags install the binary, `~/.local/share/applications/io.github.lgse.Strata.desktop`, and the `org.freedesktop.FileManager1` D-Bus service in `~/.local/share/dbus-1/services` ("Open file location" from other apps). The folder default (`inode/directory`) comes from the managed `~/.config/mimeapps.list` instead of `--with-folder-association`, because `xdg-mime default` would replace that symlink with a plain file. The installer's own dependency step runs `sudo -n pacman`, which fails without cached credentials, so its runtime packages are declared in `packages.arch.desktop.pacman` and are already present when it runs.

`strata --install-portal` makes strata the system file chooser for portal-aware apps (browsers, GTK file dialogs). It writes `strata.portal` and the `org.freedesktop.impl.portal.desktop.strata` D-Bus service under `~/.local/share`, prepends `strata;` to the `org.freedesktop.impl.portal.FileChooser` line of `~/.config/xdg-desktop-portal/<desktop>-portals.conf` (`hyprland-portals.conf`, copied from `/usr/share/xdg-desktop-portal/` when absent, so the compositor's backends stay as fallbacks), marks the in-app offer answered (`~/.config/strata/portal-opt-in-v1`), and restarts `xdg-desktop-portal.service`. That config file is strata's, not chezmoi's: `strata --uninstall-portal` restores it. Check: `gdbus call --session --dest org.freedesktop.impl.portal.desktop.strata --object-path /org/freedesktop/portal/desktop --method org.freedesktop.DBus.Properties.Get org.freedesktop.impl.portal.FileChooser version` prints `uint32 4`. Apps that draw their own picker instead of calling the portal are unchanged.

## 20-gh-extensions

`.chezmoiscripts/run_onchange_after_20-gh-extensions.sh.tmpl` installs each `packages.shared.gh_extensions` entry. It is a fish script (`#!/usr/bin/env fish`), so fish sources `~/.config/fish` first: `PATH` (mise, `~/.local/bin`, `~/.cargo/bin`) and `GITHUB_TOKEN` (from `gh auth token` in `conf.d/10-env.fish`) are those of a fish session. It runs after every file is applied and after [15-tools](#15-tools), so the fish config and `~/.cargo/env.fish` exist.

- Exits 0 with `warning: gh not installed — skipping extensions` if `gh` is missing.
- Exits 0 with `warning: gh not authenticated — run 'gh auth login', then 'chezmoi apply' again` if `gh auth status` fails.
- Reads `gh extension list`, then runs `gh extension install <repo>` only for extensions not already present.
- Exits 1 listing the failed extensions if any install failed, so the next apply retries.

> [!WARNING]
> A skipped run still exits 0, so chezmoi records this content as done and a plain re-apply does not retry it, despite what the warning text says. After `gh auth login`, either run `gh extension install` for each entry by hand, or clear chezmoi's onchange state with `chezmoi state delete-bucket --bucket=entryState` and apply again (this re-runs every `run_onchange_` script).

## 25-skills

`.chezmoiscripts/run_onchange_after_25-skills.sh.tmpl` installs the agent skills declared in [`skills.yaml`](data.md#skillsyaml) with the Skills CLI (`npx -y skills@1.7.0`). See [Skills](../ai/skills.md).

- Exits 0 with a warning if `npx` is missing.
- One-time migration: deletes any directory in `~/.agents/skills` or `~/.claude/skills` that contains symlinks into the chezmoi source directory (the old vendored layout), and removes `~/.agents/.skill-lock.json` if it is a symlink into the source directory.
- Removes skills listed in `${XDG_STATE_HOME:-~/.local/state}/chezmoi/skills.txt` that are no longer declared, with `skills remove -g -y`.
- Runs one `skills add <source> -g -y -a <agents> --skill <names…>` per source entry. Output is captured; on failure the last 8 lines are printed.
- Writes the declared names to `skills.txt`. Claude-only installs are not in the CLI's lock, so the script keeps its own record.
- Exits 1 if any source failed, so chezmoi keeps the old hash and retries on the next apply.

## 30-user-services

`.chezmoiscripts/run_once_after_30-user-services.sh.tmpl` enables session-critical systemd user units on Linux.

- Same check for `~/.config/systemd/user/kitty-day-save.service` (from `dot_config/systemd/user/`, so Linux desktop/laptop roles only), then `systemctl --user enable --now kitty-day-save.service`. See [kitty-day-save](../shell/scripts.md#kitty-day-save).
- Same check for `~/.config/systemd/user/projects-sync.timer`, then `systemctl --user enable --now projects-sync.timer`. See [projects-sync](../shell/scripts.md#projects-sync).
- On non-Linux systems it renders to `#!/bin/sh` / `exit 0`.

Other personal automation units (brain-lens, omp-loop, rclone, hermes, voxtype) are deliberately not enabled; the script comment says to enable them by hand per machine. Their unit files are not in the repo, so they have to exist on the machine already.

## 40-post

`.chezmoiscripts/run_onchange_after_40-post.sh.tmpl` is post-apply housekeeping. It re-runs when the script is edited.

| Step | Condition | Action |
| --- | --- | --- |
| bat cache | `bat` installed | `bat cache --build` |
| Font cache | Linux, `fc-cache` installed | `fc-cache -f` |

Each step ignores failures (`|| true`). tpm is cloned by [`.chezmoiexternal.toml`](externals-and-ignore.md#chezmoiexternaltoml), not here.

## build-bat-cache

`run_onchange_after_build-bat-cache.sh.tmpl` rebuilds bat's syntax and theme cache when the managed inputs change. It hashes `dot_config/bat/themes/cyberdream.tmTheme` and `dot_config/bat/config`, exits quietly if `bat` is missing, and otherwise runs `bat cache --build`. This registers the cyberdream theme and the PureScript syntax cloned by [`.chezmoiexternal.toml`](externals-and-ignore.md#chezmoiexternaltoml).

## install-yazi-plugins

`run_onchange_after_install-yazi-plugins.sh.tmpl` reinstalls yazi plugins whenever `~/.config/yazi/package.toml` changes (the template hashes it via `joinPath .chezmoi.homeDir`, guarded with `stat`). It exits quietly if `ya` is missing or `${XDG_CONFIG_HOME:-$HOME/.config}/yazi/package.toml` does not exist, and otherwise runs `ya pkg install`. If that fails, it deletes ya's clone cache (`${XDG_CACHE_HOME:-$HOME/.cache}/yazi/packages`), since clones made by an older ya can break a newer one, and retries once. `~/.config/yazi` is the [prdlk/yazi](https://github.com/prdlk/yazi) external checkout, so the plugins land in its `plugins/`, which that repo's `.gitignore` excludes apart from the vendored `bunny.yazi`. The plugin list is on the [yazi page](../tools/yazi.md).
