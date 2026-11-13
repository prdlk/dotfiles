#!/usr/bin/env bash
# Undim a window once the popup over it closes (tmux.conf: the display-popup
# alias dims the window, then starts this with run-shell -b just before the
# popup opens). tmux has no popup-closed hook, and pane-focus-in is not raised
# reliably when a popup closes, so this waits for the popup's process: the
# tmux server's child on a pty that no pane uses.
#
# Usage: popup-undim.sh <window_id>

window="$1"
server_pid="$(tmux display-message -p '#{pid}')"

popup_pid() {
	local panes pid tty
	panes="$(tmux list-panes -a -F '#{pane_tty}')"
	while read -r pid tty; do
		[ "$tty" = "?" ] && continue
		\grep -qxF "/dev/$tty" <<<"$panes" || { echo "$pid"; return; }
	done < <(ps -o pid=,tty= --ppid "$server_pid")
}

# sleep without starting a process
exec {nap}<> <(:)

# The popup starts right after this does; give it up to a second to appear.
pid=""
for _ in {1..50}; do
	pid="$(popup_pid)"
	[ -n "$pid" ] && break
	read -rt 0.02 -u "$nap"
done
if [ -n "$pid" ]; then
	while kill -0 "$pid" 2>/dev/null; do read -rt 0.05 -u "$nap"; done
fi

tmux set -wu -t "$window" window-style \; set -wu -t "$window" window-active-style
