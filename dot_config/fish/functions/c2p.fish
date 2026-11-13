function c2p --description "Code2Prompt with fuzzy-search template"
    fd --type f --extension hbs . $HOME/.config/code2prompt | fzf | xargs code2prompt --template
end 
