# Scripts

The shell-agnostic executables in ~/.local/bin — usage, behavior, and dependencies for each.

`dot_local/bin/` holds standalone `sh`, `bash`, and `python3` executables. The `executable_` prefix is a chezmoi attribute that sets the executable bit and is dropped from the target name, so `dot_local/bin/executable_pj` becomes `~/.local/bin/pj`. bash, zsh, and fish all put `~/.local/bin` on `PATH`, so every shell runs the same implementation.

This page covers the general-purpose scripts. The desktop scripts in the same directory are documented with their compositor:

- `cp-appid`: fzf-pick a `.desktop` app ID and copy it with `wl-copy`. Desktop roles only.
- `omarchy-*`: [Hyprland](../desktop/hyprland.md)

## Why some helpers are shell functions

A script runs as a child process, and a child cannot change its parent shell's working directory or read the parent's in-memory history. Helpers that need to do either are therefore defined as shell functions, ported three times: `fish/functions/*.fish`, `bash/functions/*.bash`, and `zsh/functions/*.zsh`.

| Helper | Why it must be a function |
| --- | --- |
| `yy` (and fish's `y`) | cds into the directory yazi exited in |
| `c` | cds when given an argument |
| `cd` | Replaces the `cd` builtin with a zoxide fallback |
| `ghg`, `ghn`, `gho` | cd into a repo that was picked or cloned |
| `clip-last` | Reads the shell's own history (`$history[1]` in fish, `fc` in bash/zsh) |

For `ghg` and `ghn`, the work lives in a script that prints a directory on stdout (and everything else on stderr). The shell function captures that path and cds into it. `ghg`'s script is named `ghg-clone` because an unrelated cargo binary already uses the name `ghg`. `gho` has no script: the function reads the path from `tv ghq-repos` ([television](../tools/television.md#ghq-repos)).

Several scripts below also exist as fish functions of the same name (`ai`, `c2p`, `extract_agents`, `fab`, `gdc`, `git-summary`, `lc-elir`, `mdcp`, `mdp`, `launch_omp_livediff_overlay`, `gh-sonr-org-migrate`). In fish the function runs instead of the script. Both versions behave the same. See [fish functions](fish.md#functions).

## Overview

| Script | Language | One line |
| --- | --- | --- |
| [`ai`](#ai) | sh | Pick an AI CLI with gum and launch it |
| [`atuin-pick`](#atuin-pick) | python3 | atuin history picker for a kitty or tmux split |
| [`brave-new-tab`](#brave-new-tab) | sh | Open a URL in a new Brave Origin tab |
| [`c2p`](#c2p) | sh | code2prompt with an fzf-picked template |
| [`extract_agents`](#extract_agents) | sh | Copy all `AGENTS.md` files into a directory tree |
| [`fab`](#fab) | sh | fzf picker for Fabric patterns |
| [`free-router`](#free-router) | bun | Run the freellmapi LLM router on `localhost:$FREE_ROUTER_PORT` |
| [`gdc`](#gdc) | sh | Discard all git changes after confirmation |
| [`gh-sonr-org-migrate`](#gh-sonr-org-migrate) | bash | Consolidate `*sonr*` GitHub orgs into `sonr-io` |
| [`ghg-clone`](#ghg-clone) | sh | `ghq get` and print the clone path |
| [`ghn`](#ghn) | sh | Create a private repo, clone it, print the path |
| [`git-summary`](#git-summary) | sh | Aggregate a repo's `AGENTS.md` files with code2prompt |
| [`gop`](#gop) | sh | Open the current repo's web page |
| [`kitty-day-save`](#kitty-day-save) | bash | Save kitty's daily session right before shutdown/reboot |
| [`launch_omp_livediff_overlay`](#launch_omp_livediff_overlay) | sh | omp overlay plus a livediff split in kitty |
| [`lc-elir`](#lc-elir) | sh | Run `/leetcode-eli5` via omp on picked solutions |
| [`mandible-pick`](#mandible-pick) | bash | fzf-pick a command, then open it in mandible |
| [`mdcp`](#mdcp) | sh | Fetch a URL as Markdown, copy it, preview it |
| [`mdp`](#mdp) | sh | fzf Markdown picker with mdfried preview |
| [`mtime-sort`](#mtime-sort) | sh + perl | Sort path lines newest-first by mtime |
| [`omp-session`](#omp-session) | python3 | Resume or start omp for the current repo; backend of the `omp-sessions` cable |
| [`pj`](#pj) | bash | Task runner across every project task source, on a tv cable |
| [`projects-sync`](#projects-sync) | bash | Symlink every `~/Code` repo into `~/Projects` |
| [`pj-palette`](#pj-palette) | bash | pj's tasks plus quick actions as a tmux-palette source |
| [`tmux-sessions`](#tmux-sessions) | bash | Session/window/zoxide switcher as a tmux-palette source |
| [`yazi-nvim-open`](#yazi-nvim-open) | sh | yazi opener that targets the host Neovim |

## ai

```sh
ai
```

Shows `gum choose --header 'AI CLI'` with `claude`, `opencode`, `codex`, `hermes`, and `fractal`, then `exec`s the choice. `claude` runs as `claude --dangerously-skip-permissions`; the others run as the bare binary name. Esc or Ctrl-C exits 0.

**Needs:** `gum` and the chosen CLI.

## atuin-pick

```sh
atuin-pick
```

Opens atuin's interactive search (`atuin search -i --filter-mode directory`), limited to history from the current directory. It then `exec`s an interactive `fish`. If you picked a command, the new fish runs `echo '❯ <cmd>'; <cmd>` via `-C` (`--init-command`), so aliases resolve, a `cd` persists, and the prompt appears below the output. Esc starts a plain fish.

It is written for launch contexts where atuin's shell init never ran. It runs `atuin` from `PATH` and seeds `ATUIN_SESSION` from `atuin uuid` if unset.

**Launched by:** <kbd>ctrl+shift+p</kbd> in kitty. `kitty.conf` opens it in a horizontal split (`launch_hs atuin-pick`). Under the kitty-tmux profile, `tmux.conf` runs it with `tmux split-window -v -l 25%` in the current pane's directory. See [kitty](../terminal/kitty.md) and [atuin](atuin.md).

**Needs:** `python3`, `atuin`, `fish`.

## brave-new-tab

```sh
brave-new-tab <url>
```

Runs `brave-origin --new-tab <url>` detached with `setsid -f`. With Brave Origin running, the URL opens as a tab in its last active window; otherwise Brave Origin starts with it. Exits 2 unless given exactly one argument.

A URL without a scheme gets one from its host (port and path ignored): `localhost`, `*.localhost`, `*.local`, and `127.*` get `http://`, everything else `https://`. URLs containing `://`, and `about:` URLs, pass through unchanged.

| Argument | Opens |
| --- | --- |
| `example.com/path` | `https://example.com/path` |
| `localhost:3000` | `http://localhost:3000` |
| `printer.local` | `http://printer.local` |
| `http://example.com` | `http://example.com` |

**Needs:** `brave-origin` (`brave-origin-bin`), `setsid` (util-linux).

## c2p

```sh
c2p
```

Lists `*.hbs` files under `~/.config/code2prompt` with `fd`, lets you pick one with fzf, and `exec`s `code2prompt --template <file>`.

**Needs:** `fd`, `fzf`, `code2prompt`.

## extract_agents

```sh
extract_agents <output-dir>
```

Creates `<output-dir>` and copies every `AGENTS.md` below the current directory into it with `cp --parents`, keeping the relative paths.

**Needs:** `fd`, GNU `cp` (`--parents`).

## fab

```sh
fab
some-command | fab
```

Reads `~/.config/fabric/pattern_explainations.json`. fzf lists pattern names, the preview pane (right, 60%, wrapped) shows each description, and <kbd>ctrl-/</kbd> toggles the preview. The picked pattern runs as `fabric-ai --pattern <name>`, falling back to `fabric` if `fabric-ai` is not installed. Piped stdin is buffered to a temp file and fed to the pattern; the temp file is removed on exit.

**Needs:** `jq`, `fzf`, `fabric-ai` or `fabric`, and the pattern JSON.

## gdc

```sh
gdc
```

Asks `gum confirm "Discard all uncommitted changes? This is irreversible."`. On yes, runs `git reset --hard HEAD` and `git clean -fd`.

**Needs:** `gum`, `git`.

## gh-sonr-org-migrate

```sh
gh-sonr-org-migrate
```

A bash port of `fish/functions/gh-sonr-org-migrate.fish`, with the same flow:

1. **Preflight**

   Checks that `gh`, `gum`, and `jq` exist and that `gh auth status` succeeds.

2. **Discover**

   Lists your GitHub orgs whose login contains `sonr`, excluding the target `sonr-io`. You pick which to migrate with `gum choose --no-limit`.

3. **Transfer**

   For each repo in each org, runs `gh api -X POST repos/<org>/<repo>/transfer -f new_owner=sonr-io`. If the name already exists in `sonr-io`, `gum input` asks for a new name (default `<org>-<repo>`). An empty name skips the repo.

4. **Settle**

   Waits 30 seconds (`gum spin`), because GitHub transfers are asynchronous.

5. **Delete**

   For every selected org that had no failed transfers and now has zero repos, asks `gum confirm` and then `gh api -X DELETE orgs/<org>`.

**Needs:** `gh` authenticated as owner of every org involved, `gum`, `jq`.

> [!WARNING]
> In fish, run this script by its full path (`~/.local/bin/gh-sonr-org-migrate`). The fish file of the same name is a script body with no function in it, so typing just the name runs the fish flow and then this script. See [fish](fish.md#functions).

## ghg-clone

```sh
ghg-clone <repo>
```

Runs `ghq get <repo>`, with its output sent to stderr. It then works out the on-disk path: it strips the scheme, any `user@`, the scp-style colon, and a trailing `.git`, and prefixes `github.com/` when the input has no host. It checks that `$(ghq root)/<host>/<user>/<repo>` exists, runs `zoxide add` on it if zoxide is installed, and prints the path.

Accepts `https://…`, `ssh://…`, `git@host:user/repo`, `host/user/repo`, or `user/repo`.

**Mirrors.** After the clone, it sets up a [prad.codes](../tools/git.md) mirror when the repo has none. All of it talks on stderr and never fails the clone:

| Cloned from | Mirror | Skipped when |
| --- | --- | --- |
| `github.com/<owner>/<name>` | Pull mirror into a prad.codes org, every 8h (`tea repos migrate --mirror --mirror-interval 8h`, authenticated with `gh auth token`, private if the GitHub repo is). `gum choose` picks the org, preselected from GitHub's primary language: Go → `go`, Python → `py`, Rust → `rs`, Dart → `dart`, TeX → `tex`, JS/TS/Astro/Svelte/Vue/HTML/CSS → `js`, Markdown/MDX → `md`, anything else → `env`. Esc skips | You are not an admin of the GitHub repo, or a prad.codes repo already pulls from it (`original_url`) |
| `prad.codes/<org>/<name>` | Push mirror to `github.com/<you>/<name>` on every push and every 8h, with a first sync right away. After a `gum confirm`, it creates the GitHub repo (same visibility) if missing; an existing one is overwritten by the mirror pushes, which the prompt says | The repo is itself a pull mirror, or already has a push mirror |

Both mirrors store your `gh` OAuth token in prad.codes as the remote credential. Without a terminal (no `gum` prompt), nothing is mirrored.

**Used by:** the `ghg` shell function, which cds into the path, clears the screen, and runs `onefetch`. The fish function `gtm` also uses it to clone migrated repos.

**Needs:** `ghq` (`GHQ_ROOT=~/Code`, exported by fish, zsh, and bash), optional `zoxide`. Mirrors need `gh`, `tea` (logged in to prad.codes), `jq`, and `gum`; without any of them the step is skipped.

## ghn

```sh
ghn <repo-name>
```

Creates a new **private** repo and clones it:

- **prad.codes** (Gitea): pick an org from `tea organizations list`, then `tea repos create --private` and `ghq get https://prad.codes/<org>/<name>`.
- **github.com**: pick the owner `prdlk` or `wltbs`, then `gh repo create <owner>/<name> --private` and `ghq get`.

You pick the host with `gum choose`. The script prints the clone directory, and the `ghn` shell function cds into it.

**Needs:** `gum`, `ghq`, and `tea` or `gh`.

## git-summary

```sh
git-summary [code2prompt flags…]
```

From anywhere inside a git repo, runs `code2prompt <repo-root> --include AGENTS.md --include "**/AGENTS.md" --template ~/.config/code2prompt/agents-md.hbs`. Extra flags such as `--output-file` or `--tokens` are passed through.

**Needs:** `git`, `code2prompt`, and the `agents-md.hbs` template.

## gop

```sh
gop                 # origin, else upstream, else first remote
gop upstream        # a named remote
gop owner/repo      # github.com/owner/repo
gop <url>           # any https/ssh/scp remote URL
```

Opens a repo's web page for any forge whose URL layout is `https://<host>/<owner>/<repo>`, such as github.com and prad.codes. It reduces any remote form to `<host>/<owner>/<repo>`: it drops credentials, drops the port on `ssh://` and `git://` remotes, keeps the port and plain `http` on `http://` remotes, and strips `.git`. It then runs `$BROWSER` (default `xdg-open`) on the result.

**Needs:** `git`, a browser or `xdg-open`.

## kitty-day-save

```sh
kitty-day-save         # hold a logind delay lock, flush on shutdown, exit
kitty-day-save --now   # flush every running kitty immediately
```

Run by `kitty-day-save.service` (`dot_config/systemd/user/`, `WantedBy=graphical-session.target`, `Restart=always` after 10 s). It wraps itself in `systemd-inhibit --what=shutdown --mode=delay` and waits on `gdbus monitor` for login1's `PrepareForShutdown (true,)`. logind sends that before anything is killed and waits for the lock (`InhibitDelayMaxSec`, 5 s by default), so every kitty still has all its windows. It then sends `kitten day_session.py flush` over remote control to each `@kitty-<pid>` socket in `/proc/net/unix` (3 s timeout each) and exits, which releases the lock. The kitty that owns today's session saves it and holds further saves for 60 s; other kitties ignore the flush. See [kitty daily sessions](../terminal/kitty.md#daily-sessions).

**Needs:** `systemd-inhibit`, `gdbus`, `kitten`. Linux desktop/laptop roles only (`.chezmoiignore.tmpl`).

## launch_omp_livediff_overlay

```sh
launch_omp_livediff_overlay
```

Inside kitty with remote control enabled, runs `kitty @ launch --type=overlay-main --cwd=current omp`, then opens `livediff` in a `vsplit` next to that window with `--keep-focus`. It relies on `$KITTY_LISTEN_ON` rather than a hard-coded socket, because kitty appends `-PID` to `listen_on` socket names. It exits with an error if the variable is unset.

**Needs:** kitty with `allow_remote_control`/`listen_on` ([kitty](../terminal/kitty.md)), `omp` ([AI agents](../ai/README.md)), `livediff`.

## lc-elir

```sh
lc-elir [root]
```

Finds numbered LeetCode solution files (`^\d+\..+\.(js|ts)$`, for example `1365.some-slug.js`) under `root` (default `.`). fzf multi-selects them, showing the last three path segments with a `bat` preview of the first 40 lines. Each pick runs `omp -p "/leetcode-eli5 <file>"`.

**Needs:** `fd`, `fzf`, `bat`, `omp`, and the `/leetcode-eli5` omp command.

## mandible-pick

```sh
mandible-pick
```

`mandible` (installed with cargo, `~/.cargo/bin`) needs a tool to open, so this asks for one first. fzf lists the executables installed in the `PATH` directories, without shell builtins, keywords, or aliases. <kbd>enter</kbd> opens the highlighted command. If the query contains a space (`git remote add`) or matches nothing, <kbd>enter</kbd> uses it exactly as typed, so mandible opens at that subcommand path. Then it `exec`s `mandible <tool> [subcommand…]`. <kbd>esc</kbd> exits quietly. The command list is built with a bash loop rather than GNU `find -printf`.

**Used by:** the tmux-palette **mandible** item (alias `man`), which runs it in a popup. See [tmux](../terminal/tmux.md#command-palette).

**Needs:** `mandible`, `fzf` 0.51+ (`--with-shell`, `transform`, `accept-or-print-query`).

## mdcp

```sh
mdcp <url>
```

Fetches the URL as Markdown with `curl.md`, copies it with `wl-copy`, then pastes it back into `mdfried` for a rendered preview.

**Needs:** `curl.md`, `mdfried`, and `wl-clipboard`.

## mdp

```sh
mdp
```

Lists `*.md` files up to 3 directories deep with `fd`. fzf shows an `mdfried` preview (right, 60%, wrapped), and the pick opens in `mdfried`.

**Needs:** `fd`, `fzf`, `mdfried`.

## projects-sync

```sh
projects-sync
```

Mirrors every repo under the ghq root (`$GHQ_ROOT`, default `~/Code`, laid out `<host>/<owner>/<repo>`) as `~/Projects/<repo>` → the repo. Repos with the same name under different owners become `<owner>-<repo>`. Links pointing into `~/Code` whose repo is gone are removed; real files, real directories, and links pointing elsewhere in `~/Projects` are never touched.

Run by `projects-sync.timer` (`dot_config/systemd/user/`, 30 s after login and every 5 minutes), which [`30-user-services`](../chezmoi/scripts.md#30-user-services) enables. ghq clones land two levels below `~/Code`, out of reach of a non-recursive `.path` unit, hence the poll.

**Needs:** GNU `find`. Linux desktop/laptop roles only (`.chezmoiignore.tmpl`).

## free-router

```sh
free-router
```

Runs the [freellmapi](https://github.com/tashfeenahmed/freellmapi) router under Bun on `127.0.0.1:$FREE_ROUTER_PORT`, with its API key pinned to `$FREE_ROUTER_API_KEY`. Run by `free-router.service`, which [`30-user-services`](../chezmoi/scripts.md#30-user-services) enables. See [free-router](../ai/free-router.md).

**Needs:** `bun`, `git`, the `~/.local/share/freellmapi` external. Linux desktop/laptop roles only (`.chezmoiignore.tmpl`).

## mtime-sort

```sh
… | mtime-sort [--repo]
```

Reads lines on stdin and prints them newest-first by the mtime of each line's last tab-separated field (the whole line when it has no tab). With `--repo`, it stats `<path>/.git/index` first, so a repo sorts by its last git activity. Lines whose path does not exist are dropped. Ties keep input order.

**Used by:** every custom [television](../tools/television.md) cable except `agents` and `omp-sessions`, and `pj --list`. tv layers match quality and frecency on top of this order.

**Needs:** `perl`.

## omp-session

```sh
omp-session
```

Starts or resumes omp for the current git repo by fixed rules, so <kbd>ctrl-a</kbd> never asks when the answer is obvious.

| HEAD | Does |
| --- | --- |
| Default branch | Resumes the newest session on it when that session was written less than 3 hours ago. Otherwise opens the `omp-sessions` [television](../tools/television.md#omp-sessions) cable over all of the repo's sessions; <kbd>enter</kbd> resumes the pick, <kbd>esc</kbd> returns to the prompt. With no sessions at all it starts a new one |
| Any other branch | Resumes the newest session on that branch, or starts a new one |
| Detached | Opens the `omp-sessions` cable (a new session when there are none) |
| Outside a git repo | Plain `omp` |

Resuming runs `omp --resume <session file>`; omp switches to the session's own cwd. `omp-session --new` runs plain `omp`; it is the cable's <kbd>ctrl-n</kbd> action and marks `OMP_SESSION_STATE` like a resume does, so the prompt is not moved after a new session.

**Sessions.** Every `*/*.jsonl` under `$PI_CODING_AGENT_DIR/sessions` (default `~/.omp/agent/sessions`) whose `session` header `cwd` is the worktree root or below it, excluding worktrees nested inside it. Session age is the file's mtime (the last write).

**Branches.** omp does not record the git branch. A session's branch is the one HEAD was on when the file was last written, replayed from the worktree's `git reflog` (`checkout: moving from A to B`, `Branch: renamed`, `rebase (finish): returning to`). Sessions older than the oldest reflog move belong to the branch that move left; with no moves they all belong to the current branch. The default branch is `origin/HEAD`, else `init.defaultBranch`, `main`, or `master`, whichever exists.

**Entry points.** The cable calls back into the script:

| Command | Does |
| --- | --- |
| `omp-session --list` | Prints `<age> <branch> <title>[ · <subdir>]<TAB><session file>` per session, newest first. The title is omp's session title, else the first user message |
| `omp-session --preview FILE` | Title, last-write time, cwd, then the text of every user and assistant message (thinking, tool calls, and tool results skipped) |
| `omp-session --resume FILE` | Writes `ran` to `$OMP_SESSION_STATE` when set, then `exec omp --resume FILE` (enter) |

**Prompt redraw.** The launcher runs `tv omp-sessions --inline` with `OMP_SESSION_STATE` set to a temp file. When the picker is cancelled (no `ran`), it prints `\033[A` to `/dev/tty` so the shell redraws the prompt in place; the key bindings just repaint.

**Launched by:** <kbd>ctrl-a</kbd> in fish and zsh. <kbd>ctrl-n</kbd> at the prompt runs `omp` directly, not this script.

**Needs:** `python3`, `git`, `omp`, `tv`.

## pj

```sh
pj [extra args…]
```

A task runner that searches every task source in the project and lets you pick one in the `pj` [television](../tools/television.md#pj) cable.

**Sources.** Each is listed only when its runner is installed:

| Source | Found in | Runner |
| --- | --- | --- |
| npm scripts | `package.json` | package manager from `packageManager`, else from the lockfile (`bun.lock[b]`, `pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`, searched upward), else `npm`, then `<pm> run` |
| Make | `GNUmakefile`, `makefile`, `Makefile` | `make`. Targets come from a text parse of rules and `.PHONY`; `make -p` is avoided because it would run `$(shell …)` |
| just | `justfile`, `.justfile`, `Justfile`, `JUSTFILE` | `just` |
| mise | `mise.toml`, `.mise.toml`, `mise/config.toml`, `.mise/config.toml`, `.config/mise/config.toml`, or a `mise-tasks`/`.mise/tasks`/`mise/tasks` dir | `mise run`. Hidden tasks are skipped, and tasks inherited from parent directories are filtered out |
| devbox | `devbox.json` `shell.scripts` | `devbox run` |
| poe | `pyproject.toml` `[tool.poe.tasks]` | `poe`, else `uv run poe` |
| pdm | `[tool.pdm.scripts]` (skips `_*` and `post_*`) | `pdm run` |
| rye | `[tool.rye.scripts]` | `rye run` |
| taskipy | `[tool.taskipy.tasks]` | `task`, else `uv run task` |
| hatch | `[tool.hatch.envs.<env>.scripts]` as `env:name` | `hatch run` |
| console scripts | `[tool.poetry.scripts]`, `[project.scripts]` | `poetry run` for Poetry projects, else `uv run` |

**Scanning.** Walks from `$PWD` up to the git toplevel, inclusive. Outside a repo it stops at the first directory that produced tasks.

**Picker.** `pj` writes the records to a temp file and runs `tv pj --inline --source-command "cat <tmp>" --input-header <project root>`. Rows are tagged with the tool (`npm`, `pnpm`, `bun`, `make`, `just`, `mise`, `poe`, `py`, …), so typing a tool name filters to it. A directory column appears when more than one project contributed tasks. Tasks are sorted by their manifest's mtime, newest first, through `mtime-sort`. The preview shows the task body: the npm script string, the Make recipe, `just --show`, `mise tasks info`, the devbox script, or the pyproject entry.

**Entry points.** The cable calls back into the script:

| Command | Does |
| --- | --- |
| `pj --list` | Prints tab-separated records: display, kind, target, root, runner, manifest |
| `pj --preview KIND TARGET ROOT FILE` | Prints the task body for the preview pane |
| `pj --run KIND TARGET ROOT RUNNER` | Runs the task (enter) |

**Run.** cds into the task's directory and `exec`s the runner. Extra arguments given to `pj` travel to the task through `$PJ_EXTRA` (shell-quoted), with `--` inserted for `npm run`, `mise`, and `devbox`. Tasks named `dev`, `start`, `serve`, `watch`, or namespaced variants like `dev:web` are wrapped in `openlogs` (found on `PATH`, via `mise which`, or in mise's node installs) for a live log tail. Without openlogs they run unwrapped, with a note.

**Env.** `PJ_QUIET=1` suppresses the "no task sources found" error (exit status stays 1). The <kbd>down</kbd> bindings use it. `PJ_STATE=FILE` makes `pj` write `open` to `FILE` before launching the picker, and `pj --run` writes `ran`; the file stays empty when there are no task sources. The key bindings read it to tell no tasks, a cancelled picker, and a task that printed output apart and redraw the prompt to match. `pj` itself does no cursor handling, so typing `pj` behaves like any command.

**Launched by:** <kbd>ctrl-p</kbd>, and <kbd>down</kbd> on an empty prompt, in fish, zsh, and bash.

**Needs:** `bash`, `tv`, `mtime-sort`, `jq`, `python3` 3.11+ (for `tomllib`), plus whichever runners the project uses.

## pj-palette

```sh
pj-palette
pj-palette --run KIND TARGET ROOT RUNNER
pj-palette --cmd ROOT CMD…
pj-palette --bg NAME [ROOT CMD…]
pj-palette --omp
```

The source of the **Project Tasks** [tmux command palette](../terminal/tmux.md#command-palette) (`palettes/tasks.json`). Open it with tmux `prefix t`, Ghostty <kbd>ctrl+shift+p</kbd> or <kbd>ctrl+shift+space</kbd>, or the "Project Tasks" item in the main palette.

With no arguments it reads the active pane's directory (`tmux display -p '#{pane_current_path}'`) and prints palette items as JSON, grouped by category:

| Group | Items | Shown when |
| --- | --- | --- |
| Running | Every background task session still alive (any project), by session name | A long-running item was started and not stopped |
| Quick | `<pm> install` (alias `install`, `i`), `<pm> run dev` (`dev`) | `package.json` at the project root. The package manager comes from `packageManager`, then the lockfile, as in `pj` |
| Quick | `uv sync` (`sync`), `uv run python` (`py`, `repl`) | `pyproject.toml` and `uv` installed |
| Quick | `make` (default target; `m`, `build`) | A Makefile and `make` |
| Quick | `go run .`, `cargo run` | `go.mod` / `Cargo.toml` and the toolchain |
| Quick | `docker compose up` (`up`, `compose`) | `compose.y(a)ml` or `docker-compose.y(a)ml` at the project root and `docker` |
| Tasks: `<tool>` | Every record from `pj --list`: npm/bun/pnpm/yarn scripts, Make, just, mise, devbox, pyproject task tables and console scripts | Whatever `pj` finds walking up to the git root |

The project root is the git toplevel, else the pane's directory.

**Run.** One-off items open a full-width split along the bottom of the window (`split-window -v -f -l 25%`), 25% of its height, in the task's directory. The command is passed to `split-window` as separate arguments, so no shell reparses it. `--run` calls `pj --run`, which keeps pj's `openlogs` wrapping of `dev`/`start`/`serve`/`watch` tasks, and `--cmd` runs a quick action. While the command runs, <kbd>ctrl-c</kbd> stops only the command (the script traps `SIGINT`), so the output stays. Once the command exits, the script prints `[exit N] enter or ctrl-c to close`, and <kbd>enter</kbd> or <kbd>ctrl-c</kbd> closes the pane; other keys are ignored.

**Background.** Long-running items, marked `· background`, are `<pm> run dev`, `docker compose up`, and pj tasks named `dev`/`start`/`serve`/`watch`/`preview` or with one of those as a `:` segment (`dev:web`, `api:dev`). They run through `--bg` in a detached session named `<session>:<tool-and-command>` (`leetcode:bun-run-dev`, `leetcode:docker-compose-up`), shown in a rounded 90%×80% popup attached to it. <kbd>q</kbd> detaches the popup and leaves the task running: the session's `key-table` is `pj-task`, which binds only `q` and <kbd>ctrl-c</kbd>, so other keys reach the task instead of root-table bindings (prefix bindings still work). <kbd>ctrl-c</kbd> runs `confirm-before` (`Stop <session>? (y/n)`); <kbd>y</kbd> sends ctrl-c to the task, which stops it and ends the session, closing the popup, and any other key cancels. If the task exits on its own, the `[exit N]` prompt keeps its output until <kbd>enter</kbd>. Picking the item again, or its **Running** entry, reopens the popup instead of starting a second copy. The session has `status off`, `detach-on-destroy on`, and `@pj_task` set to the task's root, which is how the Running group finds it. Session names contain `:`, so the script targets them by id (`$N`).

**omp.** tmux `prefix a` (Ghostty <kbd>ctrl+shift+a</kbd>) runs `pj-palette --bg <session>:omp <pane cwd> omp`, so omp gets the same kind of background session and Running entry. Its popup docks in the bottom-right corner of the client, 35% wide and 60% tall. omp runs directly (no `[exit N]` prompt) and needs <kbd>q</kbd>, so its session uses the `pj-app` key table instead: <kbd>ctrl-c</kbd> hides the popup, <kbd>ctrl-q</kbd> kills the session (quits omp). `prefix a` inside any session with `@pj_task` also hides, which makes <kbd>ctrl+shift+a</kbd> a toggle. The popup border shows only the session name.

**omp palette.** `--omp` feeds `palettes/omp.json`, opened by the main palette's **omp** item. It lists every running `<session>:omp` across tmux sessions, with a green icon and `open`/`hidden` state: **This session** first (or a grey `not running · start in <cwd>` item that starts it), then **Running** for the other tmux sessions' agents, then a **Quit** item per session (`kill-session`).

**Needs:** `pj` and its dependencies, `jq`, tmux.

## tmux-sessions

```sh
tmux-sessions
tmux-sessions --new QUERY
tmux-sessions --dir DIR
```

The source of the **Sessions** [tmux command palette](../terminal/tmux.md#command-palette) (`palettes/sessions.json`), which replaced tmux-sessionx. Open it with tmux `prefix o`, Ghostty <kbd>ctrl+shift+o</kbd> or <kbd>super+enter</kbd>, or the "Sessions" item in the main palette.

With no arguments it prints palette items as JSON, grouped by category:

| Group | Items | Action |
| --- | --- | --- |
| Sessions | Every session but the current one, the client's last session first. Attached ones have a green icon | `switch-client` |
| Windows | Every window of every session, as `<session>:<index> · <cwd>` | `switch-client` to that window |
| Zoxide | `zoxide query -l` | `--dir` |
| Config | Directories in `~/.config` that zoxide does not list | `--dir` |
| Rename | One per session | `command-prompt` prefilled with the name |
| Kill | One per session except the current one | `kill-session` |

pj-palette's background task sessions (`@pj_task`) are left out. Sessions are targeted by id, since names may contain `:`.

**`--new QUERY`** is the palette's `query` item, the typed text listed after the matches. It switches to the session named QUERY if there is one. Otherwise it starts a session named QUERY in QUERY itself if that is a directory (via `--dir`), else in `zoxide query QUERY`'s match (QUERY's words are separate keywords), else in tmux's default directory. Typed text that matches nothing therefore lands on the `query` item, the same as sessionx's zoxide mode.

**`--dir DIR`** switches to, or starts in DIR, the session named after DIR's basename with dots removed (sessionx's rule).

**Needs:** tmux, `jq`, `zoxide`.

## yazi-nvim-open

```sh
yazi-nvim-open [vsplit|split|tabedit] <file>…
```

yazi's `edit` opener. When run inside a Neovim terminal (`$NVIM` set), each file's absolute path goes to the **host** Neovim through `nvim --server "$NVIM" --remote-expr 'v:lua.EditFromYazi(mode, path)'` (defined in the nvim config's `yazi_session.lua`). Outside Neovim it `exec`s a normal `nvim`, and the split modes do nothing. Set `YAZI_OPEN_TRACE=<file>` to log each call.

**Used by:** `yazi.toml` (the `edit` opener) and `keymap.toml` (<kbd>ctrl-v</kbd> vsplit, <kbd>ctrl-x</kbd> split). See [yazi](../tools/yazi.md).

**Needs:** `nvim`, `realpath`.
