# Externals and ignore rules

The git repos chezmoi clones into $HOME and every rule in .chezmoiignore.tmpl, including the role gate for the Linux desktop layer.

## .chezmoiexternal.toml

Externals are content chezmoi fetches instead of storing in the repo. Every entry is a `git-repo` external: chezmoi runs `git clone` when the target directory is missing. Because they are real git checkouts, they are never symlinked into the source tree. A target that already exists without being a checkout (Omarchy's stock `~/.config/kitty`, for example) would stop the apply; [`05-externals`](scripts.md#05-externals) asks to move it aside and clones the repo in its place first.

**.chezmoiexternal.toml**

```toml
[".config/nvim"]
    type = "git-repo"
    url = "https://github.com/prdlk/nvim.git"
    [".config/nvim".pull]
        args = ["--ff-only"]

[".config/bat/syntaxes/sublime-purescript-syntax"]
    type = "git-repo"
    url = "https://github.com/tellnobody1/sublime-purescript-syntax.git"
    [".config/bat/syntaxes/sublime-purescript-syntax".pull]
        args = ["--ff-only"]

[".config/tmux/plugins/tpm"]
    type = "git-repo"
    url = "https://github.com/tmux-plugins/tpm.git"
    [".config/tmux/plugins/tpm".pull]
        args = ["--ff-only"]
```

| Target | Repo | Used by |
| --- | --- | --- |
| `~/.config/nvim` | [prdlk/nvim](https://github.com/prdlk/nvim) | Neovim config, kept in its own repo |
| `~/.config/bat/syntaxes/sublime-purescript-syntax` | [tellnobody1/sublime-purescript-syntax](https://github.com/tellnobody1/sublime-purescript-syntax) | PureScript syntax for bat, compiled into bat's cache by the [bat cache scripts](scripts.md#build-bat-cache) |
| `~/.config/tmux/plugins/tpm` | [tmux-plugins/tpm](https://github.com/tmux-plugins/tpm) | tmux plugin manager, run from the bottom of `tmux.conf` ([tmux](../terminal/tmux.md)). Cloned inside the tmux checkout, whose `.gitignore` excludes `plugins/` |

### No refreshPeriod

No entry in `.chezmoiexternal.toml` sets `refreshPeriod`, so it stays at chezmoi's default of never. chezmoi clones each repo on a fresh machine and otherwise leaves it alone: `chezmoi apply` and `chezmoi update` do not pull. The local nvim checkout always wins over the remote, so in-progress Neovim edits and unpushed commits are never disturbed by an apply.

To update explicitly, run `chezmoi apply --refresh-externals` (`-R`), which pulls with `git pull --ff-only`. `--ff-only` makes the pull fail instead of creating a merge commit when the local checkout has diverged.

## .chezmoiexternals/

Per-app config repos, one file each in `.chezmoiexternals/<app>.toml`. Each is a `git-repo` external with `refreshPeriod = "168h"` and `pull.args = ["--ff-only"]`, so `chezmoi apply` fast-forwards them at most once a week. The repos hold plain config files (no chezmoi prefixes) and are not part of `chezmoi managed` contents. The exceptions are [`agent-root.toml`](#agent-root), a single downloaded script, and [`freellmapi.toml`](#freellmapi), an upstream app checkout.

**.chezmoiexternals/tmux.toml**

```toml
[".config/tmux"]
    type = "git-repo"
    url = "https://github.com/prdlk/tmux.git"
    refreshPeriod = "168h"
    [".config/tmux".pull]
        args = ["--ff-only"]
```

| File | Target | Repo |
| --- | --- | --- |
| `tmux.toml` | `~/.config/tmux` | [prdlk/tmux](https://github.com/prdlk/tmux) |
| `tmux-palette.toml` | `~/.config/tmux-palette` | [prdlk/tmux-palette](https://github.com/prdlk/tmux-palette) |
| `television.toml` | `~/.config/television` | [prdlk/television](https://github.com/prdlk/television) |
| `yazi.toml` | `~/.config/yazi` | [prdlk/yazi](https://github.com/prdlk/yazi) |
| `kitty.toml` | `~/.config/kitty` | [prdlk/kitty](https://github.com/prdlk/kitty) |
| `ghostty.toml` | `~/.config/ghostty` | [prdlk/ghostty](https://github.com/prdlk/ghostty) |
| `herdr.toml` | `~/.config/herdr` | [prdlk/herdr](https://github.com/prdlk/herdr) — `plugins/github/` (runtime plugin checkouts) is gitignored there |
| `omarchy.toml` | `~/.config/omarchy` | [prdlk/omarchy](https://github.com/prdlk/omarchy) — `shell.json`, hooks, menu extensions, themed templates; git-installed themes/plugins are gitignored there and restored by its `install-extras` script, `calendars.json` is never committed |
| `omp.toml` | `~/.omp` | [prdlk/omp](https://github.com/prdlk/omp) — omp agent config and the global agent instructions |

Edit these in place under `~/.config/<app>`, then commit and push from that checkout.

### agent-root

`agent-root.toml` is the one `file` external: chezmoi downloads [jankeesvw/agent-root](https://github.com/jankeesvw/agent-root)'s single bash script to `~/.local/bin/agent-root` (mode `0755`) and re-fetches it at most once a week (`refreshPeriod = "168h"`). Coding agents run `agent-root "<why>" <command>` instead of `sudo`; it wraps `pkexec` (`polkit`) so the session's polkit agent shows the command, and `notify-send` (`libnotify`) shows the reason. Exit 126 means the dialog was dismissed. The usage rules agents follow live in the global omp instructions, `~/.omp/agent/AGENTS.md` ([prdlk/omp](https://github.com/prdlk/omp)). Linux desktop/laptop roles only ([role gate](#chezmoiignoretmpl)), since there is no polkit agent elsewhere.

**.chezmoiexternals/agent-root.toml**

```toml
[".local/bin/agent-root"]
    type = "file"
    url = "https://raw.githubusercontent.com/jankeesvw/agent-root/main/agent-root"
    executable = true
    refreshPeriod = "168h"
```

### freellmapi

`freellmapi.toml` clones upstream [tashfeenahmed/freellmapi](https://github.com/tashfeenahmed/freellmapi) to `~/.local/share/freellmapi`, same `git-repo` settings as the config repos. Nothing is edited there: [`free-router`](../ai/free-router.md) runs it, installing deps and building the dashboard into gitignored paths, so the checkout stays clean and `--ff-only` pulls apply. Linux desktop/laptop roles only ([role gate](#chezmoiignoretmpl)), together with its service.

## Submodules

Two source directories are git submodules, listed in `.gitmodules`. They keep chezmoi source naming and are applied in symlink mode like the rest of the tree. `chezmoi init` clones them.

| Source | Target | Repo |
| --- | --- | --- |
| `dot_config/hypr` | `~/.config/hypr` | [prdlk/hypr](https://github.com/prdlk/hypr) |
| `dot_config/fish` | `~/.config/fish` | [prdlk/fish](https://github.com/prdlk/fish) |

Edit them inside the submodule in the chezmoi source, commit there, then commit the updated submodule pointer in the root repo.

## .chezmoiignore.tmpl

Patterns match target paths (relative to `$HOME`). Matching entries are neither written nor removed. The file is a template, so the desktop block appears only on machines where it applies. Source entries that start with `.` (`.claude/`, `.gitignore`) are ignored by chezmoi without needing a rule.

### Repo docs

```txt
README.md
CLAUDE.md
AGENTS.md
docs
```

Files at the source root that would otherwise land in `$HOME` as `~/README.md` or `~/docs`. This covers the repo README, the agent instruction files, and these docs.

### Compositor hook from the fish submodule

```txt
.config/fish/auto-Niri.fish
```

The shared fish submodule ships a compositor auto-start hook this repo never uses. It is ignored on every machine, outside the role gate.

### Runtime and plugin state inside managed trees

| Pattern | Why |
| --- | --- |
| `.config/lazygit/.omc/**` | Tool state written inside the lazygit config dir |
| `.config/tmux/plugins/**`, except `!.config/tmux/plugins/tpm` | Plugins tpm installs with `prefix I`; tpm itself is the external above |
| `.config/fish/fish_variables` | fish universal variables, rewritten by fish at runtime |
| `.config/fish/conf.d/secrets.fish` | Plaintext credentials. Local-only, never in git (the fish repo's `.gitignore` also lists it) |
| `.config/nvim/lazy-lock.json` | lazy.nvim lockfile inside the nvim external |
| `.config/nvim/.git`, `.config/nvim/.git/**` | The external's git metadata |
| `.config/nvim/.omc/**`, `.config/nvim/.crush/**`, `.config/nvim/.understand-anything/**` | Agent tool state inside the nvim checkout |

`.gitignore` covers the source side of the same problem: `dot_config/lazygit/dot_omc` and `__pycache__/` never get committed even though symlink mode lets tools write into the source tree.

### mise

```txt
.config/mise
.config/mise/**
```

mise tool versions stay local to each machine and are not managed.

### Linux desktop layer (role-gated)

**.chezmoiignore.tmpl**

```txt
{{ if or (ne .chezmoi.os "linux") (and (ne .role "desktop") (ne .role "laptop")) }}
.config/hypr
.config/hypr/**
.config/waybar
.config/waybar/**
.config/uwsm
.config/uwsm/**
.local/bin/agent-root
.config/fontconfig
.config/fontconfig/**
.config/mimeapps.list
.config/xdg-terminals.list
.config/systemd
.config/systemd/**
.local/bin/kitty-day-save
.local/bin/cp-appid
.local/bin/projects-sync
.local/bin/free-router
.local/share/freellmapi
.local/share/freellmapi/**
.config/free-router
.config/free-router/**
{{ end }}
```

The block is emitted, and these paths skipped, unless the OS is `linux` and the role is `desktop` or `laptop`. `server` machines, and any non-Linux machine regardless of role, never receive the Hyprland config (`dot_config/hypr/`), the Waybar config (`dot_config/waybar/`), the uwsm environment (`dot_config/uwsm/`), fontconfig (`dot_config/fontconfig/fonts.conf`), default-app associations (`dot_config/mimeapps.list`, `dot_config/xdg-terminals.list`), the systemd user units (`dot_config/systemd/user/kitty-day-save.service`, `projects-sync.service`, `projects-sync.timer`, `free-router.service`), the `agent-root`, `cp-appid`, `kitty-day-save`, `projects-sync` and `free-router` scripts, or free-router's settings (`dot_config/free-router/env`) and freellmapi checkout.

| Machine | Desktop layer |
| --- | --- |
| Linux, `desktop` or `laptop` | Applied |
| Linux, `server` | Ignored |
| Other OS, any role | Ignored |

See [Desktop](../desktop/README.md) for what the layer contains. The `omarchy-*` scripts in `dot_local/bin/` are not in the block, so they apply on every role.
