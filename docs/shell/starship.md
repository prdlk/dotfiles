# Starship

The cross-shell prompt: a minimal left prompt, a clock on the right, and ANSI colors that follow the terminal (and so the active Omarchy theme).

[Starship](https://starship.rs) renders the prompt in fish, bash, and zsh from one config file.

| Source (repo) | Target |
| --- | --- |
| `dot_config/starship.toml` | `~/.config/starship.toml` |

The file is not a template and applies on every OS. `starship` is in `.chezmoidata/packages.yaml` (pacman, Homebrew, and mise on Ubuntu) and is installed by `.chezmoiscripts/run_onchange_before_10-packages.sh.tmpl` (or `15-tools` on Ubuntu).

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
| `git_status` | `[[(*$conflicted$untracked$modified$staged$renamed$deleted)](red) ($ahead_behind$stashed)]($style)` | `cyan` | See below |
| `cmd_duration` | `[$duration]($style) ` | `yellow` | Default threshold |
| `python` | `[$virtualenv]($style) ` | `bright-black` | `detect_extensions = []`, `detect_files = []` |
| `time` | `[$time]($style)` | `bright-black` | `disabled = false`, `time_format = '%-I:%M %p'` (for example `3:07 PM`) |
| `character` | default | | Symbols below |

**git_status.** The `conflicted`, `untracked`, `modified`, `staged`, `renamed`, and `deleted` symbols are all set to a zero-width space. Any dirty state therefore shows a single `*` in `red` instead of per-state counts. `stashed` is `≡`. `ahead_behind` keeps starship's default arrows and is drawn in `cyan`.

**python.** With both detect lists empty, the module does not trigger on `.py` files or `pyproject.toml`. It shows only the name of an active virtualenv.

### Prompt character

| State | Symbol |
| --- | --- |
| Last command succeeded | `❯` in `purple` |
| Last command failed | `❯` in `red` |
| Vi normal mode (fish) | `❮` in `green` |

fish runs in vi mode ([key bindings](fish.md#key-bindings)), so `vimcmd_symbol` appears there. zsh uses the emacs keymap and never shows it.

## Colors

There is no `palette`. Every module style is an ANSI color name, so the prompt draws with the terminal's 16 colors (`purple` is ANSI 5, `bright-black` ANSI 8). On Omarchy those colors come from the active theme's `colors.toml`: Ghostty includes the generated `ghostty.conf` ([Ghostty](../terminal/ghostty.md)), and Omarchy sends the same palette into running tmux panes. A theme switch therefore recolors the prompt with no edit here. Elsewhere, Ghostty's `cyberdream` theme supplies them.

| Name | cyberdream | Hazy Peak | Used by |
| --- | --- | --- | --- |
| `blue` | `#5ea1ff` | `#333333` | directory |
| `purple` | `#bd5eff` | `#3d3d3d` | `❯` |
| `red` | `#ff6e5e` | `#c67777` | `❯` after a failure, dirty `*` |
| `green` | `#5eff6c` | `#5e5e5e` | `❮` (vi normal) |
| `cyan` | `#5ef1ff` | `#525252` | ahead/behind, stash |
| `yellow` | `#f1ff5e` | `#727272` | command duration |
| `bright-black` | `#7b8496` | `#8a8a8a` | branch, git state, virtualenv, clock |

Hazy Peak's values are read off its reference screenshot: graphite steps on `#cccccc`, with the Umbriel warning red `#c67777` as the only color. On Omarchy, cyberdream's `bright-black` is its `muted` `#7b8496`. The old palette's `#4a4d4f` was close to unreadable on `#16181a`.
