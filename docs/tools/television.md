# television

tv config symlinked from the repo, a transparent cyberdream theme, and the custom cables behind gho, pj, and ctrl-e in fish, zsh, and bash.

[television](https://github.com/alexpasmantier/television) (`tv`) is a fuzzy picker built on "cables": TOML files that define a source command, a preview, and actions. Every shell picker in the repo runs on a tv cable, with the same keys in fish, zsh, and bash.

| | |
| --- | --- |
| Source | [prdlk/television](https://github.com/prdlk/television) via `.chezmoiexternals/television.toml`: `config.toml`, `cable/*.toml`, `themes/cyberdream-transparent.toml` (selected), `themes/cherry-blossom-transparent.toml` (CherryBlossom, not selected) |
| Target | `~/.config/television/` |
| Install | Not listed in `.chezmoidata/packages.yaml`; install separately |

`~/.config/television` is a `git-repo` checkout (pulled `--ff-only` every 168h), so edits apply immediately; commit and push them from there. `cable/` holds tv's stock cables plus the repo's own and overridden ones.

## config.toml

The UI is minimal: no borders, a hidden status bar, and padding in place of frames.

| Key | Value |
| --- | --- |
| `default_channel` | `files` |
| `ui.theme` | `cyberdream-transparent` |
| `ui.input_bar` | position `top`, prompt `❯`, `border_type = "none"`, padding left 1, right 1, bottom 1 |
| `ui.status_bar.hidden` | `true` (<kbd>f12</kbd> toggles it) |
| `ui.results_panel` | `border_type = "none"`, padding left 1, right 1 |
| `ui.preview_panel` | `size = 50`, `scrollbar = false`, `border_type = "none"`, padding left 2, right 1 |
| `ui.help_panel.hidden` | `true` |

tv 0.15 has no config key for inline mode (`--inline` and `--height` are CLI-only), so every call site passes `--inline`: `gho` (`tv ghq-repos --inline`), `pj` (`tv pj --inline …`), <kbd>ctrl-e</kbd> (`tv git-files --inline`), and bash <kbd>ctrl-t</kbd> (`tv --autocomplete-prompt … --inline`). Actions that re-exec tv pass it too: `files` (`tv files .. --inline`), `dirs` (`tv dirs .. --inline`), and `channels` (`tv {} --inline`). `tv --inline` opens on the line below the prompt and leaves the cursor there on exit; the shell key bindings move the prompt back ([fish](../shell/fish.md#key-bindings), [bash and zsh](../shell/bash-zsh.md)).

A channel that sets its own `[ui.preview_panel]` replaces the whole table with tv's defaults (rounded border, scrollbar). The stock cables that override it (`alias`, `cargo-commands`, `crontab`, `env`, `fonts`, `gh-issues`, `journal`, `man-pages`, `npm-scripts`, `opencode-sessions`, `ports`, `tea-issues`, `tea-prs`, `text`, `todo-comments`) therefore repeat `border_type = "none"`, `scrollbar = false`, and padding left 2, right 1.

Global keys added on top of the defaults:

| Key | Action |
| --- | --- |
| <kbd>ctrl-e</kbd> | `actions:edit`: the channel's `edit` action |
| <kbd>ctrl-h</kbd> | `actions:goto_parent_dir`; the help panel loses <kbd>ctrl-h</kbd> |
| <kbd>end</kbd> | `go_to_input_end` (unchanged) |

## Theme

`themes/cyberdream-transparent.toml` is a separate file because tv 0.15's builtin `cyberdream` shadows a user theme of the same name and paints an opaque `#16181a` background. This theme omits `background`, so kitty's translucent background shows through (tv 0.15 rejects `background = 'none'`).

| Key | Color |
| --- | --- |
| `border_fg` | `#3c4048` |
| `text_fg`, `input_text_fg`, `result_value_fg` | `#ffffff` |
| `dimmed_text_fg` | `#7b8496` |
| `result_name_fg` | `#5ea1ff` |
| `result_line_number_fg` | `#f1ff5e` |
| `match_fg` | `#5ef1ff` |
| `selection_fg` / `selection_bg` | `#5eff6c` on `#3c4048` |
| `preview_title_fg` | `#ffaecf` |
| `result_count_fg` | `#ffbd5e` |
| `channel_mode_bg` | `#5ef1ff` on `#16181a` |
| `remote_control_mode_bg` | `#5eff6c` on `#16181a` |
| `action_picker_mode_bg` | `#bd5eff` on `#16181a` |

## Sorting

Every custom cable except `agents` (a fixed list, see [agents](#agents)), `omp-sessions` (sorted by [`omp-session`](../shell/scripts.md#omp-session) itself), and `jobs` (fish's job order) pipes its source through [`mtime-sort`](../shell/scripts.md#mtime-sort), which orders lines newest-first by the mtime of the path in the line's last tab-separated field (`--repo` stats `<path>/.git/index` first). tv then ranks match quality and frecency on top of that order. All custom cables set `shell = "bash"`, because `$SHELL` is fish.

## Custom cables

| Cable | File | Opened by |
| --- | --- | --- |
| [`ghq-repos`](#ghq-repos) | `cable/ghq-repos.toml` | <kbd>ctrl-o</kbd> (`gho`) |
| [`git-files`](#git-files) | `cable/git-files.toml` | <kbd>ctrl-e</kbd> |
| [`pj`](#pj) | `cable/pj.toml` | <kbd>ctrl-p</kbd>, <kbd>down</kbd> on an empty prompt (`pj`) |
| [`files`](#files) | `cable/files.toml` | `tv`, <kbd>ctrl-t</kbd> autocomplete |
| [`obsidian`](#obsidian) | `cable/obsidian.toml` | `tv obsidian` |
| [`agents`](#agents) | `cable/agents.toml` | `tv agents` |
| [`omp-sessions`](#omp-sessions) | `cable/omp-sessions.toml` | `tv omp-sessions`, <kbd>ctrl-a</kbd> (`omp-session`) when it has nothing to resume |
| [`jobs`](#jobs) | `cable/jobs.toml` | <kbd>ctrl-z</kbd> in fish (`_jobs_bind`) with two or more background jobs |
| [`kitty-days`](#kitty-days) | `cable/kitty-days.toml` | `tv kitty-days` |

The keys are bound in fish (`fish_user_key_bindings.fish`), zsh (`keybinds.zsh`), and bash (`keybinds.bash`); bash has no <kbd>ctrl-a</kbd> binding, and <kbd>ctrl-z</kbd> is fish only. See [fish](../shell/fish.md#key-bindings) and [bash and zsh](../shell/bash-zsh.md).

### ghq-repos

Entries are `name<TAB>path`: tv shows and matches the name and prints the path. <kbd>ctrl-s</kbd> cycles between the two sources.

| Source | Entries | Sort |
| --- | --- | --- |
| Repos | `ghq list` under `ghq root`, plus two checkouts outside it: the chezmoi source (`~/.local/share/chezmoi`) and the nvim config (`~/.config/nvim`) as `github.com/prdlk/nvim`. Those two win over a ghq clone with the same name | `mtime-sort --repo` |
| Vaults | Every directory under `~/Documents/Obsidian` (depth 3) that contains `.obsidian`, named relative to that directory | `mtime-sort` |

**Preview.** Two commands; <kbd>ctrl-f</kbd> cycles. The default is the commit graph for git directories: `git log --graph --all`, newest 300 commits, as short hash, relative date, subject and refs. The second is `onefetch --no-art`. Non-git directories show `eza --tree --level 2` (falling back to `ls -la`) in both.

[serie](https://github.com/lusingander/serie) cannot draw inside the preview pane: it is a fullscreen TUI that paints its graph with kitty images and has no print mode. <kbd>ctrl-g</kbd> opens it instead.

| Key | Action |
| --- | --- |
| <kbd>enter</kbd> | Print the path. The `gho` function cds into it, clears, and runs `onefetch` in git repos |
| <kbd>ctrl-e</kbd> | `edit`: `cd <path> && nvim .` on `/dev/tty` |
| <kbd>ctrl-b</kbd> | `browse`: `cd <path> && gop` in fork mode, so tv stays open ([gop](../shell/scripts.md#gop)) |
| <kbd>ctrl-g</kbd> | `history`: `serie` on `/dev/tty` in fork mode for git directories; <kbd>q</kbd> returns to the picker |

**Needs:** `ghq`, `fd`, `git`, `serie`, `onefetch`, `mtime-sort`.

### git-files

| Source | Entries |
| --- | --- |
| Tracked | `git ls-files` of the whole repo (from the toplevel), or `fd -t f` outside a repo |
| All | `fd -t f -H -E .git` |

Both are sorted with `mtime-sort`. The preview is `bat -n` with `BAT_THEME=ansi`. <kbd>enter</kbd> runs `edit`: `nvim {}` on `/dev/tty`.

**Needs:** `git`, `fd`, `bat`, `mtime-sort`.

### pj

Source `pj --list`; tv shows the display column. The preview runs `pj --preview` in the global 50% panel, and <kbd>enter</kbd> runs `pj --run`. Running `pj` scans the project and opens this cable with its own records. See [pj](../shell/scripts.md#pj).

**Needs:** `pj`, `mtime-sort`.

### files

Overrides tv's stock `files` cable. Sources `Default` (`fd -t f`) and `Hidden` (`fd -t f -H`), both piped through `mtime-sort`. The `edit` action opens the selection in `nvim` on `/dev/tty`, so it also works from <kbd>ctrl-t</kbd>, where the shell captures tv's stdout.

**Needs:** `fd`, `bat`, `mtime-sort`.

### obsidian

Entries are `name<TAB>path` for every directory under `~/Documents/Obsidian` (depth 3) that contains `.obsidian`, named relative to that directory (nested vaults show as `Research/Sonr`) and sorted with `mtime-sort`. The preview is `eza --tree --level 2`.

| Key | Action |
| --- | --- |
| <kbd>enter</kbd> | `open`: `xdg-open obsidian://open?path=<path>`, detached with `setsid -f` because the generic `xdg-open` stays in the foreground |
| <kbd>ctrl-e</kbd> | `edit`: `cd <path> && nvim .` |

`obsidian://open?path=` only resolves vaults listed in `~/.config/obsidian/obsidian.json`, and Obsidian reads that file once at startup and rewrites it from memory. So when the vault is not listed and Obsidian is closed, `open` adds `{path, ts}` under a random 16-hex id first. When Obsidian is running, it sends a notification and opens the vault switcher (`obsidian://choose-vault`) for **Open folder as vault**.

**Needs:** `fd`, `jq`, `eza`, `obsidian`, `xdg-open`, `mtime-sort`.

### agents

The source is a table of known agent CLIs in the cable, `binary|launch command|description`, kept in table order (`omp` first). A row is listed only when `command -v <binary>` resolves, so agents appear and disappear as they are installed. Entries are `<name  description><TAB><launch command><TAB><binary>`; the description is part of the matched text, so `openai` finds `codex`.

| Agents in the table | Launch |
| --- | --- |
| `omp`, `claude`, `codex`, `opencode`, `crush`, `pi`, `cursor-agent`, `copilot`, `gemini`, `agy`, `grok`, `muse`, `ori`, `hermes`, `amp`, `droid`, `qwen`, `kimi`, `goose`, `aider`, `auggie`, `kiro-cli`, `cn`, `fractal` | The binary, except `claude --dangerously-skip-permissions` (same as `ai`) |

The preview shows the launch command, the path on `PATH`, its `readlink -f` target, and, for the `~/.local/bin` wrappers that install the agent through mise on first run, the mise tool. It never runs the agent, since some wrappers take seconds to answer `--version`.

<kbd>enter</kbd> runs `launch` in execute mode: tv exits and the launch command runs in its place, in the current directory.

**Needs:** nothing beyond the agents themselves.

### omp-sessions

Source `omp-session --list`: the omp sessions of the current git repo, newest first, as `<age> <branch> <title>[ · <subdir>]<TAB><session file>`. tv shows and matches the display column, so typing a branch name filters to its sessions. The branch is the one HEAD was on when the session was last written, from the reflog; see [omp-session](../shell/scripts.md#omp-session).

The preview runs `omp-session --preview`: title, last-write time and cwd, then the text of every user and assistant message. <kbd>enter</kbd> runs `resume` in execute mode, `omp-session --resume <file>`, which `exec`s `omp --resume <file>`. <kbd>ctrl-n</kbd> runs `new`, `omp-session --new`, which starts a fresh `omp` session. In this cable <kbd>ctrl-n</kbd> no longer moves to the next entry; <kbd>down</kbd> and <kbd>ctrl-j</kbd> still do.

**Needs:** `omp-session`, `omp`.

### jobs

The current fish shell's background jobs, stopped or running, newest first. tv runs as a child process and cannot read the shell's job table, so `_jobs_bind` ([fish](../shell/fish.md#key-bindings)) writes it to a temp file named by `$TV_JOBS` and the source just `cat`s that file; opened any other way the list is empty. Entries are `%<id>  <state>  <command><TAB><id><TAB><pgid>`; <kbd>enter</kbd> prints the id and the binding runs `fg %<id>`.

The preview finds the job's processes by process group (procps `ps -g` matches sessions, so it filters `ps -e -o pgid,pid`) and shows the first process's cwd and start time, then `ps --forest` with PID, STAT (`T` = stopped), elapsed time, CPU, RSS, and arguments. The preview script avoids `{`/`}` because tv would parse them as templates and leave `{split:…}` unexpanded.

| Key | Action |
| --- | --- |
| <kbd>enter</kbd> | Print the job id; `_jobs_bind` runs `fg` on it |
| <kbd>ctrl-d</kbd> | `kill` then `reload_source`: SIGTERM to the job's process group, then SIGCONT so a stopped job receives it. Once the group is gone (polled up to 1 s) the row is removed from `$TV_JOBS`, so the reloaded list drops it; a job that ignores SIGTERM stays listed. Fish reports the termination at the next prompt |

**Needs:** `ps`, fish.

### kitty-days

Lists the daily kitty sessions that `~/.config/kitty/day_session.py` saves under `~/.local/share/kitty-sessions/<monday>/<day>.kitty-session` ([kitty daily sessions](../terminal/kitty.md#daily-sessions)). Entries are `<day>  <weekday>  week of <monday>  <n> tabs<TAB><session file>`, through `mtime-sort`. The preview parses the session file with an inline `python3` script (written without braces, which tv would treat as templates): each tab, then each window's cwd and the program it restores, with the last 6 lines of its saved scrollback in color.

| Key | Action |
| --- | --- |
| <kbd>enter</kbd> | `open`: `setsid -f kitty --session <file>`, a new kitty with that day's tabs, scrollback and programs. Past days are read-only snapshots; today's file comes back as the live day if no kitty owns it |
| <kbd>ctrl-e</kbd> | `edit`: the session file in `nvim` |

**Needs:** `kitty`, `python3`, `mtime-sort`.
