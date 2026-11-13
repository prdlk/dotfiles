function clip-last --description 'Re-run last command, copy output to clipboard'
    eval $history[1] | cpy
    notify-send -a fish "Clipboard" "Command output copied to clipboard"
end
