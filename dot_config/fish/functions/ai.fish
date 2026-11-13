function ai --description 'Choose and launch an AI CLI via gum'
    set -l choice (gum choose --header 'AI CLI' claude opencode codex hermes fractal)
    test -n "$choice"; or return  # cancelled (Esc / Ctrl-C) → bail out

    switch $choice
        case claude
            claude --dangerously-skip-permissions
        case '*'
            # labels match the binary names, so just run it
            # add a dedicated `case` here if another tool needs flags
            $choice
    end
end


