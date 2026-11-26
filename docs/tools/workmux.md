# workmux

workmux global config: one git worktree and one tmux session per agent, driven from the Workmux palette.

[workmux](https://workmux.dev) pairs each git worktree with a tmux target and starts an agent in it. Here every worktree gets its own tmux session laid out like fish's `omp-continue` (`ctrl-a`): nvim with omp on its right and the treemux file tree on its left, in one window. The [Workmux palette](../shell/scripts.md#workmux-palette) (tmux `prefix w`, `ctrl+s` in the agent sidebar, or `ctrl+space` → Workmux) covers the lifecycle: open, new, close, merge, remove, and jumping to agents by status.

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
| `auto_name.system_prompt` | rules below | Keeps `add -A` branch names short (see [Branch names](#branch-names)). |
| `windows` | one window: `nvim +OmpContinue`, `<agent>` split right at 30% | workmux's `<agent>` pane is omp, so it still gets the prompt (`-p`/`-P`/`-e`, the palette's New item) and the status hooks. The nvim pane then runs `omp-continue`'s layout: `:OmpContinue` reuses that omp pane and opens the treemux sidebar on the left; focus ends in omp, and the window ends up tree 20%, nvim 50%, omp 30%. `:OmpContinue` would split off its own `omp --continue` if no omp were in the window yet, and nvim starts first, so its pane waits up to 5 s for the agent pane's `omp`. tmux's [even-out hooks](../terminal/tmux.md#panes) spread the two panes evenly while workmux builds the window, so the pane then resizes omp back to 30% and marks it `@treemux-keep-width` (which keeps the hooks off the window) before `exec nvim +OmpContinue`. The fish function itself can't be called: workmux types pane commands into tmux's `default-shell`, `/bin/sh`. Unnamed, so `automatic-rename-format` labels the tab |
| `status_format` | `false` | workmux leaves `window-status-format` alone; `tmux.conf` renders `#{@workmux_status}` itself (see [Window tabs](../terminal/tmux.md#window-tabs)). |

A `.workmux.yaml` in a repo overrides any of these.

## Agent status

The omp extension reports `working`, `waiting`, and `done`. workmux stores the icon in the window option `@workmux_status`, which the tab formats print after the label. The palette's Agents group reads `workmux status --all --json`.

## Branch names

`workmux add -A` (the palette's New item) pipes the task to `omp --no-session -p` with `auto_name.system_prompt`. The name becomes the worktree directory, the tab label (cut at 27 characters), and the session `<repo>/<name>` in the session pill (`status-left-length 30`), so the prompt asks for kebab-case, 1–2 words (3 if needed), at most 16 characters, the subject rather than the method, filler words dropped, common short forms (`auth`, `config`, `nav`, `anim`, …), and no `feat/`-style prefixes. Checked with `--dry-run`: a menu-bar tap/expand animation task → `menubar-expand`, a macOS codesigning CI failure → `codesign-fix`, plugin API docs → `plugin-api-docs`. The model can still overshoot; the prompt is guidance, not a hard cap.
