function ghg -a repo --description 'ghq get + cd (clone/path logic in ~/.local/bin/ghg-clone)'
    set -l dir (ghg-clone $repo); or return
    cd $dir; or return
    clear; and onefetch
end
