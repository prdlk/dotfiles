function cp-appid --description "Fuzzy-pick a desktop app ID and copy to clipboard"
    set -l search_dirs \
        /usr/share/applications \
        /usr/local/share/applications \
        $HOME/.local/share/applications \
        /var/lib/flatpak/exports/share/applications \
        $HOME/.local/share/flatpak/exports/share/applications \
        /var/lib/snapd/desktop/applications

    set -l existing_dirs
    for d in $search_dirs
        test -d $d; and set -a existing_dirs $d
    end

    test (count $existing_dirs) -eq 0
        and echo "No application directories found." >&2
        and return 1

    set -l chosen (
        fd --type f --extension desktop . $existing_dirs \
        | while read -l f
            set -l app_id (basename $f .desktop)
            set -l name (rg -m1 '^Name=' $f | string replace 'Name=' '')
            test -z "$name"; and set name $app_id
            echo "$name\t$app_id"
        end \
        | sort -u -t\t -k1 \
        | fzf \
            --delimiter='\t' \
            --with-nth=1,2 \
            --prompt="App ID › " \
            --height=50% \
            --layout=reverse \
            --border=rounded \
            --info=inline
    )

    test -z "$chosen"; and return 0

    set -l app_id (string split '\t' $chosen)[2]
    echo -n $app_id | wl-copy
    echo "Copied: $app_id"
end
