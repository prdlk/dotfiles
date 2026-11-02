# Packages and aliases

The .chezmoidata YAML files that declare every installed package and every shared shell alias, and how they render.

Files in `.chezmoidata/` are merged into chezmoi's template data on every run. Nothing in the directory is written to `$HOME`; the data only reaches the machine through templates and scripts.

| File | Data key | Consumed by |
| --- | --- | --- |
| `.chezmoidata/packages.yaml` | `.packages` | [`run_onchange_before_10-packages.sh.tmpl`](scripts.md#10-packages), [`run_onchange_after_15-tools.sh.tmpl`](scripts.md#15-tools), [`run_onchange_after_20-gh-extensions.sh.tmpl`](scripts.md#20-gh-extensions) |
| `.chezmoidata/aliases.yaml` | `.aliases` | `dot_config/shell/aliases.sh.tmpl` (bash and zsh) |
| `.chezmoidata/skills.yaml` | `.skills` | [`run_onchange_after_25-skills.sh.tmpl`](scripts.md#25-skills) |

## packages.yaml

One manifest for Arch, plus a `shared` block. Any edit to the file changes the hash embedded in the package script, so the next `chezmoi apply` re-runs the install. Installs are idempotent (`pacman --needed`, `yay`/`paru --needed`). The lists are derived from what the configs actually invoke: tmux-palette items, television cable `requirements`, fish functions, `~/.local/bin` scripts, and compositor bindings.

### Arch

`packages.arch.pacman`, installed on every Linux machine with `pacman -S --needed --noconfirm`:

| Group | Packages |
| --- | --- |
| Shell and editors | `fish`, `neovim`, `helix`, `micro`, `tmux` |
| Terminals | `ghostty` (default), `kitty` |
| TUI tools (tmux-palette, television cables) | `yazi`, `lazygit`, `lazydocker`, `docker`, `docker-compose`, `btop`, `fastfetch`, `onefetch`, `television`, `serie`, `tig`, `gitui`, `tldr`, `navi`, `mdfried` |
| VCS and forge | `git`, `github-cli`, `git-delta`, `diffnav`, `tea` |
| Search and files | `fzf`, `fd`, `ripgrep`, `zoxide`, `eza`, `bat`, `jq`, `duf` |
| Media and preview (yazi and tv deps) | `ffmpeg`, `ffmpegthumbnailer`, `poppler`, `resvg`, `imagemagick`, `chafa`, `7zip`, `unzip` |
| Remote | `mosh`, `sshfs`, `tailscale` |
| Misc CLI | `mise`, `gum`, `glow`, `atuin`, `wget`, `starship`, `zsh-syntax-highlighting` |
| Fonts | `ttf-victor-mono-nerd` |

`packages.arch.aur`, installed with `yay -S --needed --noconfirm` (or `paru`) on every Linux machine: `topgrade`, `portop`. Names some installed package already provides are skipped, and yay is bootstrapped when no helper exists ([10-packages](scripts.md#10-packages)).

`packages.arch.desktop`, added only for roles `desktop` and `laptop`:

| Source | Packages |
| --- | --- |
| pacman | `uwsm`, `xdg-user-dirs`; Wayland utilities `wl-clipboard`, `cliphist`, `wtype`, `ydotool`, `grim`, `slurp`, `hyprpicker`, `pamixer`, `brightnessctl`, `libnotify`; apps `nautilus`, `imv`, `mpv`, `evince`, `chromium`, `obsidian`; strata runtime deps `bubblewrap`, `desktop-file-utils`, `fontconfig`, `gstreamer`, `gst-libav`, `gst-plugins-base`, `gst-plugins-good`, `gtk4`, `gtksourceview5`, `gvfs`, `poppler-glib`, `xdg-utils` |
| AUR (or a sync repo with the same name) | `tldraw-offline-bin`; desktop apps `beeper-bin`, `fastmail`, `1password`, `brave-origin-bin`, `claude-desktop`, `spotify` |
| `[omarchy]` repo (`packages.arch.desktop.omarchy`, only when `pacman-conf -l` lists that repo) | `herdr`, `flea`, `voxtype-bin`, `xdg-terminal-exec`, `hyprland-preview-share-picker` |

Hyprland, Waybar and the `omarchy-*` commands come with the Omarchy install and are not declared. strata (the folder handler) has no package; [15-tools](scripts.md#15-tools) runs its installer.

### Shared

`packages.shared.gh_extensions`, installed by the gh-extensions script:

| Extension | Purpose |
| --- | --- |
| `davidraviv/gh-clean-branches` | `gh clean-branches`: delete local branches whose upstream is gone |
| `prdlk/gh-commit` | `gh commit` |
| `dlvhdr/gh-dash` | `gh dash`: PR and issue dashboard |
| `meiji163/gh-notify` | `gh notify`: notifications in the terminal |

`packages.shared.cargo` lists `suvadu`, `mandible` (the tmux-palette "mandible" item runs `~/.local/bin/mandible-pick`), and `worktrunk` (`wt`, git worktree management for parallel agent work). [`run_onchange_after_15-tools.sh.tmpl`](scripts.md#15-tools) installs rustup when `cargo` is missing, then any crate `cargo install --list` lacks.

`packages.shared.mise` lists the global mise tools: `ghq`, `bun`, `node`, `uv`, `opencode`, `crush`, and omp as `github:can1357/oh-my-pi` (omp is not in the mise registry, so it uses the GitHub-releases backend, which installs the release binary as `omp`). The same script runs `mise use -g` for each one not yet in the global config (`~/.config/mise/config.toml`, local per machine), then `mise install` on the list. A tool already there keeps its pinned version. topgrade's mise step (`mise upgrade`) updates them.

> [!NOTE]
> AUR packages need `yay` or `paru`. The package script bootstraps `yay` when neither exists; only when that is impossible (running as root with no repo shipping yay) does it print a warning listing the skipped AUR packages and continue.

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
| `e.h` | not defined | `cd ~/.local/share/chezmoi/dot_config/hypr && yazi` |
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

Declares the agent skills installed by the Skills CLI. `skills.cli` is the pinned CLI (`skills@1.7.0`, run with `npx -y`), `skills.agents` the default install targets (`[universal, claude-code]`), and `skills.sources` a list of `{ source, skills, agents? }` entries: 110 skills across 42 entries. The full list, pinned sources, and add/remove workflow are on the [Skills](../ai/skills.md) page.
