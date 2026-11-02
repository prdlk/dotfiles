# c: clear with no args, cd with one.
c() {
    if [ -z "${1-}" ]; then
        clear
    else
        cd "$1"
    fi
}
