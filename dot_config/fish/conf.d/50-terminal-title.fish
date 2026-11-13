# Set the tmux/screen window name from $PWD (the ESC-k sequence).
# fish_title() handles the regular terminal title; this targets multiplexers.
status is-interactive; or return

function terminal_title --on-variable PWD
    printf '\033k%s\033\\' (prompt_pwd)
end
terminal_title
