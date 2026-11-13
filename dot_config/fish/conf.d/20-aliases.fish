# Aliases — generated from .chezmoidata/aliases.yaml (shared with bash/zsh
# via ~/.config/shell/aliases.sh). Add shell-agnostic aliases in the YAML;
# fish-only bits live below the generated block.

# Editors / file managers
alias e nvim
alias vim nvim
alias e.f 'cd ~/.local/share/chezmoi/dot_config/fish && yazi'
alias e.h 'cd ~/.local/share/omarchy-desktop/dot_config/hypr && yazi'
alias e.k 'yazi ~/.config/kitty'
alias e.n 'yazi ~/.local/share/chezmoi/dot_config/niri'
alias e.y 'yazi ~/.config/yazi'
alias e.t 'nvim ~/.config/tmux/tmux.conf'
alias e.v 'yazi ~/.config/nvim/lua'

# Bun
alias br 'bun run'
alias br.d 'bun run dev'
alias br.b 'bun run build'
alias br.t 'bun run test'
alias bi 'bun install'
alias bg 'bun install -g'
alias bx 'bunx'

# Quick directory jumps
alias cdc 'cd ~/.config && yazi'
alias ,, 'cd ~/.local/share/chezmoi && yazi'
alias cdk 'cd ~/Documents/Knowledge && obsidian'
alias cdl 'cd ~/.local && yazi'
alias cds 'cd ~/.local/share/services && ls'
alias cdw 'cd ~/Downloads && yazi'

# Tools
alias hx helix
alias dd lazydocker
alias gg lazygit
alias ff 'exec fish'
alias npx bunx
alias sm 'sudo micro'
alias sd 'ssh prad@192.168.1.68'
alias oc opencode
alias dss 'dotstate sync'
alias fabric fabric-ai
alias bk bead-kanban
alias sua 'shelly upgrade-all -n'
alias lc leetcode
alias tk task
alias .. 'cd ..'

# Clipboard
if command -v wl-copy >/dev/null 2>&1
    alias cpy wl-copy
    alias pst wl-paste
else if command -v pbcopy >/dev/null 2>&1
    alias cpy pbcopy
    alias pst pbpaste
end

# q exits the shell; if this shell was spawned from yazi's own `q` bind
# (`shell "$SHELL" --block`), also tell that yazi to quit so exiting
# doesn't bounce back into the file manager.
function q --description 'exit (and quit parent yazi)'
    if set -q YAZI_ID; and command -q ya
        ya emit quit 2>/dev/null
    end
    exit
end

# Interactive-only: don't override `ls` for scripts.
if status is-interactive
    # `clear` is functions/clear.fish (kitty scrollback + bottom-pinned
    # prompt) — don't alias it here, an alias would shadow the autoload.
    alias celar clear
    alias claer clear
    if command -v eza >/dev/null 2>&1
        alias ls 'eza --icons'
    end
end
