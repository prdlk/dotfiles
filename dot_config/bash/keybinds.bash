# ~/.config/bash/keybinds.bash — readline ports of the television keys in
# fish_user_key_bindings.fish / zsh keybinds.zsh:
#   ctrl-o → gho (ghq-repos cable, cd)     ctrl-e → tv git-files (nvim)
#   ctrl-p → pj (pj cable)                 down   → pj on an empty prompt
#   ctrl-t → tv smart autocomplete (tv init bash ships no ctrl-t)
# Keys owned by kitty.conf never reach the shell: ctrl-h/j/k/l (pass_keys.py).
#
# Every picker runs tv --inline: it opens on the line below the prompt and
# leaves the cursor on that line when it exits. When nothing was printed
# below, the binding steps back up (_kb_up) so readline redraws the prompt in
# place after bind -x; output that must stay (a pj task) is left alone.

_kb_up() { printf '\033[A' >/dev/tty; }

# ctrl-e: enter opens nvim, which restores the cursor to tv's line.
_kb_git_files() {
    tv git-files --inline </dev/tty
    _kb_up
}
bind -x '"\C-e": _kb_git_files'

# ctrl-p, and down on an empty prompt. pj reports through $PJ_STATE: `open`
# = cancelled, `ran` = a task printed output, empty = no task sources.
_kb_pj() {
    local state
    state=$(mktemp) || return
    PJ_STATE=$state pj "$@" </dev/tty
    [ "$(<"$state")" = open ] && _kb_up
    rm -f "$state"
}
bind -x '"\C-p": _kb_pj'

# ctrl-o: gho, split so the prompt is right. bind -x runs in the shell
# process, so the cd persists — but readline keeps drawing the prompt it
# started with. The macro runs \C-x1 (pick with tv, cd), then \C-x2 and \C-x3,
# which _kb_gho rebinds: after a cd, \C-x2 accepts the stashed-empty line
# (bash prints a fresh prompt for the new cwd; nothing reaches history) and
# \C-x3 does gho's clear + onefetch, after which readline redraws that fresh
# prompt below the output; when cancelled both just redraw. \C-x0 restores
# the typed text.
_kb_gho() {
    local dir
    _kb_line=$READLINE_LINE _kb_point=$READLINE_POINT
    dir=$(tv ghq-repos --inline </dev/tty)
    _kb_up
    if [ -n "$dir" ] && cd "$dir"; then
        READLINE_LINE='' READLINE_POINT=0
        bind '"\C-x2": accept-line'
        bind -x '"\C-x3": _kb_gho_show'
    else
        bind '"\C-x2": redraw-current-line'
        bind '"\C-x3": redraw-current-line'
    fi
}
_kb_gho_show() {
    clear
    if [ -d .git ]; then
        onefetch
    fi
}
_kb_restore() {
    READLINE_LINE=${_kb_line-} READLINE_POINT=${_kb_point-0}
    unset _kb_line _kb_point
}
bind -x '"\C-x1": _kb_gho'
bind -x '"\C-x0": _kb_restore'
bind '"\C-o": "\C-x1\C-x2\C-x3\C-x0"'

# down: the pj cable on an idle, empty prompt, otherwise history search
# (fish's _pj_bind_down). bind -x can't call readline functions, so _kb_down
# rebinds \C-x5, which the macro sends right after it.
_kb_down() {
    if [ -n "$READLINE_LINE" ]; then
        bind '"\C-x5": history-search-forward'
        return
    fi
    PJ_QUIET=1 _kb_pj
    bind '"\C-x5": redraw-current-line'
}
bind -x '"\C-x4": _kb_down'
bind '"\e[B": "\C-x4\C-x5"'
bind '"\eOB": "\C-x4\C-x5"'

# ctrl-t: pick with the channel tv guesses from the text left of the cursor
# (shell_integration.channel_triggers) and insert the picks there, quoted.
_kb_tv_autocomplete() {
    local pre=${READLINE_LINE:0:READLINE_POINT} out item ins=''
    out=$(tv --autocomplete-prompt "$pre" --inline </dev/tty)
    _kb_up
    while IFS= read -r item; do
        [ -n "$item" ] && ins+="$(printf '%q' "$item") "
    done <<<"$out"
    READLINE_LINE=$pre$ins${READLINE_LINE:READLINE_POINT}
    READLINE_POINT=$((${#pre} + ${#ins}))
}
bind -x '"\C-t": _kb_tv_autocomplete'
