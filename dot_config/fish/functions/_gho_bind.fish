function _gho_bind --description 'ctrl-o: gho (tv --inline), then redraw the prompt in the right place'
    set -l before $PWD
    gho
    if test "$PWD" = "$before"
        # Cancelled (or the nvim action ran): tv --inline left the cursor on
        # the line below the prompt; step back so repaint redraws in place.
        printf '\033[A' >/dev/tty
    else
        # cd + clear + onefetch: put the prompt below onefetch's output.
        printf '\n' >/dev/tty
    end
    commandline -f repaint
end
