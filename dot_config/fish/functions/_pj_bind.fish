function _pj_bind --description 'ctrl-p / down: pj (tv --inline), then redraw the prompt in the right place'
    # pj reports through $PJ_STATE: `open` = the picker was cancelled and
    # left the cursor on the line below the prompt; empty = no task sources,
    # nothing drawn — but fish's repaint after an external command still
    # lands one line low, so both step back up. `ran` = a task printed
    # output: new line, prompt below it.
    set -lx PJ_STATE (mktemp)
    if contains -- --quiet $argv
        set -lx PJ_QUIET 1
    end
    pj
    set -l state (cat $PJ_STATE)
    switch "$state"
        case open ''
            printf '\033[A' >/dev/tty
        case ran
            printf '\n' >/dev/tty
    end
    rm -f $PJ_STATE
    commandline -f repaint
end
