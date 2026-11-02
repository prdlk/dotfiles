# Starship

The cross-shell prompt — a minimal left prompt, a clock on the right, and a cyberdream palette.

[Starship](https://starship.rs) renders the prompt in fish, bash, and zsh from one config file.

| Source (repo) | Target |
| --- | --- |
| `dot_config/starship.toml` | `~/.config/starship.toml` |

The file is not a template and applies on every role. `starship` is in `.chezmoidata/packages.yaml` for pacman and is installed by `.chezmoiscripts/run_onchange_before_10-packages.sh.tmpl`.

## Shell integration

| Shell | Init |
| --- | --- |
| fish | `conf.d/40-tools.fish` runs `starship init fish`, then `config.fish` runs it again and calls `enable_transience` |
| bash | `eval "$(starship init bash)"` in `~/.bashrc` |
| zsh | `eval "$(starship init zsh)"` in `~/.zshrc`, plus a transient-prompt hook |

With transience in fish, past prompts in the scrollback collapse to the output of `starship_transient_prompt_func` (`starship module character`, the `❯` alone) and `starship_transient_rprompt_func` (`starship module time`). See [fish](fish.md#configfish).

zsh has no built-in transience, so `~/.zshrc` collapses past prompts itself, rendering the `transient` (`$character`) and `transient_right` (`$time`) entries under `[profiles]` with `starship prompt --profile`. It uses profiles rather than `starship module` because only `starship prompt` wraps color escapes in zsh's `%{…%}`; without them zsh miscounts the right prompt's width. zsh also gets starship's default `∙` continuation prompt (`PROMPT2`). See [bash and zsh](bash-zsh.md#zshrc).

## Layout

**~/.config/starship.toml**

```toml
"$schema" = 'https://starship.rs/config-schema.json'
palette = "cyberdream"

format = """
$username\
$hostname\
$directory\
$git_branch\
$git_state\
$git_status\
$cmd_duration\
$python\
$character"""

right_format = """$time"""
```

The left prompt is a single line with no line break before `$character`. Only the nine listed modules can appear; every other starship module is left out of `format`. `$username` and `$hostname` keep their defaults, so they appear only over SSH or as root.

## Modules

| Module | Format | Style | Notes |
| --- | --- | --- | --- |
| `directory` | default | `blue` | |
| `git_branch` | `[$branch]($style)` | `bright-black` | Branch name only, no symbol or "on" |
| `git_state` | `\([$state( $progress_current/$progress_total)]($style)\) ` | `bright-black` | For example `(REBASING 2/5)` |
| `git_status` | `[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style)` | `cyan` | See below |
| `cmd_duration` | `[$duration]($style) ` | `yellow` | Default threshold |
| `python` | `[$virtualenv]($style) ` | `bright-black` | `detect_extensions = []`, `detect_files = []` |
| `time` | `[$time]($style)` | `bright-black` | `disabled = false`, `time_format = '%-I:%M %p'` (for example `3:07 PM`) |
| `character` | default | | Symbols below |

**git_status.** The `conflicted`, `untracked`, `modified`, `staged`, `renamed`, and `deleted` symbols are all set to a zero-width space. Any dirty state therefore shows a single `*` in 256-color `218` (pink) instead of per-state counts. `stashed` is `≡`. `ahead_behind` keeps starship's default arrows and is drawn in `cyan`.

**python.** With both detect lists empty, the module does not trigger on `.py` files or `pyproject.toml`. It shows only the name of an active virtualenv.

### Prompt character

| State | Symbol |
| --- | --- |
| Last command succeeded | `❯` in `purple` |
| Last command failed | `❯` in `red` |
| Vi normal mode (fish) | `❮` in `green` |

fish runs in vi mode ([key bindings](fish.md#key-bindings)), so `vimcmd_symbol` appears there. zsh uses the emacs keymap and never shows it.

## Palette

`palette = "cyberdream"` selects the `[palettes.cyberdream]` table, colors from [cyberdream.nvim](https://github.com/scottmckendry/cyberdream.nvim). Every named color in the module styles resolves through this table.

| Name | Normal | `bright-*` | `dim-*` |
| --- | --- | --- | --- |
| black | `#1e2124` | `#4a4d4f` | `#1c1f22` |
| red | `#ff6e5e` | `#ff8b7e` | `#d05c50` |
| green | `#5eff6c` | `#7eff89` | `#4fd05b` |
| yellow | `#f1ff5e` | `#f3ff7e` | `#c5d050` |
| blue | `#5ea1ff` | `#7eb3ff` | `#4f85d1` |
| purple | `#bd5eff` | `#ff7ef3` | `#d050c6` |
| cyan | `#5ef1ff` | `#7ef3ff` | `#4fc5d1` |
| white | `#ffffff` | `#ffffff` | `#d0d0d1` |

`bright-black` (`#4a4d4f`) is the muted gray used for the branch, git state, virtualenv, and clock. The `dim-*` entries are defined but no module uses them.
