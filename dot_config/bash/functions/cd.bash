# cd with zoxide fallback, else builtin cd.
cd() {
    local rc target
    if [ $# -eq 0 ]; then
        builtin cd "$HOME"
    elif [ "$1" = - ]; then
        builtin cd -
    elif builtin cd "$1" 2>/dev/null; then
        : # exact path resolved, nothing else to do
    elif command -v zoxide >/dev/null 2>&1; then
        target=$(zoxide query -- "$1" 2>/dev/null)
        if [ -n "$target" ]; then
            builtin cd "$target"
        else
            builtin cd "$1" # let builtin cd surface the real error
        fi
    else
        builtin cd "$1"
    fi
    rc=$?
    command -v zoxide >/dev/null 2>&1 && zoxide add "$PWD" 2>/dev/null
    return $rc
}
