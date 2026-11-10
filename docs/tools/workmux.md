# workmux

workmux global config: one git worktree and one tmux session per agent, driven from the Workmux palette.

[workmux](https://workmux.dev) pairs each git worktree with a tmux target and starts an agent in it. Here every worktree gets its own tmux session (an omp window and an nvim window), and the [Workmux palette](../shell/scripts.md#workmux-palette) (tmux `prefix w`, or `ctrl+space` → Workmux) covers the lifecycle: open, new, close, merge, remove, and jumping to agents by status.

| | |
| --- | --- |
| Source | `dot_config/workmux/config.yaml` |
| Target | `~/.config/workmux/config.yaml` (symlink) |
| Packages | `workmux` under `packages.shared.mise` |
| Status tracking | omp extension `~/.omp/agent/extensions/workmux-status.ts` (in the [omp external](../chezmoi/externals-and-ignore.md)) |

## config.yaml

| Key | Value | Effect |
| --- | --- | --- |
| `nerdfont` | `true` | Nerd Font icons in workmux's own UI. |
| `mode` | `session` | Each worktree is a tmux session, so the session pill, Ghostty's window title, and the [Sessions palette](../shell/scripts.md#tmux-sessions) list it like any other session. |
| `window_prefix` | `"{project}/"` | Session names read `<repo>/<handle>`. |
| `worktree_dir` | `~/Work/{project}` | Worktrees land in `~/Work/<repo>/<handle>`, next to worktrunk's `~/Work/<repo>-<branch>`. |
| `base_branch` | `auto` | New branches start from the repo's main branch, not the branch the pane is on. |
| `agent` | `omp` | `<agent>` runs omp; it receives `-p`/`-P`/`-e` prompts and names branches for `add -A`. |
| `windows` | omp (focused), nvim | Two unnamed windows, so `automatic-rename-format` labels them like every other tab. |
| `status_format` | `false` | workmux leaves `window-status-format` alone; `tmux.conf` renders `#{@workmux_status}` itself (see [Window tabs](../terminal/tmux.md#window-tabs)). |

A `.workmux.yaml` in a repo overrides any of these.

## Agent status

The omp extension reports `working`, `waiting`, and `done`. workmux stores the icon in the window option `@workmux_status`, which the tab formats print after the label. The palette's Agents group reads `workmux status --all --json`.
