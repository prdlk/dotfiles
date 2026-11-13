# bash and zsh

Secondary shells that share fish's aliases, starship prompt, atuin history, and cd-style helper functions.

bash and zsh are set up so a shell other than fish feels the same: the same aliases, the same starship prompt, atuin history, ports of the fish helpers that have to change the shell's own directory, and the same picker key bindings.

| Source (repo) | Target |
| --- | --- |
| `dot_bashrc` | `~/.bashrc` |
| `dot_zshrc` | `~/.zshrc` |
| `dot_config/zsh/keybinds.zsh` | `~/.config/zsh/keybinds.zsh` |
| `dot_config/bash/keybinds.bash` | `~/.config/bash/keybinds.bash` |
| `dot_config/shell/aliases.sh.tmpl` | `~/.config/shell/aliases.sh` (template) |
| `dot_config/bash/functions/*.bash` | `~/.config/bash/functions/` |
| `dot_config/zsh/functions/*.zsh` | `~/.config/zsh/functions/` |

`aliases.sh.tmpl` is the only template. It renders the alias list from `.chezmoidata/aliases.yaml` ([chezmoi data](../chezmoi/data.md)). The other files apply as-is on every OS.

## Installation

bash is part of the base system. zsh is in `.chezmoidata/packages.yaml` for Arch and Ubuntu (macOS ships it), alongside `zsh-syntax-highlighting`, `starship`, `atuin`, `eza`, and `zoxide`. `suvadu` (the `suv` history tool) is declared under `packages.shared.cargo` and installed by [15-tools](../chezmoi/scripts.md#15-tools).

## ~/.bashrc

Interactive shells only (`[[ $- != *i* ]] && return`). In order:

1. **PATH.** Prepends `~/.local/bin` if missing, sources `~/.cargo/env` if present, evaluates `brew shellenv` when Homebrew is installed (macOS), runs `mise activate bash` when mise is installed, and appends `~/.maestro/bin` if it exists. Exports `GHQ_ROOT` and `CODE_ROOT` as `~/Code`.
2. **Go.** `GOPATH=~/.local/share/go`, `GOBIN=$GOPATH/bin`, and `GOBIN` prepended to `PATH`. mise provides `GOROOT`. The same two values are also in `~/.config/go/env` (`dot_config/go/env.tmpl`), Go's own config file, so every `go` invocation uses them even without these variables (cron, `sudo -u`, `env -i`, GUI apps).
3. **Android SDK.** `ANDROID_HOME` and `ANDROID_SDK_ROOT` set to `~/.local/share/android-sdk`. `platform-tools`, `cmdline-tools/latest/bin`, and `emulator` are prepended if they exist, so they win over the legacy AUR tools `/etc/profile.d/android-sdk.sh` appends. `JAVA_HOME` points at JDK 17 (`/usr/lib/jvm/java-17-openjdk`) when it is installed, for Gradle/AGP builds. Exports `GITHUB_TOKEN` from `gh auth token` unless it is already set, and every variable in `~/.config/free-router/env` (`FREE_ROUTER_PORT`, `FREE_ROUTER_API_KEY`) if that file exists. The file comes from the [desktop layer](https://prad.codes/env/omarchy-desktop/src/branch/main/docs/free-router.md), so it only exists on Omarchy machines.
4. **Aliases.** Sources `~/.config/shell/aliases.sh`.
5. **Functions.** Sources every `~/.config/bash/functions/*.bash`.
6. **Flyline.** If `~/.local/lib/libflyline.so` exists, loads it with `enable -f … flyline` for richer line editing.
7. Sources `~/.config/envman/load.sh` if it is non-empty.
8. **Prompt.** `eval "$(starship init bash)"` if starship is installed.
9. **television.** `eval "$(tv init bash)"` if `tv` is installed (the `_tv` completion), then sources `~/.config/bash/keybinds.bash`.
10. **atuin.** `eval "$(atuin init bash)"` if atuin is installed (the package's binary; see [atuin](atuin.md#installation)). atuin comes after tv, so it keeps <kbd>ctrl-r</kbd> and <kbd>up</kbd>.

## ~/.zshrc

1. **History.** `HISTFILE=~/.zsh_history`, `HISTSIZE=10000`, `SAVEHIST=10000`, `setopt SHARE_HISTORY HIST_IGNORE_DUPS`.
2. **Completion.** `autoload -Uz compinit && compinit`.
3. The same PATH, Go, Android, `GITHUB_TOKEN`, and free-router blocks as `.bashrc` (including the Homebrew and mise lines, `GHQ_ROOT` and `CODE_ROOT`).
4. Sources `~/.config/shell/aliases.sh`.
5. Sources every `~/.config/zsh/functions/*.zsh`.
6. Sources `~/.config/zsh/keybinds.zsh`.
7. `eval "$(suv init zsh)"` if suvadu is installed.
8. Sources `~/.config/envman/load.sh` if it is non-empty.
9. **Prompt.** If starship is installed: `eval "$(starship init zsh)"`, `ZLE_RPROMPT_INDENT=0` (the right-prompt clock sits flush with the edge), and a transient prompt. A `line-finish` zle hook swaps `PROMPT`/`RPROMPT` to the `transient` and `transient_right` starship profiles (`❯`, colored by the last exit status, and the time) and redraws, so past prompts collapse as in fish; a `precmd` hook restores the full prompt. Starship's zsh init also sets `PROMPT2`, the `∙` continuation prompt for unfinished lines. See [Starship](starship.md#shell-integration).
   **Window title.** A `precmd` hook ports `fish_title`: it sets the terminal title to `%~`, prefixed with the first 10 characters of the hostname over SSH, and inside tmux also sets the window name (`ESC k`), like fish's `50-terminal-title.fish`. Unlike fish's `prompt_pwd`, the path is not abbreviated.
10. `eval "$(tv init zsh)"` if `tv` is installed (<kbd>ctrl-t</kbd> smart autocomplete).
11. **Syntax highlighting.** Sources the first `zsh-syntax-highlighting.zsh` found in `/usr/share/zsh/plugins/zsh-syntax-highlighting/` (Arch), `/usr/share/zsh-syntax-highlighting/` (Ubuntu), or `$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/` (Homebrew). The comment says this must stay last, because it wraps every zle widget defined before it.
12. **atuin.** `eval "$(atuin init zsh)"` if atuin is installed. This line comes after the syntax-highlighting block, so despite the comment, syntax highlighting is not actually last. atuin loads after tv, so it keeps <kbd>ctrl-r</kbd>.

## zsh key bindings

`keybinds.zsh` ports `fish_user_key_bindings.fish` to zle. Unlike fish, zsh uses the **emacs** keymap: `bindkey -e` pins it so that `$EDITOR=nvim` does not switch zsh into vi mode. `unsetopt flow_control` frees <kbd>ctrl-q</kbd> and <kbd>ctrl-s</kbd> from the terminal.

A generic widget `_zle-run` is registered as `run-<cmd>` for `purple`, `clip-last`, `omp`, `yy`, and `lazygit`. It clears the pending display (`zle -I`), runs the command with the tty on stdin, then `zle reset-prompt`. Widgets run in the shell process, so directory changes made by `gho` and `yy` persist.

The tv pickers have their own widgets, because `tv --inline` opens on the line below the prompt and leaves the cursor there on exit. `zle -I` followed by `zle reset-prompt` redraws the prompt where zle last drew it, wiping anything printed below; `zle -I` alone draws a fresh prompt under the output.

| Widget | Runs | Then |
| --- | --- | --- |
| `tv-git-files` | `tv git-files --inline` | `\033[A`, `reset-prompt` |
| `gho-inline` | `gho` | cwd unchanged: `\033[A`, `reset-prompt`. After a cd: nothing, so the new prompt lands below onefetch |
| `pj-inline`, `pj-down` | `_zle-pj`: `pj` with `PJ_STATE` set to a temp file (`PJ_QUIET=1` for `pj-down`) | `open` (cancelled): `\033[A`, `reset-prompt`. `ran`: nothing, so the task output stays. Empty (no task sources): `reset-prompt` |

| Key | Action |
| --- | --- |
| <kbd>ctrl-e</kbd> | `tv-git-files` (pick a file, open it in nvim) |
| <kbd>ctrl-f</kbd> | `yy` |
| <kbd>ctrl-b</kbd> | `purple` (an external command; this repo does not provide it) |
| <kbd>ctrl-y</kbd> | `clip-last` |
| <kbd>ctrl-o</kbd> | `gho-inline` (`ghq-repos` cable, cd) |
| <kbd>ctrl-p</kbd> | `pj-inline` (`pj` cable) |
| <kbd>ctrl-t</kbd> | tv smart autocomplete (from `tv init zsh`) |
| <kbd>down</kbd> | `pj-down`: `PJ_QUIET=1 pj` on an empty prompt, otherwise `down-line-or-history` (bound to `^[[B` and `^[OB`) |
| <kbd>ctrl-a</kbd> | `omp-session`: resume or start omp for the current repo ([Scripts](scripts.md#omp-session)) |
| <kbd>ctrl-n</kbd> | `omp`: always a new omp session (replaces zsh's `down-line-or-history` on that key; <kbd>down</kbd> still walks history) |
| <kbd>ctrl-g</kbd> | `lazygit` |
| <kbd>ctrl-q</kbd> | `exit` |
| <kbd>ctrl-c</kbd> | At the prompt: kill the buffer, clear the screen and kitty scrollback (`ESC[2J ESC[3J`), reset the prompt |

<kbd>ctrl-c</kbd> is the tty interrupt character, so `bindkey '^C'` would never fire. The binding is a `TRAPINT` function instead. At the prompt it runs `zle .kill-buffer`, prints the clear sequence, and runs `zle .reset-prompt`. While a command is running, SIGINT keeps its normal behavior (returns `128+SIGINT`).

The fish-only binds <kbd>ctrl-w</kbd> (atuin AI) and <kbd>?</kbd> have no zsh equivalent. <kbd>ctrl-h/j/k/l</kbd> belong to kitty ([kitty](../terminal/kitty.md)) and are not bound here. The cables are described on the [television](../tools/television.md) page.

## bash key bindings

`keybinds.bash` gives bash the same picker keys as fish and zsh. bash keeps readline's default emacs keymap. Every picker runs `tv --inline`; when nothing was printed below the prompt, `_kb_up` (`\033[A` on `/dev/tty`) steps back so readline redraws the prompt in place after `bind -x`.

| Key | Action |
| --- | --- |
| <kbd>ctrl-o</kbd> | Macro `\C-x1\C-x2\C-x3\C-x0` (below): pick from the `ghq-repos` cable and cd |
| <kbd>ctrl-e</kbd> | `_kb_git_files`: `tv git-files --inline`, then `_kb_up` |
| <kbd>ctrl-p</kbd> | `_kb_pj`: `pj` with `PJ_STATE` set to a temp file; `_kb_up` only when the state is `open` (cancelled) |
| <kbd>down</kbd> | `PJ_QUIET=1 _kb_pj` on an empty prompt, otherwise `history-search-forward` |
| <kbd>ctrl-t</kbd> | `_kb_tv_autocomplete`: runs `tv --autocomplete-prompt … --inline` on the text left of the cursor, `_kb_up`, and inserts the picks there, each `printf %q`-quoted |

`bind -x` runs in the shell process, so a `cd` persists, but readline keeps drawing the prompt it started with. <kbd>ctrl-o</kbd> is therefore a macro:

1. `\C-x1` runs `_kb_gho`: stashes `READLINE_LINE`, runs `tv ghq-repos --inline`, `_kb_up`, and cds into the pick. It does not call the `gho` function. After a cd it empties the line and rebinds `\C-x2` to `accept-line` and `\C-x3` to `bind -x _kb_gho_show`; when cancelled it rebinds both to `redraw-current-line`.
2. `\C-x2` accepts the empty line, so bash prints a fresh prompt for the new cwd. Nothing reaches history.
3. `\C-x3` runs `_kb_gho_show` (`clear`, then `onefetch` in git repos); readline redraws the prompt below the output.
4. `\C-x0` runs `_kb_restore`, which puts the typed text back.

<kbd>down</kbd> (`\e[B` and `\eOB`) is the macro `\C-x4\C-x5`. `bind -x` cannot call readline functions, so `_kb_down` (`\C-x4`) rebinds `\C-x5` to `history-search-forward` when the line is non-empty, or runs `PJ_QUIET=1 _kb_pj` and rebinds `\C-x5` to `redraw-current-line`.

## Shared aliases: aliases.sh

`~/.config/shell/aliases.sh` is rendered from `.chezmoidata/aliases.yaml`. Each YAML `section` becomes a comment, and each item becomes `alias <name>='<cmd>'`. The template then appends shell-specific extras that are not in the YAML:

**~/.config/shell/aliases.sh**

```sh
# Clipboard
if command -v wl-copy >/dev/null 2>&1; then
    alias cpy='wl-copy'
    alias pst='wl-paste'
fi

q() {
    if [ -n "$YAZI_ID" ] && command -v ya >/dev/null 2>&1; then
        ya emit quit 2>/dev/null
    fi
    exit
}

alias celar='clear'
alias claer='clear'
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons'
fi
```

- **Clipboard detection.** `cpy`/`pst` map to Wayland's `wl-copy`/`wl-paste` when `wl-copy` exists; they are not defined on macOS.
- **`q`.** Exits the shell. If the shell was spawned from yazi's own `q` binding (`$YAZI_ID` set), it runs `ya emit quit` first so the parent yazi closes too instead of bouncing back.
- **Typo guards and eza.** `celar`/`claer` → `clear`, and `ls` → `eza --icons` when eza is installed. The file is sourced only by interactive shells, so scripts keep the real `ls`.

The full alias table, including the differences from fish, is on the [Aliases](aliases.md) page.

## Per-shell functions

Each directory holds one function per file. bash and zsh source every file at startup; the bash and zsh versions have identical bodies.

| Function | Behavior |
| --- | --- |
| `c [dir]` | `clear` with no argument, `cd "$1"` with one |
| `cd [dir]` | No argument: `$HOME`. `-`: previous dir. Otherwise `builtin cd`, falling back to `zoxide query -- "$1"`. Records the result with `zoxide add "$PWD"` and preserves cd's exit status |
| `clip-last` | Re-runs the previous history entry (`fc -ln -1 -1`, skipping itself if the line editor already recorded `clip-last`), pipes the output to `wl-copy` or `pbcopy`, and sends a `notify-send -a shell` notification if available |
| `ghg <repo>` | `ghg-clone "$@"`, cd into the printed path, `clear && onefetch` |
| `ghn <name>` | `command ghn "$@"`, cd into the printed path |
| `gho` | `dir=$(tv ghq-repos --inline)`, return if empty, cd into it, `clear`, and `onefetch` if it is a git repo. No cursor handling; bash <kbd>ctrl-o</kbd> does not call it |
| `yy [args]` | `yazi --cwd-file=<tmp>`, then cd to the directory written there if it changed |

The `ghg` helper script is named `ghg-clone` because an unrelated cargo binary already uses the name `ghg`. The [Scripts](scripts.md#why-some-helpers-are-shell-functions) page explains why these helpers are shell functions and not scripts.
