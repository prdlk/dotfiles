# Re-run last command, copy output to clipboard.
# History-offset handling: some line editors add the current command to
# history before execution, some after — detect instead of assuming.
clip-last() {
    local last copy
    last=$(fc -ln -1 -1 2>/dev/null)
    last=${last#"${last%%[![:space:]]*}"} # trim leading whitespace
    case $last in
        clip-last*)
            last=$(fc -ln -2 -2 2>/dev/null)
            last=${last#"${last%%[![:space:]]*}"}
            ;;
    esac
    if [ -z "$last" ]; then
        echo "clip-last: no previous command in history" >&2
        return 1
    fi
    if command -v wl-copy >/dev/null 2>&1; then
        copy=wl-copy
    else
        echo "clip-last: no clipboard tool (wl-copy) found" >&2
        return 1
    fi
    eval "$last" | "$copy"
    command -v notify-send >/dev/null 2>&1 \
        && notify-send -a shell "Clipboard" "Command output copied to clipboard"
}
