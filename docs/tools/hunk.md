# Hunk

Hunk terminal diff viewer settings, used as the gh-dash diff pager.

[Hunk](https://github.com/modem-dev/hunk) is a review-first terminal diff viewer aimed at agent-authored changes. In this setup it is the diff pager for [gh-dash](github-cli.md#gh-dash).

| | |
| --- | --- |
| Sources | `dot_config/hunk/config.toml`, `dot_config/hunk/private_state.json` |
| Targets | `~/.config/hunk/config.toml`, `~/.config/hunk/state.json` (mode `0600`) |
| Packages | Not declared in `packages.yaml`; install hunk separately |

## config.toml

**~/.config/hunk/config.toml**

```toml
theme = "auto"
mode = "auto"
vcs = "git"
watch = false
exclude_untracked = true
line_numbers = true
tab_width = 4
wrap_lines = false
menu_bar = true
agent_notes = true
prompt_save_view_preferences = false
transparent_background = true
```

| Key | Value | Effect |
| --- | --- | --- |
| `theme` | `auto` | Picks a built-in theme to match the terminal. |
| `mode` | `auto` | Chooses split or stacked layout from the window width (alternatives: `split`, `stack`). |
| `vcs` | `git` | Git backend (alternatives: `jj`, `sl`). |
| `watch` | `false` | Does not reload on file changes. |
| `exclude_untracked` | `true` | Untracked files are left out of working-tree diffs. |
| `line_numbers` | `true` | Shows line numbers. |
| `tab_width` | `4` | Tab stops every 4 columns. |
| `wrap_lines` | `false` | Long lines are not wrapped. |
| `menu_bar` | `true` | Shows the top menu bar. |
| `agent_notes` | `true` | Shows agent notes when a review opens (off by default in hunk). |
| `prompt_save_view_preferences` | `false` | Does not ask to persist view changes. |
| `transparent_background` | `true` | Uses the terminal background instead of the theme's. |

No `[pager]` or per-command sections are set, so pager sessions use these top-level values.

## state.json

`private_state.json` is hunk's runtime state: the state-file `version` and `lastSeenCliVersion`, which hunk updates on its own. It holds no preferences. The `private_` prefix gives it mode `0600`.

## Integrations

**~/.config/gh-dash/config.yml**

```yaml
pager:
  diff: "hunk pager"
```

gh-dash pipes PR diffs into `hunk pager`. Plain `git diff` does not use hunk; it goes through diffnav (see [Git](git.md)).
