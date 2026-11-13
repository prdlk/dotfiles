#!/bin/sh
# On Omarchy machines, apply the Omarchy desktop layer
# (https://prad.codes/env/omarchy-desktop) after every apply of these
# dotfiles: clone it the first time, apply it every time. It is a separate
# chezmoi source driven through ~/.local/bin/chezmoi-desktop (applied just
# before this runs). Elsewhere (macOS, Ubuntu, Arch without Omarchy) this
# does nothing. The checkout is never pulled here: commit and push in it, as
# in this repo.
set -eu

command -v omarchy >/dev/null 2>&1 || exit 0

desktop="$HOME/.local/bin/chezmoi-desktop"
if [ -d "$HOME/.local/share/omarchy-desktop/.git" ]; then
    "$desktop" apply
else
    "$desktop" init --apply https://prad.codes/env/omarchy-desktop.git
fi
