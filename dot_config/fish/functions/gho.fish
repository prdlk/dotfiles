function gho --description 'pick a ghq repo / Obsidian vault (tv ghq-repos cable) + cd'
    set -l dir (tv ghq-repos --inline); or return
    test -n "$dir"; or return 1
    cd $dir; or return
    clear
    if test -d .git
        onefetch
    end
end
