# ghq get + cd; clone/path logic lives in ~/.local/bin/ghg-clone.
# (helper is not named ghg: an unrelated cargo binary owns that name)
ghg() {
    local dir
    dir=$(ghg-clone "$@") || return
    cd "$dir" || return
    clear && onefetch
}
