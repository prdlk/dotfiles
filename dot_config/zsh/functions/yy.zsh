# yazi wrapper: cd to the directory yazi was left in on exit.
yy() {
    local tmp cwd
    tmp=$(mktemp -t "yazi-cwd.XXXXXX")
    command yazi "$@" --cwd-file="$tmp"
    cwd=$(cat -- "$tmp" 2>/dev/null)
    if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && [ -d "$cwd" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
