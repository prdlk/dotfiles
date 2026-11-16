# Externals and ignore rules

The git repos chezmoi clones into $HOME, the pull arguments every external uses, and every rule in .chezmoiignore.tmpl. This repo has no git submodules: fish (`dot_config/fish`), tmux and tmux-palette are plain files here.

## .chezmoiexternal.toml

Externals are content chezmoi fetches instead of storing in the repo. Every entry is a `git-repo` external: chezmoi runs `git clone` when the target directory is missing. Because they are real git checkouts, they are never symlinked into the source tree. A target that already exists without being a checkout (Omarchy's stock `~/.config/kitty`, for example) would stop the apply; [`05-externals`](scripts.md#05-externals) asks to move it aside and clones the repo in its place first.

**.chezmoiexternal.toml**

```toml
[".config/nvim"]
    type = "git-repo"
    url = "https://github.com/prdlk/nvim.git"
    [".config/nvim".pull]
        args = ["--ff-only", "--no-rebase"]

[".config/bat/syntaxes/sublime-purescript-syntax"]
    type = "git-repo"
    url = "https://github.com/tellnobody1/sublime-purescript-syntax.git"
    [".config/bat/syntaxes/sublime-purescript-syntax".pull]
        args = ["--ff-only", "--no-rebase"]

[".config/tmux/plugins/tpm"]
    type = "git-repo"
    url = "https://github.com/tmux-plugins/tpm.git"
    [".config/tmux/plugins/tpm".pull]
        args = ["--ff-only", "--no-rebase"]
```

| Target | Repo | Used by |
| --- | --- | --- |
| `~/.config/nvim` | [prdlk/nvim](https://github.com/prdlk/nvim) | Neovim config, kept in its own repo |
| `~/.config/bat/syntaxes/sublime-purescript-syntax` | [tellnobody1/sublime-purescript-syntax](https://github.com/tellnobody1/sublime-purescript-syntax) | PureScript syntax for bat, compiled into bat's cache by the [bat cache scripts](scripts.md#build-bat-cache) |
| `~/.config/tmux/plugins/tpm` | [tmux-plugins/tpm](https://github.com/tmux-plugins/tpm) | tmux plugin manager, run from the bottom of `tmux.conf` ([tmux](../terminal/tmux.md)). Cloned into `~/.config/tmux/plugins/`, a directory chezmoi otherwise ignores |

tmux itself is not an external: `dot_config/tmux` and `dot_config/tmux-palette` are local files in this repo, symlinked into `~/.config`. tpm is the only external under `~/.config/tmux`.

### No refreshPeriod

No entry in `.chezmoiexternal.toml` sets `refreshPeriod`, so it stays at chezmoi's default of never. chezmoi clones each repo on a fresh machine and otherwise leaves it alone: `chezmoi apply` and `chezmoi update` do not pull. The local nvim checkout always wins over the remote, so in-progress Neovim edits and unpushed commits are never disturbed by an apply.

To update explicitly, run `chezmoi apply --refresh-externals` (`-R`), which pulls with `git pull --ff-only --no-rebase`.

### Pull arguments

Every git-repo external, here and in `.chezmoiexternals/`, pulls with `args = ["--ff-only", "--no-rebase"]`. `--ff-only` makes the pull fail instead of creating a merge commit when the checkout has diverged. `--no-rebase` overrides the user's `pull.rebase=true`: with that setting a plain `git pull --ff-only` refuses any checkout that has uncommitted edits, and the failure aborted the whole apply.

## .chezmoiexternals/

Per-app config repos, one file each in `.chezmoiexternals/<app>.toml`. Each is a `git-repo` external with `refreshPeriod = "168h"` and `pull.args = ["--ff-only", "--no-rebase"]`, so `chezmoi apply` fast-forwards them at most once a week. The repos hold plain config files (no chezmoi prefixes) and are not part of `chezmoi managed` contents.

**.chezmoiexternals/kitty.toml**

```toml
[".config/kitty"]
    type = "git-repo"
    url = "https://github.com/prdlk/kitty.git"
    refreshPeriod = "168h"
    [".config/kitty".pull]
        args = ["--ff-only", "--no-rebase"]
```

| File | Target | Repo |
| --- | --- | --- |
| `television.toml` | `~/.config/television` | [prdlk/television](https://github.com/prdlk/television) |
| `yazi.toml` | `~/.config/yazi` | [prdlk/yazi](https://github.com/prdlk/yazi) |
| `kitty.toml` | `~/.config/kitty` | [prdlk/kitty](https://github.com/prdlk/kitty) |
| `herdr.toml` | `~/.config/herdr` | [prdlk/herdr](https://github.com/prdlk/herdr) — `plugins/github/` (runtime plugin checkouts) is gitignored there |
| `omp.toml` | `~/.omp` | [prdlk/omp](https://github.com/prdlk/omp) — omp agent config and the global agent instructions |

Edit these in place under `~/.config/<app>`, then commit and push from that checkout.

The Omarchy-only externals (`~/.config/omarchy`, `agent-root`, freellmapi) are declared by the [desktop layer](https://prad.codes/env/omarchy-desktop/src/branch/main/README.md#externals), not here.

## .chezmoiignore.tmpl

Patterns match target paths (relative to `$HOME`). Matching entries are neither written nor removed. The file is still named `.tmpl` but has no conditional blocks: the same rules apply on every OS. Source entries that start with `.` (`.claude/`, `.gitignore`) are ignored by chezmoi without needing a rule.

### Repo docs

```txt
README.md
CLAUDE.md
AGENTS.md
docs
```

Files at the source root that would otherwise land in `$HOME` as `~/README.md` or `~/docs`. This covers the repo README, the agent instruction files, and these docs.

### Niri compositor hook in the fish config

```txt
.config/fish/auto-Niri.fish
```

`dot_config/fish/auto-Niri.fish` is a compositor auto-start hook for niri machines, kept from the fish repo this config came from. It is ignored on every machine.

### Runtime and plugin state inside managed trees

| Pattern | Why |
| --- | --- |
| `.config/lazygit/.omc/**` | Tool state written inside the lazygit config dir |
| `.config/tmux/plugins/**`, except `!.config/tmux/plugins/tpm` | Plugins cloned by [45-tmux-plugins](scripts.md#45-tmux-plugins) (or tpm's `prefix I`); tpm itself is the external above |
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

### No desktop gate

Earlier versions gated the Linux desktop layer (Hyprland, Waybar, uwsm, fontconfig, systemd units, `omarchy-*` scripts, free-router) by machine role here. That layer now lives in [env/omarchy-desktop](https://prad.codes/env/omarchy-desktop) and is applied by its own chezmoi, started from [`run_after_50-omarchy-desktop.sh`](scripts.md#50-omarchy-desktop) only on Omarchy machines. Nothing in this file depends on the OS or the machine.
