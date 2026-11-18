#!/usr/bin/env bash
# tmux-resurrect post-save-layout hook: makes restored omp panes resume their
# own session. Resurrect saves a pane's command line as ps shows it (`omp`),
# and replaying that starts a fresh session. This rewrites the saved command
# of every pane running omp to `omp --resume <session file>`; the file comes
# from omp's terminal breadcrumb (~/.omp/agent/terminal-sessions/pts-N, what
# `omp --continue` reads), keyed by the pane's tty. `--continue` itself can't
# be replayed: restored panes get new ttys, whose breadcrumbs belong to other
# sessions. A pane whose omp has no session file yet (no message sent, or
# /new not yet materialized: breadcrumb older than the process or marked
# `fresh`) is saved as plain `omp`. @resurrect-processes lists omp, so these
# commands are replayed on restore.
#
# $1: the resurrect save file (tab-separated; pane lines: 2 session,
# 3 window, 6 pane index, 11 ":<full command>").

file=$1
[ -f "$file" ] || exit 0
crumbs="$HOME/.omp/agent/terminal-sessions"
now=$(date +%s)

# session<TAB>window<TAB>pane<TAB>command, one line per omp pane.
map=$(
	tmux list-panes -a -F '#{session_name}	#{window_index}	#{pane_index}	#{pane_pid}	#{pane_tty}' |
		while IFS=$'\t' read -r session window pane pid tty; do
			# omp is the pane's process (pj-palette --bg) or a child of its shell.
			if [ "$(cat "/proc/$pid/comm" 2>/dev/null)" != omp ]; then
				pid=$(pgrep -x -P "$pid" omp | head -n 1)
				[ -n "$pid" ] || continue
			fi
			cmd=omp
			tty=${tty#/dev/}
			crumb="$crumbs/${tty//\//-}"
			if [ -f "$crumb" ]; then
				started=$((now - $(ps -o etimes= -p "$pid")))
				{ read -r _cwd; read -r session_file; read -r marker; } <"$crumb"
				if [ "$(stat -c %Y "$crumb")" -ge "$started" ] && [ "$marker" != fresh ] && [ -f "$session_file" ]; then
					cmd="omp --resume $(printf '%q' "$session_file")"
				fi
			fi
			printf '%s\t%s\t%s\t%s\n' "$session" "$window" "$pane" "$cmd"
		done
)
[ -n "$map" ] || exit 0

tmp=$(mktemp "$file.XXXXXX") || exit 1
awk 'BEGIN { FS = OFS = "\t" }
	NR == FNR { cmd[$1 FS $2 FS $3] = $4; next }
	$1 == "pane" && (($2 FS $3 FS $6) in cmd) { $11 = ":" cmd[$2 FS $3 FS $6] }
	{ print }' <(printf '%s\n' "$map") "$file" >"$tmp" && mv "$tmp" "$file"
