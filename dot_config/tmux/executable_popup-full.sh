#!/usr/bin/env bash
# Open a tmux popup over the whole client except the status bar, so the tab
# bar stays visible: full width, edge on the line next to the status bar
# (-y S), height the client minus the status lines. Every floating window
# (tmux.conf bindings, tmux-palette items, pj-palette, workmux-palette) opens
# through this; the palettes' own popups keep their size.
#
# Usage: popup-full.sh [display-popup flags] [command...]
# Flags and command go to `tmux display-popup` as given (-E, -d, -T, -e, ...).
# display-popup does not expand formats in -h, so the height is computed here.

# #{status} comes from the client's session: without -t, tmux may resolve the
# format against another session (pj-palette --bg just created one with its
# status off).
read -r height session < <(tmux display -p '#{client_height} #{client_session}')
status=$(tmux display -p -t "=$session:" '#{status}')
case $status in
off) lines=0 ;;
on) lines=1 ;;
*) lines=$status ;; # 2..5
esac
exec tmux display-popup -x 0 -y S -w 100% -h "$((height - lines))" "$@"
