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

`.name` and `.email` come from `.chezmoidata/user.yaml`; they are not prompted. No OS condition changes this file.

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

The `[delta]` section is not a pager setting; delta reads it whenever it runs. Here that means diffnav and [lazygit](lazygit.md). Layout lives in `[delta]`. Colors live in two features: `features = dark` makes `[delta "dark"]` the default, and `--features=light` on the command line selects `[delta "light"]` instead. On Omarchy, lazygit passes `--features=<theme mode>`, so diffs follow the theme there. diffnav always gets `dark`.

| `[delta]` option | Value |
| --- | --- |
| `features` | `dark` |
| `tabs` | `2` |
| `file-style` / `file-decoration-style` | `omit` / `none` (no file header) |
| `line-numbers-left-format` | `"{nm:>4} "` |
| `line-numbers-right-format` | `"│ {np:>4} "` |
| `line-numbers-left-style`, `-zero-style`, `-plus-style`, `-minus-style` | `white dim` (ANSI, so the terminal palette decides) |
| `wrap-left-symbol`, `wrap-right-symbol`, `wrap-right-prefix-symbol` | a single space each (wrap markers hidden) |
| `hunk-label` | a Nerd Font glyph |

| Feature option | `dark` | `light` |
| --- | --- | --- |
| mode | `dark = true` | `light = true` |
| `syntax-theme` | delta's default | `ansi` (the terminal's 16 colors: Hazy Peak's graphite) |
| `line-numbers-right-style` | `"#1f2335" dim` | `"#aeaeae"` |
| `plus-style` / `plus-emph-style` | `syntax "#0e250e"` / `syntax "#103610"` | `syntax "#bababa"` / `syntax "#a8a8a8"` |
| `minus-style` / `minus-emph-style` | `syntax "#402a26"` / `syntax "#45221c"` | `syntax "#d4bcbc"` / `syntax "#d9a9a9"` |
| `hunk-header-line-number-style` | `"#10233A"` | `"#474747"` |
| `hunk-header-style` / `-file-style` | `"#868E99"` / `"#868E99" dim` | `"#727272"` / `"#727272" dim` |
| `hunk-header-decoration-style` | `"#163050" ol ul` | `"#aeaeae" ol ul` |

Added and removed lines keep syntax highlighting (`syntax` foreground). Dark puts them on dark green and dark red. Light puts them on grey and on Hazy Peak's `#c67777` red mixed into the fog.

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
