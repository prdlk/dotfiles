# Create a repo (prad.codes/github.com) + cd; logic lives in ~/.local/bin/ghn.
ghn() {
    local dir
    dir=$(command ghn "$@") || return
    cd "$dir" || return
}
