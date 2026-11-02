# Aliases

Every alias and alias-like helper across fish, bash, and zsh, and where each one is defined.

## Single source

`.chezmoidata/aliases.yaml` holds the shell-agnostic aliases as a list of sections, each with `name`/`cmd` items. chezmoi loads the file as template data ([chezmoi data](../chezmoi/data.md)), and `dot_config/shell/aliases.sh.tmpl` ranges over it to produce `~/.config/shell/aliases.sh`, which `~/.bashrc` and `~/.zshrc` source:

**.chezmoidata/aliases.yaml**

```yaml
aliases:
  - section: "Editors / file managers"
    items:
      - { name: "e", cmd: "nvim" }
      # …
```

**~/.config/shell/aliases.sh**

```text
# Editors / file managers
alias e='nvim'
```

To add an alias for bash and zsh, add it to the YAML and run `chezmoi apply`.

> [!NOTE]
> The YAML and template comments say fish renders the same data through `fish/conf.d/20-aliases.fish.tmpl`. That template no longer exists. `dot_config/fish/conf.d/20-aliases.fish` is a plain, hand-maintained fish file, so a YAML change does not reach fish. The fish column below shows where the two sets differ.

## Shared aliases

A ✓ means the alias exists in that shell with the command shown. Where fish uses a different command, the fish command is shown instead.

### Editors / file managers

| Alias | bash / zsh (YAML) | fish (`20-aliases.fish`) |
| --- | --- | --- |
| `e` | `nvim` | ✓ |
| `e.d` | `cd ~/.config/dotstate/storage/Rogz/.config && yazi` | not defined |
| `e.f` | `cd ~/.config/fish && yazi` | `cd ~/.local/share/chezmoi/dot_config/fish && yazi` |
| `e.h` | not defined | `cd ~/.local/share/chezmoi/dot_config/hypr && yazi` |
| `e.k` | `yazi ~/.config/kitty` | ✓ |
| `e.v` | `yazi ~/.config/nvim/lua` | ✓ |
| `e.y` | `yazi ~/.config/yazi` | ✓ |
| `e.t` | `nvim ~/.config/tmux/tmux.conf` | ✓ |
| `hx` | `helix` | ✓ (listed under Tools in fish) |

The fish `e.f`, `e.h`, and `e.k` aliases open the chezmoi source tree directly. In symlink mode, `~/.config/<tool>` files are symlinks into that tree, so both versions edit the same files. yazi and tmux are external checkouts in `~/.config`, so `e.y` and `e.t` open them there.

### Quick directory jumps

| Alias | bash / zsh (YAML) | fish |
| --- | --- | --- |
| `cdc` | `cd ~/.config && yazi` | ✓ |
| `cdd` | `cd ~/Developer && yazi` | not defined |
| `cdk` | `cd ~/Documents/Knowledge && obsidian` | ✓ |
| `cdl` | `cd ~/.local && yazi` | ✓ |
| `cds` | `cd ~/.local/share/services && ls` | ✓ |
| `cdw` | `cd ~/Downloads && yazi` | ✓ |
| `,,` | not defined | `cd ~/.local/share/chezmoi && yazi` |

### Tools

| Alias | Command | fish |
| --- | --- | --- |
| `dd` | `lazydocker` | ✓ |
| `gg` | `lazygit` | ✓ |
| `ff` | `exec fish` | ✓ |
| `npx` | `bunx` | ✓ |
| `sm` | `sudo micro` | ✓ |
| `sd` | `ssh prad@<lan-host>` (a machine on the local network) | ✓ |
| `oc` | `opencode` | ✓ |
| `dss` | `dotstate sync` | ✓ |
| `fabric` | `fabric-ai` | ✓ |
| `bk` | `bead-kanban` | ✓ |
| `lc` | `leetcode` | ✓ |
| `tk` | `task` | ✓ |
| `..` | not defined | `cd ..` |

`dd` shadows coreutils `dd` in interactive shells. Use `command dd` for the real one.

## fish-only aliases

### Bun

| Alias | Command |
| --- | --- |
| `br` | `bun run` |
| `br.d` | `bun run dev` |
| `br.b` | `bun run build` |
| `br.t` | `bun run test` |
| `bi` | `bun install` |
| `bg` | `bun install -g` |
| `bx` | `bunx` |

`bg` replaces fish's job-control builtin. Use `builtin bg` to resume a background job.

## Shell-specific extras

All three shells define these outside the YAML: in `20-aliases.fish` for fish, and in the tail of `aliases.sh.tmpl` for bash and zsh.

| Name | Kind | Definition |
| --- | --- | --- |
| `cpy` | alias | `wl-copy` if available |
| `pst` | alias | `wl-paste` if available |
| `q` | function | `exit`. Runs `ya emit quit` first when `$YAZI_ID` is set, so the parent yazi also quits |
| `celar`, `claer` | alias | `clear` (interactive only) |
| `ls` | alias | `eza --icons` when eza is installed (interactive only) |

## Abbreviations

No fish `abbr` definitions are committed. Abbreviations live in `fish_variables`, which chezmoi ignores.

## Related helpers

The following are functions or scripts, not aliases, and are documented elsewhere:

- `c`, `cd`, `y`/`yy`, `clip-last`, `ghg`, `ghn`, `gho`: per-shell functions ([fish](fish.md#functions), [bash and zsh](bash-zsh.md#per-shell-functions)).
- `pnpmf`, `pnpmfd`, `pnpmfr`, `pnpmfw`, `pnpmfx`: fish workspace helpers ([fish](fish.md#pnpm-filterfish)).
- `ai`, `pj`, `gop`, `fab`, `gdc`, and the other `~/.local/bin` tools: [Scripts](scripts.md).
