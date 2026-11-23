#!/usr/bin/env bash
# Copy the last command's output in a pane to the clipboard (tmux.conf:
# prefix + Y, Ghostty ctrl+shift+y). The shell marks each prompt and the
# start of each command's output with OSC 133 (A and C; fish 4 sends both
# itself), and tmux keeps those marks per line. Copy mode's previous-prompt /
# next-prompt -o find them: the output is the lines from the last command's
# output mark up to the line before the current prompt. It goes to a tmux
# buffer (prefix + ]) and, through load-buffer -w, to the clipboard (OSC 52).
#
# Usage: copy-last-output.sh <pane_id> [client_name]

pane="$1"
client="$2"

notify() { tmux display-message ${client:+-c "$client"} -d 1500 "$1"; }

if [ "$(tmux display -p -t "$pane" '#{alternate_on}')" = 1 ]; then
	notify "Not at a shell prompt"
	exit 0
fi
[ "$(tmux display -p -t "$pane" '#{pane_in_mode}')" = 1 ] && tmux send -t "$pane" -X cancel

# The copy-mode cursor's line, counted from the top of the history
line() { tmux display -p -t "$pane" '#{e|-:#{e|+:#{history_size},#{copy_cursor_y}},#{scroll_position}}'; }

# copy mode starts on the pane's cursor: the current prompt
tmux copy-mode -t "$pane"
prompt="$(line)"
tmux send -t "$pane" -X previous-prompt
command="$(line)"
tmux send -t "$pane" -X next-prompt -o
output="$(line)"
tmux send -t "$pane" -X cancel

if [ "$command" -ge "$prompt" ]; then
	notify "No previous command (the shell sends no OSC 133 prompt marks)"
	exit 0
fi
# A command without output has its output mark on the current prompt's line
if [ "$output" -le "$command" ] || [ "$output" -ge "$prompt" ]; then
	notify "The last command printed nothing"
	exit 0
fi

history="$(tmux display -p -t "$pane" '#{history_size}')"
# -J joins wrapped lines; $(...) drops the trailing newlines
text="$(tmux capture-pane -p -J -t "$pane" -S $((output - history)) -E $((prompt - 1 - history)))"
printf '%s' "$text" | tmux load-buffer -w ${client:+-t "$client"} -
notify "Copied $((prompt - output)) lines of output"
