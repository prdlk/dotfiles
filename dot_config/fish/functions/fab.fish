function fab -d "Fuzzy find and execute a Fabric pattern"
    set -l json_file ~/.config/fabric/pattern_explainations.json
    
    if not test -f $json_file
        set_color red; echo "Error: $json_file not found."; set_color normal
        return 1
    end

    # 1. Safely capture piped input (if any) to a temp file
    # This preserves all formatting, newlines, and avoids variable escaping issues
    set -l temp_input (mktemp)
    if not isatty stdin
        cat > $temp_input
    end

    # 2. Parse JSON to TSV -> fzf (Name in list, Description in preview) -> Extract Name
    set -l selection (jq -r '.[] | "\(.name)\t\(.description)"' $json_file | \
        fzf --delimiter '\t' \
            --with-nth 1 \
            --preview 'echo {2}' \
            --preview-window 'right:60%:wrap' \
            --prompt 'Pattern > ' \
            --info inline \
            --bind 'ctrl-/:toggle-preview')

    # 3. Execute with or without the piped data
    if test -n "$selection"
        set -l pattern (string split -f 1 \t "$selection")
        
        # If our temp file has data (-s), pipe it. Otherwise, run bare.
        if test -s $temp_input
            cat $temp_input | fabric --pattern "$pattern"
        else
            fabric --pattern "$pattern"
        end
    end

    # 4. Clean up
    rm -f $temp_input
end
