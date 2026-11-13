function fish_user_key_bindings
    # Vi mode first: it rebinds the preset tables and (on first activation)
    # re-triggers this function via the fish_key_bindings handler, so custom
    # binds must come after it to land on top.
    fish_vi_key_bindings
    # No visual mode: `v` in normal mode (the only key that enters it) does
    # nothing.
    bind --preset -e -M default v

    # Vi mode types in `insert`; bind customs there AND in `default` (normal)
    # so the keys work regardless of mode.
    for mode in insert default
        # Keys owned by kitty.conf never reach fish and are NOT bound here:
        #   ctrl-g → lazygit overlay, ctrl-y → yazi vsplit,
        #   ctrl-h/j/k/l → vim-aware split nav (pass_keys.py).
        # ctrl-e: tv git-files (bat preview, enter opens nvim). ctrl-o, ctrl-p
        # and down also open tv cables — same keys in zsh and bash. tv runs
        # --inline below the prompt; _tv_inline/_gho_bind/_pj_bind put the
        # prompt back in place (or below any output) afterwards. ctrl-a:
        # omp-session resumes or starts omp for the repo (same in zsh); when it
        # opens the omp-sessions cable and it is cancelled, it steps back up.
        # ctrl-n: always a new omp session.
        bind -M $mode ctrl-e 'nvim; commandline -f repaint'
        bind -M $mode ctrl-b purple repaint
        bind -M $mode ctrl-y clip-last

        bind -M $mode ctrl-o _gho_bind
        bind -M $mode ctrl-p _pj_bind
        bind -M $mode ctrl-a 'omp-session; commandline -f repaint'
        bind -M $mode ctrl-n 'omp; commandline -f repaint'
        bind -M $mode ctrl-w 'atuin ai inline; commandline -f repaint'
        # ctrl-z at the prompt: fg the only background job, or pick one from
        # the jobs tv cable when there are several (_jobs_bind).
        bind -M $mode ctrl-z _jobs_bind

        # Arrow keys: atuin owns up (bound from config.fish, survives the
        # fish_vi_key_bindings reset above because that only erases presets),
        # down opens the pj tv cable — but only on an idle, empty prompt; see
        # _pj_bind_down.
        bind -M $mode down _pj_bind_down

        # ctrl-f: yazi (cd's to yazi's exit dir on quit).
        bind -M $mode ctrl-f 'yy; commandline -f repaint'
        bind -M $mode ctrl-g 'lazygit; commandline -f repaint'

        # ctrl-c routes through the clear wrapper (kitty scrollback + prompt
        # pinned to the bottom) AND wipes any text typed on the command line.
        bind -M $mode ctrl-c 'commandline -r ""; clear; commandline -f repaint'

        # ctrl-q mirrors ctrl-d's preset (`exit`) — quit the shell.
        bind -M $mode ctrl-q exit
    end
end
