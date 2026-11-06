# AI agents

The shared agent skill library and the shell entry points for coding agents.

The repo manages the agent skill library only. Claude Code (`~/.claude`) and omp (`~/.omp`) configs are not in this repo. omp, opencode, and crush are global mise tools (`packages.shared.mise`, installed by [15-tools](../chezmoi/scripts.md#15-tools)) and are updated by topgrade's `mise upgrade`; no other agent CLI is installed by chezmoi.

- [Skills](skills.md): Every agent skill in [prdlk/skills](https://github.com/prdlk/skills), installed into `~/.agents/skills` and `~/.claude/skills` by an apply script.

## Pages

| Page | Source in repo | Target in `$HOME` | Covers |
| --- | --- | --- | --- |
| [Skills](skills.md) | `.chezmoidata/skills.yaml`, `.chezmoiscripts/run_onchange_after_25-skills.sh.tmpl` | `~/.agents/skills/`, `~/.claude/skills/` | The prdlk/skills source and skill list; installed by the Skills CLI, not vendored |

## Shell entry points

- `ai` (fish function) opens a `gum choose` picker over `claude`, `opencode`, `codex`, `hermes`, and `fractal`. Picking `claude` runs `claude --dangerously-skip-permissions`; the others run the binary of the same name. See [fish](../shell/fish.md).
- <kbd>Ctrl</kbd> <kbd>A</kbd> runs [`omp-session`](../shell/scripts.md#omp-session) from the fish and zsh prompt: on the default branch it resumes a session written in the last 3 hours, else opens the `omp-sessions` television cable; on any other branch it resumes that branch's newest session or starts a new one. `tv agents` still lists every installed agent CLI ([television](../tools/television.md#agents)).
- <kbd>Ctrl</kbd> <kbd>N</kbd> starts a new omp session from the fish and zsh prompt, skipping every resume rule. Inside the `omp-sessions` cable, <kbd>ctrl-n</kbd> does the same instead of resuming the selected session.
- `launch_omp_livediff_overlay` and `lc-elir` are omp helpers in `~/.local/bin`; see [scripts](../shell/scripts.md).
