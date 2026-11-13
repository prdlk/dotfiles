function ghn -a repo --description 'create repo + cd (logic in ~/.local/bin/ghn)'
    set -l dir (command ghn $repo); or return
    cd $dir
end
