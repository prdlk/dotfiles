# ~/.config/zsh/keybinds.zsh — zle ports of fish_user_key_bindings.fish.
# Keys owned by kitty.conf never reach the shell and are NOT bound here:
#   ctrl-h/j/k/l → vim-aware split nav (pass_keys.py).

bindkey -e            # pin emacs keymap ($EDITOR containing "vi" would pick viins)
unsetopt flow_control # free ^Q/^S in zle so the ctrl-q exit bind fires

# Generic runner: widget `run-<cmd>` executes <cmd> (function or binary) with
# the tty as stdin, then repaints — fish's `commandline -f repaint`.
# cwd changes from gho/yy persist: widgets run in the shell process.
# gho, pj and `tv git-files` (below) open television cables (~/.config/
# television/cable) — the same keys do the same in fish and bash.
_zle-run() {
    local cmd=${WIDGET#run-}
    zle -I
    $cmd </dev/tty
    zle reset-prompt
}
for _cmd in purple clip-last omp-session omp yy lazygit; do
    zle -N "run-$_cmd" _zle-run
done
unset _cmd

# tv pickers run --inline below the prompt. zle -I + reset-prompt redraws the
# prompt where zle last drew it, wiping anything printed below; zle -I alone
# redraws a fresh prompt under the output. So: a cancelled picker (cursor
# left on the line below the prompt) steps back up and resets in place, and
# output that must stay (onefetch after gho's cd, a pj task) gets zle -I only.

# ctrl-e: tv git-files (bat preview, enter opens nvim, which restores the
# cursor to tv's line).
_zle-tv-git-files() {
    zle -I
    tv git-files --inline </dev/tty
    printf '\033[A' >/dev/tty
    zle reset-prompt
}
zle -N tv-git-files _zle-tv-git-files

# ctrl-o: gho (ghq-repos cable); cd + clear + onefetch when something was
# picked.
_zle-gho() {
    local before=$PWD
    zle -I
    gho </dev/tty
    if [[ $PWD == "$before" ]]; then
        printf '\033[A' >/dev/tty
        zle reset-prompt
    fi
}
zle -N gho-inline _zle-gho

# ctrl-p, and down on an idle empty prompt (fish's _pj_bind_down; otherwise
# normal history / multiline movement). pj reports through $PJ_STATE: `open`
# = cancelled, `ran` = a task printed output, empty = no task sources
# (PJ_QUIET keeps down silent outside projects).
_zle-pj() {
    if [[ $WIDGET == pj-down && -n $BUFFER ]]; then
        zle down-line-or-history
        return
    fi
    local state
    state=$(mktemp) || return
    zle -I
    if [[ $WIDGET == pj-down ]]; then
        PJ_STATE=$state PJ_QUIET=1 pj </dev/tty
    else
        PJ_STATE=$state pj </dev/tty
    fi
    case $(<$state) in
        open) printf '\033[A' >/dev/tty; zle reset-prompt ;;
        ran) ;;
        *) zle reset-prompt ;;
    esac
    rm -f $state
}
zle -N pj-inline _zle-pj
zle -N pj-down _zle-pj

bindkey '^E' tv-git-files
bindkey '^B' run-purple
bindkey '^Y' run-clip-last
bindkey '^O' gho-inline
bindkey '^P' pj-inline
# ctrl-a: omp-session resumes or starts omp for the repo; after a cancelled
# omp-sessions picker it moves the cursor back up itself.
bindkey '^A' run-omp-session
# ctrl-n: always a new omp session.
bindkey '^N' run-omp
# ctrl-f: yazi; yy cd's to yazi's exit dir on quit.
bindkey '^F' run-yy
bindkey '^G' run-lazygit
bindkey '^[[B' pj-down
bindkey '^[OB' pj-down

# ctrl-q mirrors ctrl-d's preset (`exit`) — quit the shell.
_zle-exit() { exit }
zle -N _zle-exit
bindkey '^Q' _zle-exit

# ctrl-c at the prompt: wipe any typed text AND clear screen + kitty
# scrollback (2J/3J drops it, like the fish `clear` wrapper). ^C is the tty
# INTR char, so this lives in TRAPINT — bindkey '^C' would never fire.
# Mid-command SIGINT behaves normally (128+SIGINT). BUFFER is read-only in
# trap context, so builtin widgets are invoked via `zle .name` instead.
TRAPINT() {
    if zle; then
        zle .kill-buffer
        printf '\033[2J\033[3J\033[1;1H'
        zle .reset-prompt
        return 0
    fi
    return $(( 128 + $1 ))
}
