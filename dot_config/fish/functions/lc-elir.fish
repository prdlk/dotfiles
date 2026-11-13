function lc-elir -d "fzf-pick LeetCode solution files and run /leetcode-eli5 on each via omp"
    set -l root (count $argv > /dev/null; and echo $argv[1]; or echo .)
    # Match only numbered problem files: 1365.some-slug.js anywhere in the tree
    set -l files (fd --type f '^\d+\..+\.(js|ts)$' $root \
        | fzf --multi \
              --prompt='eli5> ' \
              --delimiter=/ \
              --with-nth=-3.. \
              --preview 'bat --color=always --line-range=:40 {}' \
              --preview-window=right:60%)
    test -z "$files"; and return 1
    for f in $files
        echo "── /leetcode-eli5 $f"
        omp -p "/leetcode-eli5 $f"
    end
end
