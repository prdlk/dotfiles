# Pick a ghq repo / Obsidian vault with tv (ghq-repos cable) + cd.
gho() {
    local dir
    dir=$(tv ghq-repos --inline) || return
    [ -n "$dir" ] || return 1
    cd "$dir" || return
    clear
    if [ -d .git ]; then
        onefetch
    fi
}
