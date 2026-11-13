function gdc --description "Discard all git changes with gum confirmation"
    if gum confirm "Discard all uncommitted changes? This is irreversible."
        git reset --hard HEAD
        git clean -fd
        echo "Changes wiped."
    else
        echo "Operation aborted."
    end
end
