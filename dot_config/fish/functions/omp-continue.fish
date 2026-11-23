# Pick up where you left off: nvim restores this worktree/branch session, omp
# resumes this directory's latest session (`omp --continue`) in a pane on the
# right, and the treemux file tree opens on the left. The layout is nvim's
# :OmpContinue (~/.config/nvim/lua/config/omp_term.lua); it needs tmux, so
# outside tmux this starts a new tmux session for it.
function omp-continue --description 'nvim session + omp --continue pane + treemux tree'
    if not set -q TMUX
        tmux new-session -c $PWD 'nvim +OmpContinue'
        return
    end
    nvim +OmpContinue
end
