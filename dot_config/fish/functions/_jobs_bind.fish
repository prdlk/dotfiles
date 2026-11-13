function _jobs_bind --description 'ctrl-z: fg the only job, or pick one from the jobs tv cable'
    # Only reached at the prompt: while a job owns the terminal, ctrl-z is the
    # tty's SIGTSTP and stops it. So ctrl-z toggles: suspend, then resume.
    # Records for the `jobs` cable: display, job id, process group (tabs).
    set -l recs
    for line in (jobs 2>/dev/null)
        set -l f (string split \t -- $line)
        string match -qr '^\d+$' -- $f[1]; or continue # header row
        set -a recs (printf '%%%s  %-8s %s\t%s\t%s' $f[1] $f[4] $f[5] $f[1] $f[2])
    end

    set -l id
    switch (count $recs)
        case 0
            return
        case 1
            set id (string split \t -- $recs[1])[2]
        case '*'
            set -lx TV_JOBS (mktemp)
            printf '%s\n' $recs >$TV_JOBS
            set id (_tv_inline jobs)
            rm -f $TV_JOBS
    end

    if test -z "$id"
        commandline -f repaint
        return
    end

    # Run fg as a command line, not from the binding: a binding runs with the
    # terminal still in fish's reader mode (extended keys on), so a job that
    # never had the terminal (started with &) would get ctrl-z/ctrl-c as escape
    # sequences instead of signals. The leading space keeps it out of history.
    # Whatever was typed comes back at the next prompt.
    set -l buf (commandline | string collect)
    if test -n "$buf"
        set -g __jobs_bind_buf $buf
        function __jobs_bind_restore --on-event fish_prompt
            functions -e __jobs_bind_restore
            commandline -r -- $__jobs_bind_buf
            set -e __jobs_bind_buf
        end
    end

    # Executing leaves "❯  __jobs_bind_fg 1" on the prompt line: step up and
    # erase it, and drop fg's "Send job … to foreground" (stderr of fg only;
    # the job keeps its own stdout/stderr).
    function __jobs_bind_fg
        printf '\033[A\033[2K\r' >/dev/tty
        fg %$argv[1] 2>/dev/null
    end
    commandline -r -- " __jobs_bind_fg $id"
    commandline -f execute
end
