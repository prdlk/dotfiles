# Start or reuse a single ssh-agent shared across shells.
# Respects an externally provided SSH_AUTH_SOCK (systemd unit, forwarding, keyring).
if status is-interactive; and not set -q SSH_AUTH_SOCK
    set -l env_file $HOME/.ssh/agent.env.fish
    test -r $env_file; and source $env_file

    # ssh-add exit 2 = no agent reachable (0/1 = agent alive)
    ssh-add -l >/dev/null 2>&1
    if test $status -eq 2
        ssh-agent -c | string replace -r '^setenv (\S+) (\S+);$' 'set -gx $1 $2' | string match -rv '^echo ' >$env_file
        source $env_file
    end
end
