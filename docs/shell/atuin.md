# atuin

Shell history search with a daemon, directory-scoped up-arrow, tmux popups, a CherryBlossom theme, and the atuin AI inline command generator.

[atuin](https://atuin.sh) replaces shell history search in fish, bash, and zsh. It also provides `atuin ai inline`, a natural-language command generator that the fish config binds to keys.

| Source (repo) | Target | Notes |
| --- | --- | --- |
| `dot_config/atuin/private_config.toml` | `~/.config/atuin/config.toml` | `private_`: written as a regular `0600` file, not a symlink |
| `dot_config/atuin/themes/cherry-blossom.toml`, `dot_config/atuin/themes/cyberdream.toml` | `~/.config/atuin/themes/*.toml` | symlinks |

chezmoi runs in symlink mode, but `private_` files are written as real files, so edits to `~/.config/atuin/config.toml` do not reach the repo on their own. Copy them back with `chezmoi re-add` (or `czs`, see [fish](fish.md#functions)). None of the files are templates, and they apply on every role.

## Installation

`atuin` is listed in `.chezmoidata/packages.yaml` for pacman, and the shells use that package's binary (`/usr/bin/atuin` on Arch). Each shell runs `atuin init` only if `atuin` is on `PATH`.

> [!NOTE]
> **No standalone install**
>
> An earlier setup also kept atuin's standalone installer layout in `~/.atuin/bin` (with a cargo-dist `atuin-receipt.json` in the repo) and prepended it to `PATH` from `conf.d/atuin.env.fish` and `. "$HOME/.atuin/bin/env"` in `.bashrc`/`.zshrc`. That copy fell behind the package: the daemon, from the newer package, migrated the history database, and every command the shells ran through the old binary failed with `migration 20260818000000 was previously applied but is missing in the resolved migrations`. The standalone install, its receipt, and the `PATH` lines are gone. Do not reinstall atuin with its curl installer on this setup.

## Shell integration

| Shell | Where | What |
| --- | --- | --- |
| fish | `config.fish`, interactive only | `atuin init fish \| source`, and a copy of the `?` binding (atuin 18.21 removed the `atuin ai init` command that used to emit it) |
| fish | `functions/fish_user_key_bindings.fish` | <kbd>ctrl-w</kbd> runs `atuin ai inline` |
| bash | end of `~/.bashrc` | `eval "$(atuin init bash)"` |
| zsh | end of `~/.zshrc` | `eval "$(atuin init zsh)"` |

In fish, `40-tools.fish` sources hishtory before atuin, but atuin's init runs later in `config.fish` and takes <kbd>ctrl-r</kbd>. zsh also loads `suv init zsh` (suvadu) if installed.

### Key bindings

| Key | Shells | Action |
| --- | --- | --- |
| <kbd>ctrl-r</kbd> | all | Interactive search (`_atuin_search`) |
| <kbd>up</kbd> | all | Search opened from the up arrow. `filter_mode_shell_up_key_binding = "directory"` limits it to history from the current directory |
| <kbd>?</kbd> | fish, vi normal mode | On an empty buffer, runs `atuin ai inline --hook` |
| <kbd>ctrl-w</kbd> | fish, insert and normal mode | `atuin ai inline`, then repaint |
| <kbd>ctrl+shift+p</kbd> | kitty | [`atuin-pick`](scripts.md#atuin-pick): directory-filtered search in a split, running the pick in a fresh fish |

Under tmux, atuin's `[tmux]` settings open the search in a tmux popup (80% wide, 60% tall) instead of inline.

## AI inline

Commit `a82921c` ("add Atuin AI inline integration and keybinding") added the <kbd>ctrl-w</kbd> bind to `fish_user_key_bindings.fish`, `atuin ai init fish | source` to `config.fish`, and a copy of the `_atuin_ai_question_mark` function that command printed, with `bind "?" _atuin_ai_question_mark`. atuin 18.21 removed `atuin ai init`, so `config.fish` keeps only the copied function and binding; `atuin ai inline --hook` still works.

The config also sets `[ai] enabled = true`.

`_atuin_ai_question_mark` works like this:

- **Buffer empty (or just `?`):** clears the line, prints OSC `133;C` to `/dev/tty` to close the terminal's semantic prompt zone (so shell-integrated terminals do not erase the TUI during a prompt reflow), then runs `atuin ai inline --hook` with stdout and stderr swapped. The TUI draws on the terminal, and the result comes back tagged:

  | Output prefix | Effect |
  | --- | --- |
  | `__atuin_ai_print__:` | Print the text, repaint |
  | `__atuin_ai_cancel__` | Repaint only |
  | `__atuin_ai_execute__:` | Put the command on the line and execute it |
  | `__atuin_ai_insert__:` | Put the command on the line for editing |
  | anything else, non-empty | Put it on the line for editing |

- **Buffer not empty:** inserts a literal `?` under emacs bindings. Under vi or hybrid bindings, which this config uses, it does nothing.

`bind "?"` in `config.fish` has no `-M` flag, so it applies to fish's `default` mode, which is vi **normal** mode here. In insert mode <kbd>?</kbd> types a question mark. To ask for a command, press <kbd>Esc</kbd> and then <kbd>?</kbd> on an empty line, or press <kbd>ctrl-w</kbd> from either mode. The <kbd>ctrl-w</kbd> bind calls `atuin ai inline` without `--hook` and replaces fish's default <kbd>ctrl-w</kbd> word deletion.

bash and zsh have no AI binding.

## Configuration

`config.toml` is atuin's generated sample with a few keys set. The rest are commented-out defaults. The settings that take effect:

| Key | Value | Effect |
| --- | --- | --- |
| `filter_mode_shell_up_key_binding` | `"directory"` | Up-arrow search shows only the current directory's history |
| `dotfiles.enabled` | `true` | Enables atuin's dotfiles feature (aliases and vars managed by atuin) |
| `daemon.enabled` | `true` | Uses the background daemon |
| `daemon.autostart` | `true` | atuin starts and manages the daemon itself |
| `pty_proxy.enabled` | `false` | `atuin init` does not re-exec the shell inside `atuin pty-proxy` |
| `theme.name` | `"cherry-blossom"` | Loads `themes/cherry-blossom.toml` |
| `tmux.enabled` | `true` | Search opens in a tmux popup when inside tmux (tmux 3.2+) |
| `tmux.width` / `tmux.height` | `"80%"` / `"60%"` | Popup size |
| `ai.enabled` | `true` | Enables `atuin ai` |

No sync server, key, or session is configured in the repo. atuin keeps its encryption key and session under `~/.local/share/atuin`, outside chezmoi, and uses the default sync server.

> [!WARNING]
> **Misplaced keys**
>
> Several keys sit after the `[dotfiles]` table header, so TOML puts them inside `[dotfiles]` rather than at the top level, and atuin ignores them. `atuin config get --resolved` confirms it:
>
> | Key as written | Intended | Resolved |
> | --- | --- | --- |
> | `search_mode` | `"daemon-fuzzy"` | `fuzzy` |
> | `enter_accept` | `true` | `false` |
> | `workspaces` | `true` | `false` |
> | `style` | `"auto"` | `compact` |
> | `inline_height_shell_up_key_binding` | `20` | unknown key |
> | `auto_sync` | `true` | `true` (the default) |
> | `update_check` | `true` | `true` (the default) |
>
> `syntax_highlight = true` has the same problem: it sits under `[ai]`, while the comment block above it documents the `[ui]` table.
>
> To apply these settings, move the keys above `[dotfiles]` (and `syntax_highlight` under `[ui]`) in `dot_config/atuin/private_config.toml`.

## Theme

`themes/cherry-blossom.toml` defines the selected theme, from the CherryBlossom palette shared with Ghostty, tmux, lazygit, and omp:

| Key | Color |
| --- | --- |
| `AlertInfo` | `#a78266` |
| `AlertWarn` | `#ae825f` |
| `AlertError` | `#bf615d` |
| `Annotation` | `#a6958f` |
| `Guidance` | `#8f9aa0` |
| `Important` | `#cf716f` |
| `Title` | `#cf716f` |
| `Muted` | `#a6958f` |
| `SyntaxCommand` | `#cf716f` |
| `SyntaxFlag` | `#a78266` |
| `SyntaxString` | `#a6b084` |
| `SyntaxVariable` | `#c17e4a` |
| `SyntaxOperator` | `#ad6756` |
| `SyntaxComment` | `#a6958f` |

`themes/cyberdream.toml` is still shipped (the palette shared with [fish](fish.md#theme) and [Starship](starship.md#palette)) but not selected.
