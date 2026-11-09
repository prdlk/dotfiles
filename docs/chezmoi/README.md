# How it works

Source layout, naming conventions, symlink mode, and the day-to-day chezmoi workflow for this repo.

The repo is a [chezmoi](https://chezmoi.io) source directory. It lives at `~/Code/prad.codes/env/omarchy` and chezmoi uses it as its source, either through `chezmoi init --source ~/Code/prad.codes/env/omarchy` or by cloning it into `~/.local/share/chezmoi`; both are the same checkout model chezmoi expects. Its remote is [env/omarchy](https://prad.codes/env/omarchy) (branch `main`). `chezmoi apply` renders it into `$HOME`. The [Installation](../installation.md) page covers first-time setup.

## Pages in this section

| Page | Covers |
| --- | --- |
| [Config and roles](config.md) | `.chezmoi.toml.tmpl`: prompts, machine role, symlink mode, age encryption, template data |
| [Packages and aliases](data.md) | `.chezmoidata/packages.yaml` and `.chezmoidata/aliases.yaml`, and how they render |
| [Apply scripts](scripts.md) | Every `run_*` script: when it runs, what triggers it, what it does per role |
| [Externals and ignore rules](externals-and-ignore.md) | `.chezmoiexternal.toml` git clones and every `.chezmoiignore.tmpl` rule |

## Source layout

```text
.chezmoi.toml.tmpl
.chezmoidata/
  aliases.yaml
  packages.yaml
  skills.yaml
.chezmoiexternal.toml
.chezmoiexternals/
  agent-root.toml
  freellmapi.toml
  ghostty.toml
  herdr.toml
  kitty.toml
  omarchy.toml
  omp.toml
  television.toml
  tmux.toml
  tmux-palette.toml
  yazi.toml
.chezmoiignore.tmpl
.gitmodules
.chezmoiscripts/
  run_before_05-externals.sh.tmpl
  run_onchange_before_10-packages.sh.tmpl
  run_onchange_after_15-tools.sh.tmpl
  run_onchange_after_20-gh-extensions.sh.tmpl
  run_onchange_after_25-skills.sh.tmpl
  run_once_after_30-user-services.sh.tmpl
  run_onchange_after_40-post.sh.tmpl
run_onchange_after_build-bat-cache.sh.tmpl
run_onchange_after_install-yazi-plugins.sh.tmpl
dot_bashrc
dot_zshrc
dot_gitconfig.tmpl
dot_config/
  atuin/
  bash/
  bat/
  drydock/
  fish/
  fontconfig/
  gh/
  gh-dash/
  go/
  herdr-nvim/
  hunk/
  hypr/
  lazydocker/
  lazygit/
  mimeapps.list
  shell/
  starship.toml
  systemd/
  topgrade.toml
  uwsm/
  waybar/
  xdg-terminals.list
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
| `.chezmoi.toml.tmpl` | `~/.config/chezmoi/chezmoi.toml` | Config template rendered by `chezmoi init`. See [Config and roles](config.md). |
| `.chezmoidata/` | — | YAML merged into template data (`.packages`, `.aliases`, `.skills`). See [Packages and aliases](data.md) and [Skills](../ai/skills.md). |
| `.chezmoiexternal.toml` | — | Git repos cloned into `$HOME` (nvim config, a bat syntax, tpm). |
| `.chezmoiexternals/` | — | One external per app or tool: agent-root, freellmapi, ghostty, herdr, kitty, omarchy, omp, television, tmux, tmux-palette, yazi. Mostly plain config repos cloned into `~/.config/<app>`. See [Externals and ignore rules](externals-and-ignore.md#chezmoiexternals). |
| `.gitmodules` | — | `dot_config/hypr` and `dot_config/fish` are git submodules. See [Submodules](externals-and-ignore.md#submodules). |
| `.chezmoiignore.tmpl` | — | Target paths chezmoi skips; gates the Linux desktop layer by role. |
| `.chezmoiscripts/`, root `run_*` | — | Install and housekeeping scripts. See [Apply scripts](scripts.md). |
| `dot_config/` | `~/.config/` | Per-tool config. Documented under [Shell](../shell/README.md), [Terminal](../terminal/README.md), [Tools](../tools/README.md), [Desktop](../desktop/README.md). |
| `dot_local/bin/` | `~/.local/bin/` | 37 standalone scripts shared by every shell, plus the `omarchy-*` helpers. |
| `dot_leetcode/` | `~/.leetcode/` | leetcode CLI workspace state. |
| `docs/`, `AGENTS.md`, `README.md` | — | These docs, the repo agent rules, and the repo README. Listed in `.chezmoiignore.tmpl`, never applied. |

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

- Editing a plain file in `$HOME` (for example `~/.config/waybar/config.jsonc`) edits the matching file in the source tree directly. The change is live and shows up in `git status` of the repo with no `chezmoi add` step.
- Templates are rendered copies. Editing `~/.gitconfig` or `~/.config/shell/aliases.sh` changes only the copy; the next `chezmoi apply` overwrites it. Edit the `.tmpl` source (`chezmoi edit ~/.gitconfig`) instead.
- `private_` and `executable_` targets are real files too. After editing one in place, run `chezmoi re-add <path>` to copy it back into the source.
- Tools that rewrite their own config write through the symlink into the repo. The runtime state that would otherwise pollute the source (plugin dirs, lock files, `fish_variables`, `__pycache__`) is excluded in `.chezmoiignore.tmpl` and `.gitignore`; see [Externals and ignore rules](externals-and-ignore.md).

> [!NOTE]
> Several fish aliases (`e.f`, `e.h`, `e.k`, `,,`) open the chezmoi source paths directly. Symlink mode makes that equivalent to editing the live config. `e.y` and `e.t` open the yazi and tmux external checkouts in `~/.config`.

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
| `chezmoi init --prompt` | Re-asks name, email, and role and regenerates `~/.config/chezmoi/chezmoi.toml`. |

Commit and push from the source directory with plain git; the remote pushes over SSH (`git@prad.codes:env/omarchy.git`).
