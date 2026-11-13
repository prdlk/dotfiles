function fish_title
    # Show a short hostname over SSH, otherwise just the current directory.
    if set -q SSH_TTY
        echo (prompt_hostname | string sub -l 10):(prompt_pwd)
    else
        prompt_pwd
    end
end
