# Git

Global git config with templated identity, three diff pagers, an nvim difftool, and gh/tea credential helpers.

Git's global config is a single chezmoi template. It sets the commit identity from chezmoi data, routes diffs through diffnav and git-split-diffs, styles delta for the tools that call it, and delegates HTTPS credentials to `gh` and `tea`.

| | |
| --- | --- |
| Source | `dot_gitconfig.tmpl` |
| Target | `~/.gitconfig` |
| Type | Template (rendered, so it is written as a regular file, not a symlink) |
| Packages | `git`, `git-delta`, `diffnav` (pacman) |

> [!WARNING]
> `git-split-diffs` (the `core.pager`) is not declared in `packages.yaml`; install it separately.

## Identity

**~/.gitconfig**

```ini
[user]
	email = {{ .email }}
	name = {{ .name }}
```

`.name` and `.email` are prompted once by `.chezmoi.toml.tmpl` on the first `chezmoi init` and stored in the local chezmoi config. No role or OS condition changes this file.

## Pagers

Three pagers are configured, each for a different path:

| Setting | Value | Applies to |
| --- | --- | --- |
| `pager.diff` | `diffnav` | `git diff`: file-tree diff viewer built on delta |
| `core.pager` | `git-split-diffs --color`, piped into `less -+LFX` | Every other paged command (`git log -p`, `git show`, ...) |
| `[split-diffs] min-line-width` | `40` | git-split-diffs side-by-side threshold |
| `[split-diffs] theme-name` | `dark` | git-split-diffs theme |

`less -+LFX` resets the `-L`, `-F`, and `-X` flags, so less always takes over the screen and never exits early on short output.

### delta styling

The `[delta]` section is not a pager setting; delta reads it whenever it runs. Here that means diffnav and [lazygit](lazygit.md), which renders diffs with `delta --dark --paging=never`.

| Option | Value |
| --- | --- |
| `dark` | `true` |
| `tabs` | `2` |
| `file-style` / `file-decoration-style` | `omit` / `none` (no file header) |
| `line-numbers-left-format` | `"{nm:>4} "` |
| `line-numbers-right-format` | `"│ {np:>4} "` |
| `line-numbers-left-style` | `white dim` |
| `line-numbers-right-style` | `"#1f2335" dim` |
| `line-numbers-zero-style`, `-plus-style`, `-minus-style` | `white dim` |
| `wrap-left-symbol`, `wrap-right-symbol`, `wrap-right-prefix-symbol` | a single space each (wrap markers hidden) |
| `plus-style` | `syntax "#0e250e"` |
| `plus-emph-style` | `syntax "#103610"` |
| `minus-style` | `syntax "#402a26"` |
| `minus-emph-style` | `syntax "#45221c"` |
| `hunk-label` | a Nerd Font glyph |
| `hunk-header-line-number-style` | `"#10233A"` |
| `hunk-header-style` | `"#868E99"` |
| `hunk-header-file-style` | `"#868E99" dim` |
| `hunk-header-decoration-style` | `"#163050" ol ul` |

Added and removed lines keep syntax highlighting (`syntax` foreground) on dark green and dark red backgrounds.

## Difftool

**~/.gitconfig**

```ini
[diff]
	tool = codediff
[difftool "codediff"]
	cmd = nvim \"$LOCAL\" \"$REMOTE\" +\"CodeDiff file $LOCAL $REMOTE\"
```

`git difftool` opens both versions in [Neovim](neovim.md) and runs the `:CodeDiff` command, which comes from the external nvim config. Lazygit's `openDiffTool` binding (`<c-t>`) uses the same tool.

## Remotes and push

| Setting | Value | Effect |
| --- | --- | --- |
| `url "git@github.com:".pushInsteadOf` | `https://github.com/` | Remotes cloned over HTTPS push over SSH; fetches stay on HTTPS. |
| `push.autoSetupRemote` | `true` | First `git push` on a new branch sets its upstream automatically. |
| `advice.addIgnoredFile` | `false` | Silences the hint when `git add` touches an ignored path. |
| `beads.role` | `maintainer` | Role read by the beads (`bd`) issue tracker. |

## Credential helpers

Each host block first sets an empty `helper =`, which clears any helper inherited from system config, then adds one helper:

| Host | Helper | Notes |
| --- | --- | --- |
| `https://github.com` | `!gh auth git-credential` | Uses the token from `gh auth login`. See [GitHub CLI](github-cli.md). |
| `https://gist.github.com` | `!gh auth git-credential` | Same as above, for gists. |
| `https://prad.codes` | `!tea login helper` | Self-hosted Gitea; uses the login stored by the `tea` CLI. |

No credentials are stored in the file itself.

## Related helpers

These git-adjacent commands live in `~/.local/bin` and the shell function directories. See [shell scripts](../shell/scripts.md) for the full set.

| Command | What it does |
| --- | --- |
| `gdc` | Asks for confirmation with `gum confirm`, then runs `git reset --hard HEAD` and `git clean -fd`. |
| `gop` | Opens a repo's web page for any forge whose layout is `https://<host>/<owner>/<repo>`; defaults to `origin`, then `upstream`. Also the <kbd>ctrl-b</kbd> action of the `ghq-repos` [television](television.md#ghq-repos) cable. |
| `git-summary` | Aggregates every `AGENTS.md` in the current repo through `code2prompt`. |
| `ghg` / `ghg-clone` | `ghq get` a repo and `cd` into the clone; sets up a prad.codes pull mirror (your GitHub repos) or GitHub push mirror (prad.codes repos) when none exists. |
| `ghn` | Creates a private repo on prad.codes (via `tea`) or github.com (via `gh`), clones it with ghq, and `cd`s into it. |
| `gho` | Picks a ghq repo or Obsidian vault with the `ghq-repos` [television](television.md#ghq-repos) cable and `cd`s into it. |
