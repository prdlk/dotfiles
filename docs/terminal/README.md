# Terminal

Terminal emulators and multiplexers configured by the dotfiles.

kitty is the primary terminal. It runs in three modes: plain kitty (kitty owns splits and tabs), a tmux host, and a herdr host. Ghostty is a tmux-only terminal: every window attaches to tmux, and its `ctrl+shift` chords drive tmux.

kitty and ghostty are separate config repos cloned as externals (edit and commit in `~/.config/<app>`). tmux and tmux-palette are plain files in this repo, symlinked into `~/.config` and edited in place; only tpm is an external. Ghostty has no package on Ubuntu 24.04.

| Page | Source | What it covers |
| --- | --- | --- |
| [kitty](kitty.md) | external repo via `.chezmoiexternals/kitty.toml` | Main config, host configs (tmux, herdr), the goliath ssh window, kittens, custom tab bar |
| [Ghostty](ghostty.md) | external repo via `.chezmoiexternals/ghostty.toml` | tmux-only terminal: ctrl+shift chords → tmux, themes |
| [tmux](tmux.md) | local files: `dot_config/tmux/` and `dot_config/tmux-palette/`, plus the tpm external | Prefix, bindings, kitty-style tabs with Nerd Font icons, resurrect/continuum persistence |
| [herdr](herdr.md) | external repo via `.chezmoiexternals/herdr.toml`, plus `dot_config/herdr-nvim/` | Agent-aware multiplexer: keys, theme, plugins, Claude hook |

## Shared conventions

- Font: VictorMono Nerd Font everywhere.
- Background opacity `0.9`, no window decorations; the compositor provides blur.
- Prefix `ctrl+b` in tmux and herdr. kitty and Ghostty translate chords into the prefix byte `\x02` plus a key, so the same physical shortcut works across hosts.
- `ctrl+h/j/k/l` moves between panes across nvim, kitty, tmux, and herdr (vim-aware handoff at every layer).
