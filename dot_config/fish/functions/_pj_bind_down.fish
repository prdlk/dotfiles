function _pj_bind_down --description "down arrow: pj tv cable on an idle empty prompt, else fish's down-or-search"
    # Mirror of atuin's up binding (atuin owns up, this owns down). Everything
    # that legitimately needs the arrow keys keeps them:
    #   - non-empty buffer  → multiline cursor movement / forward history search
    #   - paging mode       → tab-completion pager navigation (tab on an empty
    #                         line opens the pager with an empty buffer)
    #   - search mode       → history-search navigation
    # down-or-search is fish's own input function, called as a command exactly
    # the way atuin's _atuin_bind_up calls up-or-search.
    set -l buf (commandline | string collect)
    if test -n "$buf"; or commandline --paging-mode; or commandline --search-mode
        down-or-search
        return
    end

    # _pj_bind runs ~/.local/bin/pj (also ctrl-p), which opens the `pj` tv
    # cable. --quiet (PJ_QUIET) keeps it silent when the tree has no task
    # source at all, so down is a no-op outside projects instead of printing
    # an error per press.
    _pj_bind --quiet
end
