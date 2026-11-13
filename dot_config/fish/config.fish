# Config is split into autoloaded files (see `man fish` → Configuration files):
#   conf.d/00-path.fish          PATH entries
#   conf.d/10-env.fish           environment + fish_greeting + fzf theme
#   conf.d/20-aliases.fish       aliases
#   conf.d/40-tools.fish         starship / zoxide / mise / hishtory init
#   conf.d/50-terminal-title.fish tmux window title
#   conf.d/secrets.fish          API keys (gitignored)
#   functions/                   one autoloaded function per file
#   functions/fish_user_key_bindings.fish  key bindings
#
# Nothing needs to live here; keep it empty so startup stays fast.

function starship_transient_prompt_func
  starship module character
end

function starship_transient_rprompt_func
  starship module time
end

starship init fish | source
enable_transience

# Pin the prompt to the bottom of the terminal (FISH_BOTTOM_PROMPT=1, the
# default from conf.d/10-env.fish; set 0 for the normal top prompt).
# functions/clear.fish and the ctrl-l binding re-pin it after clearing.
status is-interactive; and test "$FISH_BOTTOM_PROMPT" = 1; and tput cup $LINES 0

# >>> grok installer >>>
fish_add_path $HOME/.grok/bin
# <<< grok installer <<<

# Generated for envman. Do not edit.
test -s ~/.config/envman/load.fish; and source ~/.config/envman/load.fish

if status is-interactive
    atuin init fish | source
    # atuin 18.21 dropped `atuin ai init`; the `?` binding it used to emit is
    # copied below as _atuin_ai_question_mark.
end

# cmux
fish_add_path "/home/prad/.cmux/bin"
fish_add_path "/home/prad/.cache/.bun/bin"

for _f in $HOME/.config/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.fish
    test -r "$_f"; and source "$_f"; and break
end


# Question mark at start of line - natural language mode
function _atuin_ai_question_mark
    set -l buf (commandline -b)

    # If buffer is empty or just contains '?', trigger natural language mode
    if test -z "$buf" -o "$buf" = "?"
        commandline -r ""

        # Close the semantic prompt zone (OSC 133 C) so terminals with
        # shell integration don't erase the TUI's output during their
        # resize-time prompt reflow.
        printf '\033]133;C\007' > /dev/tty

        # Run atuin ai inline, swapping stdout and stderr
        set -l output (atuin ai inline --hook 3>&1 1>&2 2>&3 | string collect)

        if string match --quiet '__atuin_ai_print__:*' "$output"
            echo (string replace "__atuin_ai_print__:" "" -- "$output" | string collect)
            commandline -f repaint
        else if test "$output" = "__atuin_ai_cancel__"
            commandline -f repaint
        else if string match --quiet '__atuin_ai_execute__:*' "$output"
            # Execute the command immediately
            set -l cmd (string replace "__atuin_ai_execute__:" "" -- "$output" | string collect)
            commandline -r "$cmd"
            commandline -f repaint
            commandline -f execute
        else if string match --quiet '__atuin_ai_insert__:*' "$output"
            # Insert the command for editing
            set -l cmd (string replace "__atuin_ai_insert__:" "" -- "$output" | string collect)
            commandline -r "$cmd"
            commandline -f repaint
        else if test -n "$output"
            # Default: insert for editing
            commandline -r "$output"
            commandline -f repaint
        else
            commandline -f repaint
        end
    else if not contains -- "$fish_key_bindings" fish_vi_key_bindings fish_hybrid_key_bindings
        # Not at empty prompt, just insert the question mark
        commandline -i "?"
    end
end

# Set up keybindings
bind "?" _atuin_ai_question_mark

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/prad/.lmstudio/bin
# End of LM Studio CLI section

