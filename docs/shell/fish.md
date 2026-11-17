# fish

The primary interactive shell — conf.d layout, environment, vi-mode key bindings, the cyberdream theme, completions, and every autoloaded function.

fish is the primary interactive shell. The config is split into autoloaded files: `conf.d/` for startup snippets, `functions/` for one function per file, `completions/` for completion scripts, and `themes/` for the color theme. `config.fish` runs last and holds the prompt and atuin setup.

| Source (repo) | Target |
| --- | --- |
| `dot_config/fish/config.fish` | `~/.config/fish/config.fish` |
| `dot_config/fish/conf.d/*.fish` | `~/.config/fish/conf.d/` |
| `dot_config/fish/functions/*.fish` | `~/.config/fish/functions/` |
| `dot_config/fish/completions/*.fish` | `~/.config/fish/completions/` |
| `dot_config/fish/themes/cyberdream.theme` | `~/.config/fish/themes/cyberdream.theme` |
| `dot_config/fish/fish_plugins` | `~/.config/fish/fish_plugins` |

`dot_config/fish` is part of this repo (it used to be the [prdlk/fish](https://github.com/prdlk/fish) submodule); edit and commit it here. None of these files are templates. chezmoi runs in symlink mode, so each target is a symlink back into the source tree and edits to `~/.config/fish/...` land in the repo directly. `~/.config/fish/fish_variables` (universal variables, including the selected theme) is listed in `.chezmoiignore.tmpl` and stays local to each machine. `~/.config/fish/conf.d/secrets.fish` is local-only: it is listed in `.chezmoiignore.tmpl` and in the root `.gitignore`, and never committed.

## Installation

`fish` is in `.chezmoidata/packages.yaml` under `packages.tools` (pacman, Homebrew, or apt through the fish 4 PPA on Ubuntu); `.chezmoiscripts/run_onchange_before_10-packages.sh.tmpl` installs it. The tools that fish initializes (starship, zoxide, atuin, fzf, eza, gum, yazi, television, mise) come from the same manifest; Bun is a global mise tool (`packages.shared.mise`) and rustup comes from [15-tools](../chezmoi/scripts.md#15-tools). hishtory, envman, and the Go, Android, and Foundry toolchains are not in the manifest; fish initializes each one only if it is present.

### Plugins

`fish_plugins` is a [fisher](https://github.com/jorgebucaran/fisher) manifest with one entry:

**~/.config/fish/fish_plugins**

```text
jorgebucaran/nvm.fish
```

The plugin's files are committed to the repo (`conf.d/nvm.fish`, `functions/nvm.fish`, `functions/_nvm_*.fish`, `completions/nvm.fish`), so fish has `nvm` without fisher. The plugin stores Node builds in `$XDG_DATA_HOME/nvm` (default `~/.local/share/nvm`) and downloads from `https://nodejs.org/dist`. If `nvm_default_version` is set, it runs `nvm use --silent $nvm_default_version` in each interactive shell.

## Startup order

fish sources `conf.d/*.fish` in name order and then `config.fish`. The numbered files load first:

| File | Purpose |
| --- | --- |
| `00-path.fish` | `PATH` entries and `PNPM_HOME` |
| `10-env.fish` | Non-secret environment, greeting, fzf colors |
| `20-aliases.fish` | Aliases, clipboard aliases, `q`, typo guards |
| `30-ssh-agent.fish` | One ssh-agent shared across shells |
| `40-tools.fish` | mise, television, starship, zoxide, entire, hishtory, unsloth |
| `50-terminal-title.fish` | tmux/screen window name from `$PWD` |
| `inir-env.fish` | `INIR_VENV` and `ILLOGICAL_IMPULSE_VIRTUAL_ENV` → `~/.local/state/quickshell/.venv` |
| `inir-path.fish` | Prepends `~/.local/bin` to `PATH` if missing |
| `nvm.fish` | nvm.fish plugin events and default-version activation |
| `opencode-background-subagents.fish` | `OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true`, `OPENCODE_ENABLE_EXA=1` |
| `pnpm-filter.fish` | `pnpmf*` workspace helpers |
| `rustup.fish` | Sources `~/.cargo/env.fish` |
| `secrets.fish` | API credentials (names below) |
| `uv.env.fish` | Sources `~/.local/bin/env.fish` (written by the uv installer) |

### 00-path.fish

Runs for every shell, including non-interactive ones, so scripts get the same `PATH`.

| Entry | Position |
| --- | --- |
| `~/.local/bin` | prepended first, so `40-tools.fish` finds a `mise` installed by `mise.run` (Ubuntu); `inir-path.fish` adds it again only if missing |
| Homebrew's prefix (`brew shellenv fish`, macOS) | evaluated next |
| `~/.bun/bin`, `~/.local/share/go/bin`, `~/.maestro/bin`, `~/.grok/bin`, `~/.opencode/bin` | prepended |
| `~/.foundry/bin` | appended |
| `~/.local/share/android-sdk/platform-tools`, `cmdline-tools/latest/bin`, `emulator` | prepended (ahead of the legacy AUR `/opt/android-sdk/tools`) |
| `~/local/share/pnpm` | appended (note the missing dot; this path does not match `PNPM_HOME`) |
| `$PNPM_HOME/bin` | prepended; `PNPM_HOME=~/.local/share/pnpm` |

`~/.cargo/bin` comes from `rustup.fish`. `40-tools.fish` runs `mise activate fish` only when `mise` is on `PATH`.

### 10-env.fish

| Variable | Value |
| --- | --- |
| `fish_greeting` | empty (no greeting) |
| `FISH_BOTTOM_PROMPT` | `0` unless inherited. `1` pins the prompt to the bottom row |
| `HSA_OVERRIDE_GFX_VERSION` | `11.5.0` (ROCm) |
| `ROCR_VISIBLE_DEVICES`, `HIP_VISIBLE_DEVICES` | `0` |
| `__EGL_VENDOR_LIBRARY_FILENAMES`, `VK_DRIVER_FILES` | Mesa's `50_mesa.json` and RADV's `radeon_icd.json`, only when `/dev/dri/by-path/pci-0000:c4:00.0-render` (the Strix Halo iGPU) exists. Keeps the session off the compute-only eGPU |
| `EGET_BIN` | `~/.local/bin` |
| `GHQ_ROOT`, `CODE_ROOT` | `~/Code` |
| `ANDROID_HOME`, `ANDROID_SDK_ROOT` | `~/.local/share/android-sdk` |
| `JAVA_HOME` | `/usr/lib/jvm/java-17-openjdk` when installed (Gradle/AGP builds) |
| `PI_BASH_NO_CI` | `1`: omp's bash tool stops exporting `CI=true` into agent shells (CI mode turns off Metro's file watching) |
| `GITEA_LOGIN` | `prad.codes` |
| `GITLAB_HOST` | `git.sonr.org` |
| `GITHUB_TOKEN` | `gh auth token`, unless already set and only if `gh` is logged in |
| `FREE_ROUTER_PORT`, `FREE_ROUTER_API_KEY` | each `KEY=VALUE` line of `~/.config/free-router/env`, if it exists. The file comes from the [desktop layer](https://prad.codes/env/omarchy-desktop/src/branch/main/docs/free-router.md), so it only exists on Omarchy machines |
| `EDITOR`, `VISUAL` | `nvim` |
| `BROWSER` | `/usr/bin/brave-origin` if that binary exists |
| `CHROME_EXECUTABLE` | `/usr/bin/chromium` if it exists |
| `PUPPETEER_EXECUTABLE_PATH` | `~/.local/bin/chrome-headless-shell` |
| `ZEAL_DOCSETS` | the Zeal flatpak docset directory |
| `SHARP_IGNORE_GLOBAL_LIBVIPS` | `1` |
| `FZF_DEFAULT_OPTS` | cyberdream fzf theme (below) |

`GOPATH`/`GOBIN` are not set here. The comment explains why: mise's fish hook re-applies its `[env]` on every prompt, so Go paths are pinned in `~/.config/mise/config.toml`, and mise provides `GOROOT`. `~/.config/go/env` holds the same values for any `go` run outside a shell.

**~/.config/fish/conf.d/10-env.fish**

```fish
set -gx FZF_DEFAULT_OPTS "
  --height=~40%
  --layout=default
  --info=inline-right
  --border=rounded
  --prompt='  '
  --pointer='▶'
  --marker='✓'
  --color=fg:#ffffff,fg+:#ffffff,bg:-1,bg+:#3c4048
  --color=hl:#5ef1ff,hl+:#5ef1ff
  --color=info:#7b8496,header:#7b8496,border:#7b8496
  --color=prompt:#5ef1ff,pointer:#ffaecf,marker:#5eff6c,spinner:#f1ff5e
  --color=gutter:-1,query:#ffffff
"
```

### 20-aliases.fish

Editor, Bun, directory-jump, and tool aliases, followed by:

- `cpy`/`pst`: `wl-copy`/`wl-paste` when `wl-copy` exists (Wayland; not defined on macOS).
- `q`: exits the shell. If `$YAZI_ID` is set and `ya` exists, it first runs `ya emit quit` so the yazi that spawned the shell quits too.
- Interactive only: `celar` and `claer` → `clear`, and `ls` → `eza --icons` when eza is installed. `clear` itself is not aliased, because an alias would shadow `functions/clear.fish`.

The full list is on the [Aliases](aliases.md) page. This file is plain fish, not rendered from `.chezmoidata/aliases.yaml`, so its alias set differs from bash/zsh in a few places.

### 30-ssh-agent.fish

Interactive shells without `SSH_AUTH_SOCK` source `~/.ssh/agent.env.fish` and probe with `ssh-add -l`. Exit code 2 means no agent is reachable. In that case it starts `ssh-agent -c`, rewrites its csh `setenv` lines into `set -gx`, saves them to `~/.ssh/agent.env.fish`, and sources the file. An `SSH_AUTH_SOCK` provided from outside (systemd unit, forwarding, keyring) is left alone.

### 40-tools.fish

- `mise activate fish` runs for every shell, so scripts see mise shims too.
- Interactive only, in order:
  1. Print `~/.local/state/quickshell/user/generated/terminal/sequences.txt` if present. These are escape sequences that apply wallpaper-generated Material You terminal colors from quickshell.
  2. `tv init fish` (television), if installed.
  3. `starship init fish`, `zoxide init fish`, and `entire completion fish`, each only if installed.
  4. `tv init fish` a second time. The comment says it runs before hishtory so hishtory keeps <kbd>ctrl-r</kbd>.
  5. Source `~/.hishtory/config.fish` if present.
  6. Activate the unsloth studio venv (`~/.unsloth/studio/unsloth_studio/bin/activate.fish`) if present.

atuin is initialized later, in `config.fish`, and binds <kbd>ctrl-r</kbd> itself.

### 50-terminal-title.fish

Defines `terminal_title`, which runs on every `PWD` change and prints `ESC k <prompt_pwd> ESC \`. That sequence sets the tmux or screen window name. `functions/fish_title.fish` sets the regular terminal title.

### pnpm-filter.fish

pnpm workspace helpers. `__pnpm_pick_pkg` lists workspace packages with `pnpm m ls --depth -1 --json | jq`, and you pick one with `gum filter`.

| Function | Does |
| --- | --- |
| `pnpmf <deps…>` | Pick a package, then `pnpm --filter <pkg> add <deps>` inside a `gum spin` |
| `pnpmfd <deps…>` | Same with `add -D` |
| `pnpmfr <deps…>` | `pnpm --filter <pkg> remove <deps>` |
| `pnpmfw` | Pick a target package and a sibling, then `pnpm --filter <pkg> add <sibling> --workspace` |
| `pnpmfx` | Pick a package, then pick one of its `package.json` scripts with `gum filter` and run it |

### secrets.fish

Exports credentials as global variables. It is age-encrypted in the repo (`dot_config/fish/conf.d/encrypted_private_secrets.fish.age`) and written, mode 600, only on machines that got the [master password](../chezmoi/config.md#master-password) at `chezmoi init`; elsewhere it is absent and fish starts without it. Edit it with `chezmoi edit ~/.config/fish/conf.d/secrets.fish`. It ships with every variable commented out:

`PGDATABASE` (local Postgres connection string), `GITLAB_TOKEN`, `OPPER_API_KEY`, `OPENAI_API_KEY`, `GROQ_API_KEY`, `WEBAWESOME_NPM_TOKEN`, `TAVILY_API_KEY`, `FINANCIAL_DATASETS_API_KEY`, `PIMLICO_API_KEY`, `WAKATIME_API_KEY`, `LINEAR_CLI_PROFILE`, `LINEAR_API_KEY`, `LINEAR_TEAM_ID`.

## config.fish

The header comment says the file should stay empty, but it holds the following:

1. **Starship with transient prompt.** `starship_transient_prompt_func` renders `starship module character` and `starship_transient_rprompt_func` renders `starship module time`. Then `starship init fish | source` and `enable_transience` run, so past prompts collapse to `❯` with the time on the right. See [Starship](starship.md).
2. **Bottom-pinned prompt.** In interactive shells with `FISH_BOTTOM_PROMPT=1`, `tput cup $LINES 0` moves the cursor to the last row. The comment calls `1` the default, but `10-env.fish` sets `0`, so the prompt stays at the top unless you export `FISH_BOTTOM_PROMPT=1`.
3. `fish_add_path ~/.grok/bin` (grok installer block).
4. Sources `~/.config/envman/load.fish` if it is non-empty.
5. **atuin.** Interactive shells run `atuin init fish | source`. See [atuin](atuin.md).
6. `fish_add_path ~/.cmux/bin` and `~/.cache/.bun/bin`.
7. Sources the first readable `~/.config/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.fish`. This is herdr's automatic pane-rename hook ([herdr](../terminal/herdr.md)).
8. A copy of the `_atuin_ai_question_mark` function that `atuin ai init fish` used to emit (atuin 18.21 removed that command), followed by `bind "?" _atuin_ai_question_mark`.

## Key bindings

`functions/fish_user_key_bindings.fish` turns on **vi mode** (`fish_vi_key_bindings`) first, then adds custom binds in both `insert` and `default` (normal) modes, so they work in either mode. Visual mode is off: the preset `v` bind in normal mode (the only way into it) is erased, so `v` does nothing.

| Key | Action |
| --- | --- |
| <kbd>ctrl-e</kbd> | `_tv_inline git-files`, then repaint: pick a file in the repo and open it in nvim ([television](../tools/television.md#git-files)) |
| <kbd>ctrl-f</kbd> | `yy`: yazi, then cd to the directory yazi exited in |
| <kbd>ctrl-b</kbd> | `purple`, then repaint (an external command; this repo does not provide it) |
| <kbd>ctrl-y</kbd> | `clip-last`: re-run the last command and copy its output |
| <kbd>ctrl-o</kbd> | `_gho_bind`: `gho` (pick a ghq repo or Obsidian vault from the `ghq-repos` cable and cd into it), then repaint |
| <kbd>ctrl-p</kbd> | `_pj_bind`: `pj`, the task runner on the `pj` cable ([Scripts](scripts.md#pj)), then repaint |
| <kbd>ctrl-a</kbd> | `omp-session`, then repaint: resume or start omp for the current repo by branch and session age, opening the `omp-sessions` cable only when nothing qualifies ([Scripts](scripts.md#omp-session)) |
| <kbd>ctrl-n</kbd> | `omp`, then repaint: always a new omp session |
| <kbd>ctrl-w</kbd> | `atuin ai inline`: natural-language command overlay |
| <kbd>ctrl-z</kbd> | `_jobs_bind`: with one background job, `fg` it; with several, pick one from the `jobs` cable ([television](../tools/television.md#jobs)) and `fg` that; with none, nothing. While a job holds the terminal, ctrl-z is still the tty's suspend, so the key toggles suspend and resume |
| <kbd>ctrl-g</kbd> | `lazygit` |
| <kbd>down</kbd> | `_pj_bind_down`: opens the `pj` cable on an idle, empty prompt, otherwise fish's `down-or-search` |
| <kbd>ctrl-c</kbd> | Clears the command line, runs `clear` (screen and kitty scrollback), repaints |
| <kbd>ctrl-q</kbd> | `exit` |

Bindings added by tool init scripts:

| Key | Mode | Action | Source |
| --- | --- | --- | --- |
| <kbd>ctrl-r</kbd> | default and insert | `_atuin_search` | `atuin init fish` |
| <kbd>up</kbd> | default and insert | `_atuin_bind_up` (atuin history, directory filter) | `atuin init fish` |
| <kbd>?</kbd> | default (vi normal) | `_atuin_ai_question_mark`: on an empty buffer, opens `atuin ai inline` | `config.fish` |
| <kbd>ctrl-t</kbd> | insert | `tv_smart_autocomplete` | `tv init fish` |

`_pj_bind_down` hands the key to `down-or-search` when the buffer is non-empty, the completion pager is open, or history search is active. Otherwise it runs `_pj_bind --quiet` (`PJ_QUIET=1`), so pressing down outside a project does nothing and prints no error.

The pickers run `tv --inline`, which opens on the line below the prompt and leaves the cursor there when it exits. The wrappers put the prompt back before `commandline -f repaint`, writing the cursor moves to `/dev/tty`:

| Wrapper | Runs | Then |
| --- | --- | --- |
| `_tv_inline ARGS` | `tv ARGS --inline` | `\033[A` (cursor up), returns tv's status |
| `_gho_bind` | `gho` | `\033[A` if the cwd did not change; `\n` after a cd, so the prompt lands below onefetch |
| `_pj_bind [--quiet]` | `pj` with `PJ_STATE` set to a temp file | `\033[A` for `open` (cancelled) or empty (no task sources); `\n` for `ran` (the task printed output) |
| `_jobs_bind` | `fg` of the only job, or `jobs` with `TV_JOBS` set to a temp file holding the job table | `\033[A` (via `_tv_inline`) when the picker is cancelled |

`_jobs_bind` runs `fg` by replacing the command line with ` __jobs_bind_fg <id>` (leading space: kept out of history) and executing it, not from inside the binding. A binding runs while fish's reader still owns the terminal with extended keys on, so a job started with `&` that had never held the terminal got ctrl-z and ctrl-c as escape sequences instead of signals. `__jobs_bind_fg` erases the echoed prompt line (`\033[A\033[2K` on `/dev/tty`) and runs `fg` with its "Send job … to foreground" message sent to `/dev/null`, so resuming leaves nothing on screen. Text already typed is put back at the next prompt by a one-shot `fish_prompt` handler.

`omp-session` (<kbd>ctrl-a</kbd>) does its own `\033[A` when its `omp-sessions` picker is cancelled, so the binding only repaints.

zsh and bash bind <kbd>ctrl-o</kbd>, <kbd>ctrl-e</kbd>, <kbd>ctrl-p</kbd>, <kbd>down</kbd>, and <kbd>ctrl-t</kbd> the same way ([bash and zsh](bash-zsh.md)). Inside television, <kbd>ctrl-e</kbd> runs the channel's `edit` action and <kbd>ctrl-h</kbd> its `goto_parent_dir` action (`~/.config/television/config.toml`). The config and cables are on the [television](../tools/television.md) page.

> [!NOTE]
> Under kitty, <kbd>ctrl-g</kbd> (lazygit overlay), <kbd>ctrl-y</kbd> (yazi split), and <kbd>ctrl-h/j/k/l</kbd> (split navigation) are mapped in `kitty.conf` and never reach fish. The fish binds for those keys only apply in other terminals. See [kitty](../terminal/kitty.md).

The prompt shows `❮` in green in vi normal mode (starship's `vimcmd_symbol`).

## Theme

`themes/cyberdream.theme` is a fish theme file with colors from [cyberdream.nvim](https://github.com/scottmckendry/cyberdream.nvim) and preferred background `#16181a`. The repo ships the file but does not select it. The active theme is stored in `fish_variables`, which chezmoi ignores, so pick it once per machine with `fish_config theme save cyberdream`.

| Variable | Color |
| --- | --- |
| `fish_color_normal` | `#ffffff` |
| `fish_color_command` | `#5ef1ff` |
| `fish_color_param`, `fish_color_escape` | `#ffaecf` |
| `fish_color_keyword`, `fish_color_host` | `#5eff6c` |
| `fish_color_quote`, `fish_color_option`, `fish_color_host_remote` | `#f1ff5e` |
| `fish_color_redirection`, `fish_color_operator` | `#5ea1ff` |
| `fish_color_end` | `#bd5eff` |
| `fish_color_comment`, `fish_color_gray`, `fish_color_autosuggestion` | `#7b8496` |
| `fish_color_error`, `fish_color_cancel`, `fish_color_status` | `#ff6e5e` |
| `fish_color_selection`, `fish_color_search_match` | background `#3c4048` |
| `fish_color_cwd` | `#ffbd5e` |
| `fish_color_user` | `#5ef5d2` |
| `fish_pager_color_progress`, `fish_pager_color_description` | `#7b8496` |
| `fish_pager_color_prefix` | `#5ea1ff` |
| `fish_pager_color_completion` | `#ffffff` |

`FZF_DEFAULT_OPTS` in `10-env.fish` uses the same palette.

## Completions

| File | Command | Mechanism |
| --- | --- | --- |
| `ccc.fish` | `ccc` | Typer-generated: calls `ccc` with `_CCC_COMPLETE=complete_fish` |
| `grok.fish` | `grok` | Static clap-style completion script (global options, subcommands) |
| `mise.fish` | `mise` | `mise completion fish \| source` (generated at load time) |
| `nvm.fish` | `nvm` | From the nvm.fish plugin |
| `omp.fish` | `omp` | `omp completions fish \| source` (generated at load time) |
| `ostt.fish` | `ostt` | Static clap-style completion script |

## Functions

Every file in `functions/` is autoloaded by name. Several also exist as POSIX scripts in `~/.local/bin` for bash and zsh. In fish the function shadows the script. See [Scripts](scripts.md) for why the cd-style helpers must stay shell functions.

| Function | Purpose |
| --- | --- |
| `_nvm_index_update` | nvm.fish internal: downloads `index.tab` from `$nvm_mirror` into `$nvm_data/.index` |
| `_nvm_list` | nvm.fish internal: lists installed Node versions plus `system` |
| `_nvm_version_activate` | nvm.fish internal: sets `nvm_current_version` and prepends its `bin` to `PATH` |
| `_nvm_version_deactivate` | nvm.fish internal: removes a version's `bin` from `PATH` |
| `_gho_bind` | <kbd>ctrl-o</kbd> handler: `gho`, then cursor fix and repaint (see [Key bindings](#key-bindings)) |
| `_pj_bind` | <kbd>ctrl-p</kbd> handler: `pj` with `PJ_STATE`, then cursor fix and repaint. `--quiet` sets `PJ_QUIET=1` |
| `_jobs_bind` | <kbd>ctrl-z</kbd> handler: `fg` the only job or pick one from the `jobs` cable (see [Key bindings](#key-bindings)) |
| `_pj_bind_down` | Down-arrow handler: `_pj_bind --quiet` on an empty idle prompt, else `down-or-search` |
| `_tv_inline` | `tv $argv --inline`, then moves the cursor up one line on `/dev/tty` |
| `ai` | `gum choose` among `claude`, `opencode`, `codex`, `hermes`, `fractal`. `claude` runs with `--dangerously-skip-permissions` |
| `c` | `clear` with no argument, `cd <dir>` with one |
| `c2p` | fzf-pick a `.hbs` template under `~/.config/code2prompt` and run `code2prompt --template` |
| `cd` | `builtin cd`. If that fails, `zoxide query` the argument. Every successful cd is recorded with `zoxide add` |
| `clear` | Prints `ESC[2J ESC[3J ESC[1;1H` to clear the screen and kitty scrollback, then re-pins the prompt if `FISH_BOTTOM_PROMPT=1`. Falls back to `command clear` when not interactive |
| `clip-last` | Re-runs `$history[1]`, pipes the output to `cpy`, and sends a `notify-send` notification |
| `cp-appid` | fzf-pick a `.desktop` app ID and copy it with `wl-copy`; runs the `cp-appid` script from the [desktop layer](https://prad.codes/env/omarchy-desktop/src/branch/main/docs/scripts.md#cp-appid), so it only works on Omarchy machines |
| `czs` | chezmoi sync: `chezmoi status`, `chezmoi re-add` of drifted files, commit the source repo, then `git pull --rebase --autostash` and `git push` if ahead. Optional targets scope it (for example `czs ~/.config/fish`). Messages print with a `chs:` prefix |
| `extract_agents <dir>` | Copies every `AGENTS.md` under the current tree into `<dir>`, preserving paths |
| `fab` | fzf-pick a Fabric pattern from `~/.config/fabric/pattern_explainations.json` (description in the preview, <kbd>ctrl-/</kbd> toggles it) and run it, feeding piped stdin if any |
| `fish_title` | Terminal title: `prompt_pwd`, or `<host (10 chars)>:<pwd>` over SSH |
| `fish_user_key_bindings` | Vi mode plus the custom binds above |
| `gdc` | `gum confirm`, then `git reset --hard HEAD` and `git clean -fd` |
| `gh-sonr-org-migrate` | Script body (see the warning below) that moves every repo from `*sonr*` GitHub orgs into `sonr-io` and deletes the emptied orgs |
| `ghg <repo>` | `ghg-clone <repo>` (ghq get), cd into the clone, `clear`, `onefetch` |
| `ghn <name>` | Runs `~/.local/bin/ghn` to create and clone a private repo, then cds into it |
| `gho` | `tv ghq-repos --inline` (repo/vault picker); returns if nothing was picked, else cds into the result, `clear`, and `onefetch` inside git repos |
| `git-summary [flags]` | `code2prompt` over the repo root, including only `AGENTS.md` files, using `~/.config/code2prompt/agents-md.hbs`. Extra flags pass through |
| `gtm [repo]` | Migrates GitHub repos to a prad.codes (Gitea) org with `tea repos migrate`. With no argument, fzf multi-selects from `gh repo list`. You pick the target org and migration options (wiki, issues, labels, pull-requests, releases, milestones, lfs, mirror) with gum, private repos stay private, and it offers to clone the results with `ghg-clone`. Fish only |
| `launch_omp_livediff_overlay` | Uses `kitty @` to overlay `omp` on the current window with a `livediff` vsplit beside it. Needs `KITTY_LISTEN_ON` |
| `lc-elir [root]` | fzf multi-select numbered LeetCode solution files (`1234.slug.js`/`.ts`) and run `omp -p "/leetcode-eli5 <file>"` on each |
| `mdcp <url>` | `curl.md <url>`, copy the result with `cpy`, and preview it with `mdfried` |
| `mdp` | fzf-pick a Markdown file up to 3 levels deep (mdfried preview) and open it in `mdfried` |
| `nvm` | nvm.fish: `install`, `use`, `list`, `list-remote`, `current`, `uninstall`. Reads `.nvmrc`/`.node-version` |
| `y` | yazi with `--cwd-file`, then cd to the directory yazi exited in |
| `yy` | Same as `y`. Used by the <kbd>ctrl-f</kbd> bind |

Functions defined inside `conf.d/` and `config.fish` rather than `functions/`: `q` (20-aliases), `terminal_title` (50-terminal-title), the `pnpmf*` helpers and `__pnpm_pick_pkg` (pnpm-filter), the `_nvm_install`/`_nvm_update`/`_nvm_uninstall` event handlers (nvm), and `starship_transient_prompt_func`, `starship_transient_rprompt_func`, and `_atuin_ai_question_mark` (config.fish).

> [!WARNING]
> **gh-sonr-org-migrate**
>
> `functions/gh-sonr-org-migrate.fish` is a script, not a function definition. Running `gh-sonr-org-migrate` in fish autoloads the file, which runs the whole fish migration flow. Because the file defines no function of that name, fish then falls through to the bash port at `~/.local/bin/gh-sonr-org-migrate` and starts a second run. Cancel the second run at its first `gum` prompt, or call the bash script by its full path.
