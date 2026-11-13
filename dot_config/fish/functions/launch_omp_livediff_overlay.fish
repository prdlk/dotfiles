function launch_omp_livediff_overlay --description "Overlay omp on the current kitty window with a livediff split beside it"
    # kitty appends -PID to config-file listen_on sockets, so a hardcoded
    # --to unix:@kitty-local never matches. kitty @ resolves the real
    # address from $KITTY_LISTEN_ON on its own.
    if not set -q KITTY_LISTEN_ON
        echo "launch_omp_livediff_overlay: no kitty remote-control socket (KITTY_LISTEN_ON unset)" >&2
        return 1
    end

    # omp overlays the current window; capture its window id
    set -l wid (kitty @ launch --type=overlay-main --cwd=current omp)
    or return

    # livediff side by side in the same tab; keep focus on omp
    kitty @ launch --match id:$wid --location=vsplit --keep-focus --cwd=current livediff
end
