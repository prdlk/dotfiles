#!/bin/bash
# ~/.config/tmux/tab-label.sh — the tab label for any program but an editor or
# an idle shell, kitty tab_bar.py's rule: the repo the pane's cwd belongs to
# (dir name if no repo, ~ at home). Editors (the open file) and idle shells
# (the shell's name) are handled in tmux.conf's automatic-rename-format.
# Args: $1 pane_current_path  $2 window_id

path=$1 window=$2

if [[ $path == "$HOME" ]]; then
    label='~'
else
    dir=$path
    while [[ -n $dir && ! -e $dir/.git ]]; do dir=${dir%/*}; done
    root=${dir:-$path}
    label=${root##*/}
fi
printf '%s' "$label"

# tmux runs #() jobs async and only re-checks a window's name on pane output,
# so after a `cd` the tab would keep the old label until the next keystroke.
# Re-arming automatic-rename makes tmux re-check now and pick up this output.
if [[ -n $window && $(tmux display -p -t "$window" '#W' 2>/dev/null) != *"${label:0:26}"* ]]; then
    tmux set -w -t "$window" automatic-rename on >/dev/null 2>&1 &
fi
