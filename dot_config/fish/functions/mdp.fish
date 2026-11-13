# ~/.config/fish/functions/mdv.fish
function mdp -d "Interactive Markdown selector and previewer"
    # Find markdown files up to 3 directories deep
    set -l file (fd --type f --extension md --max-depth 3 | fzf --preview 'mdfried {}' --preview-window=right:60%:wrap)

    # Execute mdfried on the selected file if one was chosen
    if test -n "$file"
        mdfried "$file"
    end
end
