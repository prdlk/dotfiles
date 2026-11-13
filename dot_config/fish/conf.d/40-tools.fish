# Tool initialization.
# mise provides tool shims, so activate it for every shell (scripts included).
command -q mise; and mise activate fish | source

# Everything below spawns subprocesses or only matters for a prompt —
# skip it for non-interactive shells to keep scripts fast.
status is-interactive; or return

# Material You terminal colors generated from the wallpaper (quickshell).
if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
end

command -v tv >/dev/null 2>&1; and tv init fish | source
command -v starship >/dev/null 2>&1; and starship init fish | source
command -v zoxide >/dev/null 2>&1; and zoxide init fish | source
command -v entire >/dev/null 2>&1; and entire completion fish | source
# television fuzzy finder — sourced BEFORE hishtory so hishtory keeps
# ctrl-r; tv's default binds are curated in fish_user_key_bindings.
command -v tv >/dev/null 2>&1; and tv init fish | source

# hishtory shell history
test -f ~/.hishtory/config.fish; and source ~/.hishtory/config.fish

# unsloth studio python venv
test -f ~/.unsloth/studio/unsloth_studio/bin/activate.fish
    and source ~/.unsloth/studio/unsloth_studio/bin/activate.fish

