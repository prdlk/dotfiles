# How it works

Source layout, naming conventions, symlink mode, and the day-to-day chezmoi workflow for this repo.

The repo is a [chezmoi](https://chezmoi.io) source directory at `~/.local/share/chezmoi`, chezmoi's default source directory. Its remote is [prdlk/dotfiles](https://github.com/prdlk/dotfiles) (branch `main`). `chezmoi apply` renders it into `$HOME`. The [Installation](../installation.md) page covers first-time setup.

## Pages in this section

| Page | Covers |
| --- | --- |
| [Config and OS family](config.md) | `.chezmoi.toml.tmpl`: prompts, the os-family template, symlink mode, age encryption, template data |
| [Packages and aliases](data.md) | `.chezmoidata/packages.yaml` (the `packages.tools` schema and per-OS table) and `.chezmoidata/aliases.yaml`, and how they render |
| [Apply scripts](scripts.md) | Every `run_*` script: when it runs, what triggers it, what it does per OS |
| [Externals and ignore rules](externals-and-ignore.md) | `.chezmoiexternal.toml` git clones and every `.chezmoiignore.tmpl` rule |

## Source layout

```text
.chezmoi.toml.tmpl
.chezmoitemplates/
  os-family
.chezmoidata/
  aliases.yaml
  packages.yaml
  skills.yaml
.chezmoiexternal.toml
.chezmoiexternals/
  herdr.toml
  kitty.toml
  omp.toml
  television.toml
  yazi.toml
.chezmoiignore.tmpl
.chezmoiscripts/
  run_before_05-externals.sh.tmpl
  run_onchange_before_10-packages.sh.tmpl
  run_onchange_after_15-tools.sh.tmpl
  run_onchange_after_20-gh-extensions.sh.tmpl
  run_onchange_after_25-skills.sh.tmpl
  run_onchange_after_40-post.sh.tmpl
  run_after_50-omarchy-desktop.sh
run_onchange_after_build-bat-cache.sh.tmpl
run_onchange_after_install-yazi-plugins.sh.tmpl
dot_bashrc
dot_zshrc
dot_gitconfig.tmpl
private_dot_ssh/
dot_config/
  atuin/
  bash/
  bat/
  drydock/
  fish/
  gh/
  gh-dash/
  go/
  herdr-nvim/
  hunk/
  lazydocker/
  lazygit/
  shell/
  starship.toml
  tmux/
  tmux-palette/
  topgrade.toml
  workmux/
  worktrunk/
  yazi.toml.tmpl
  zsh/
dot_local/
  bin/
dot_leetcode/
docs/
AGENTS.md
README.md
```

| Path | Target | Purpose |
| --- | --- | --- |
| `.chezmoi.toml.tmpl` | `~/.config/chezmoi/chezmoi.toml` | Config template rendered by `chezmoi init`. See [Config and OS family](config.md). |
| `.chezmoitemplates/os-family` | — | Renders `arch`, `debian` or `darwin`; scripts use it to pick the package manager. See [os-family](config.md#os-family). |
| `.chezmoidata/` | — | YAML merged into template data (`.packages`, `.aliases`, `.skills`). See [Packages and aliases](data.md) and [Skills](../ai/skills.md). |
| `.chezmoiexternal.toml` | — | Git repos cloned into `$HOME` (nvim config, a bat syntax, tpm). |
| `.chezmoiexternals/` | — | One external per app or tool: herdr, kitty, omp, television, yazi. Plain config repos cloned into `~/.config/<app>`. See [Externals and ignore rules](externals-and-ignore.md#chezmoiexternals). |
| `.chezmoiignore.tmpl` | — | Target paths chezmoi skips: repo docs, runtime state, mise config. The same on every OS. |
| `.chezmoiscripts/`, root `run_*` | — | Install and housekeeping scripts. See [Apply scripts](scripts.md). |
| `dot_config/` | `~/.config/` | Per-tool config, including Ghostty, tmux and tmux-palette as local files. Documented under [Shell](../shell/README.md), [Terminal](../terminal/README.md), [Tools](../tools/README.md). |
| `dot_local/bin/` | `~/.local/bin/` | 26 standalone scripts shared by every shell, including `chezmoi-desktop`. |
| `dot_leetcode/` | `~/.leetcode/` | leetcode CLI workspace state. |
| `docs/`, `AGENTS.md`, `README.md` | — | These docs, the repo agent rules, and the repo README. Listed in `.chezmoiignore.tmpl`, never applied. |

The Omarchy desktop layer (Hyprland, Waybar, uwsm, vicinae, fontconfig, default apps, systemd user units, `omarchy-*` scripts) is not in this tree. It is the second chezmoi source [env/omarchy-desktop](https://prad.codes/env/omarchy-desktop), applied through `chezmoi-desktop`; see [50-omarchy-desktop](scripts.md#50-omarchy-desktop).

Entries whose source name starts with `.` (`.claude/`, `.gitignore`) are ignored by chezmoi automatically and stay repo-only.

## Naming conventions

chezmoi encodes target names and attributes in source file names. These are the prefixes and suffixes the repo uses:

| Source form | Meaning | Examples here |
| --- | --- | --- |
| `dot_` | Target name starts with `.` | `dot_config` → `~/.config`, `dot_zshrc` → `~/.zshrc` |
| `private_` | Target has group/world permissions cleared (`0600`/`0700`) | `dot_config/atuin/private_config.toml`, `dot_config/gh/private_config.yml`, `dot_config/hunk/private_state.json` |
| `executable_` | Target gets the executable bit | Every script in `dot_local/bin/` |
| `empty_` | File is kept even when empty | None currently |
| `symlink_` | Target is a symlink; file content is the link destination | None currently |
| `.tmpl` | Rendered with Go templates and chezmoi data | `dot_gitconfig.tmpl`, `dot_config/shell/aliases.sh.tmpl`, all scripts, the config and ignore files |
| `run_once_` / `run_onchange_` + `before_` / `after_` | Script, with run frequency and phase | See [Apply scripts](scripts.md) |

Prefixes stack in chezmoi's fixed order, e.g. `private_dot_foo`, `executable_dot_bar`. No source file currently uses `encrypted_`, even though age encryption is configured.

## Symlink mode

`.chezmoi.toml.tmpl` sets `mode = "symlink"`. `chezmoi apply` then makes each managed dotfile a symlink into the source tree instead of a copy, as long as the file is a plain regular file. Files that are templates, `private_`, `executable_`, or encrypted are still written as real files.

What that means in practice:

- Editing a plain file in `$HOME` (for example `~/.config/tmux/tmux.conf`) edits the matching file in the source tree directly. The change is live and shows up in `git status` of the repo with no `chezmoi add` step.
- Templates are rendered copies. Editing `~/.gitconfig` or `~/.config/shell/aliases.sh` changes only the copy; the next `chezmoi apply` overwrites it. Edit the `.tmpl` source (`chezmoi edit ~/.gitconfig`) instead.
- `private_` and `executable_` targets are real files too. After editing one in place, run `chezmoi re-add <path>` to copy it back into the source.
- Tools that rewrite their own config write through the symlink into the repo. The runtime state that would otherwise pollute the source (plugin dirs, lock files, `fish_variables`, `__pycache__`) is excluded in `.chezmoiignore.tmpl` and `.gitignore`; see [Externals and ignore rules](externals-and-ignore.md).

> [!NOTE]
> Several fish aliases (`e.f`, `e.k`, `,,`) open the chezmoi source paths directly, and `e.h` opens the desktop layer's Hyprland config in `~/.local/share/omarchy-desktop`. Symlink mode makes that equivalent to editing the live config. `e.y` opens the yazi external checkout in `~/.config`; `e.t` edits `~/.config/tmux/tmux.conf`, which is a symlink into this repo.

## Daily workflow

| Command | What it does here |
| --- | --- |
| `chezmoi apply` | Runs `before_` scripts (package install), writes symlinks/files/templates into `$HOME`, clones missing externals, then runs `after_` scripts. |
| `chezmoi update` | `git pull` in the source directory, then `apply`. |
| `chezmoi diff` | Shows what `apply` would change, including rendered templates and scripts that would run. |
| `chezmoi add <path>` | Moves a new file into the source tree under the right name. In symlink mode the target becomes a symlink on the next apply. Use `--template` or `--encrypt` for templated or secret files. |
| `chezmoi re-add <path>` | Copies edits made to non-symlinked targets (private, executable) back into the source. |
| `chezmoi edit <path>` | Opens the source file for a target, the right way to change templates. |
| `chezmoi cd` | Opens a shell in the source directory for git work. The fish alias `,,` opens yazi there instead. |
| `chezmoi init --prompt` | Re-asks name and email and regenerates `~/.config/chezmoi/chezmoi.toml`. |

Commit and push from the source directory with plain git; the remote is [prdlk/dotfiles](https://github.com/prdlk/dotfiles) (`git@github.com:prdlk/dotfiles.git` over SSH). On Omarchy, `chezmoi-desktop` (diff, apply, cd) does the same for the [desktop layer](https://prad.codes/env/omarchy-desktop).
