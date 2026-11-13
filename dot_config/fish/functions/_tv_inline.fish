function _tv_inline --description 'tv --inline below the prompt, cursor back on the prompt line; stdout is the pick'
    # tv --inline opens on the line below the prompt and leaves the cursor on
    # its own first row when it exits; step back up so the following
    # `commandline -f repaint` redraws the prompt in place instead of one line
    # lower. /dev/tty keeps the move out of callers that capture stdout (gho).
    tv $argv --inline
    set -l st $status
    printf '\033[A' >/dev/tty
    return $st
end
