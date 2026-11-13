# PATH — runs for every shell (scripts need these too).
# ~/.local/bin comes first here: mise.run installs mise there (Ubuntu), and
# 40-tools.fish needs it before inir-path.fish (which also adds it) runs.
# ~/.cargo/bin is handled by rustup.fish.
fish_add_path $HOME/.local/bin

# Homebrew (macOS): formulae and casks from .chezmoidata/packages.yaml.
for brew in /opt/homebrew/bin/brew /usr/local/bin/brew
    if test -x $brew
        $brew shellenv fish | source
        break
    end
end

fish_add_path $HOME/.bun/bin
fish_add_path $HOME/.local/share/go/bin
fish_add_path $HOME/.maestro/bin
fish_add_path $HOME/.grok/bin
fish_add_path $HOME/.opencode/bin
fish_add_path -a $HOME/.foundry/bin

# Android SDK (relocated under ~/.local/share/android)
fish_add_path -a $HOME/.local/share/android/platform-tools
fish_add_path -a $HOME/.local/share/android/cmdline-tools/latest/bin
fish_add_path -a $HOME/.local/share/android/emulator
fish_add_path -a $HOME/local/share/pnpm

# pnpm
set -gx PNPM_HOME $HOME/.local/share/pnpm
fish_add_path $PNPM_HOME/bin
