function czs --description 'chezmoi: re-add drifted files, then commit + push the source repo'
    # Optional targets scope both the status view and the re-add,
    # e.g. `chs ~/.config/fish`. No args = all managed files.
    set -l drift (chezmoi status $argv)
    or return

    if test -n "$drift"
        printf '%s\n' $drift
        # re-add takes the local (destination) contents as truth for modified
        # files; templates are never overwritten, non-file entries are ignored.
        chezmoi re-add $argv
        or return
    else
        echo "chs: in sync — nothing to re-add"
    end

    # Commit + sync the source repo (~/.local/share/chezmoi).
    set -l src (chezmoi source-path)
    if test -n "$(git -C $src status --porcelain)"
        git -C $src add -A
        and git -C $src commit --quiet -m 'chs: re-add drifted files'
        or return
        echo "chs: committed "(git -C $src rev-parse --short HEAD)
    end

    # Push anything unpushed — covers this commit AND leftovers from a
    # previously failed push. --autostash tolerates post-commit hooks
    # (beads export) re-dirtying the tree mid-sync.
    set -l ahead (git -C $src rev-list --count @{upstream}..HEAD 2>/dev/null; or echo 0)
    if test $ahead -gt 0
        git -C $src pull --rebase --autostash --quiet
        and git -C $src push --quiet
        and echo "chs: pushed $ahead commit(s) to "(git -C $src remote get-url origin)
    else
        echo "chs: remote up to date"
    end
end
