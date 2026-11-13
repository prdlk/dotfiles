function cd --description 'cd with zoxide fallback, else builtin cd'
    if test (count $argv) -eq 0
        builtin cd $HOME
    else if test "$argv[1]" = '-'
        builtin cd -
    else if builtin cd $argv[1] 2>/dev/null
        # exact path resolved, nothing else to do
    else if type -q zoxide
        set -l target (zoxide query -- $argv[1] 2>/dev/null)
        if test -n "$target"
            builtin cd $target
        else
            builtin cd $argv[1]  # let builtin cd surface the real error
        end
    else
        builtin cd $argv[1]
    end

    type -q zoxide; and zoxide add $PWD
end
