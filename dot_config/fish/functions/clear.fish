function clear --wraps clear --description 'clear screen + kitty scrollback, prompt pinned to the bottom'
    if not status is-interactive
        command clear $argv
        return
    end
    # kitty doesn't clear scrollback with plain `clear`; 3J drops it.
    printf '\033[2J\033[3J\033[1;1H'
    # Re-pin only when the bottom prompt is enabled (FISH_BOTTOM_PROMPT=0
    # keeps the default top prompt).
    test "$FISH_BOTTOM_PROMPT" = 1; and tput cup $LINES 0
end
