# AGENTS.md

chezmoi source for `$HOME` on [Omarchy](https://omarchy.org) (Arch + Hyprland). Remote: `https://prad.codes/env/omarchy` (`git@prad.codes:env/omarchy.git`), branch `main`.

Location: `~/Code/prad.codes/env/omarchy`. chezmoi uses it as its source either via `chezmoi init --source ~/Code/prad.codes/env/omarchy` or by cloning it into `~/.local/share/chezmoi` — the same checkout model either way: one working tree that chezmoi reads and that you commit from.

`mode = "symlink"`: plain files in `$HOME` are symlinks into this repo, so editing `~/.config/foo/bar` edits `dot_config/foo/bar` directly. Templates (`*.tmpl`), `private_`, `executable_` targets are rendered copies — edit the source, then `chezmoi apply`.

Config lives in three places. Check which one before editing.

## 1. Local (this repo)

`dot_*` trees committed here. Edit in place, commit here. Docs for each tool are in `docs/`; update the matching page (`docs/**/*.md`) when behavior changes.

- Never edit a rendered copy of a `.tmpl`; edit the `.tmpl` and run `chezmoi apply <path>`.
- Scripts: `.chezmoiscripts/run_*`. Data: `.chezmoidata/*.yaml` (packages, aliases, skills).
- Ignore rules: `.chezmoiignore.tmpl`. Repo docs (`AGENTS.md`, `README.md`, `docs/`) are listed there so they never land in `$HOME`.
- Roles: `desktop` (default), `laptop`, `server`. Desktop/laptop get the Omarchy layer (hypr, waybar, uwsm, fontconfig, mimeapps, systemd user units, `omarchy-*` scripts); `server` gets the universal toolset only.

## 2. Submodules (`.gitmodules`)

| Path | Repo |
| --- | --- |
| `dot_config/fish` | prdlk/fish |
| `dot_config/hypr` | prdlk/hypr |

Still applied by chezmoi like local files, but the git history is separate:

1. `cd dot_config/<app>`, edit, commit, push there.
2. `cd` back to the root and commit the updated submodule pointer.

Fresh clone: `git submodule update --init` (chezmoi does this on `init`).

## 3. Externals (`.chezmoiexternals/*.toml`, `.chezmoiexternal.toml`)

`git-repo` externals. chezmoi clones them into `$HOME` when missing and fast-forwards (`--ff-only`) at most every `refreshPeriod`. The source tree holds nothing for these — only the `.toml`.

| Target | Repo | Declared in |
| --- | --- | --- |
| `~/.config/kitty` | prdlk/kitty | `.chezmoiexternals/kitty.toml` |
| `~/.config/ghostty` | prdlk/ghostty | `.chezmoiexternals/ghostty.toml` |
| `~/.config/tmux` | prdlk/tmux | `.chezmoiexternals/tmux.toml` |
| `~/.config/tmux-palette` | prdlk/tmux-palette | `.chezmoiexternals/tmux-palette.toml` |
| `~/.config/television` | prdlk/television | `.chezmoiexternals/television.toml` |
| `~/.config/yazi` | prdlk/yazi | `.chezmoiexternals/yazi.toml` |
| `~/.config/herdr` | prdlk/herdr | `.chezmoiexternals/herdr.toml` (`plugins/github/` gitignored, runtime plugin checkouts) |
| `~/.config/omarchy` | prdlk/omarchy | `.chezmoiexternals/omarchy.toml` (git themes/plugins live in its `extras.txt`, not this repo) |
| `~/.omp` | prdlk/omp | `.chezmoiexternals/omp.toml` |
| `~/.local/bin/agent-root` | jankeesvw/agent-root (one `file` external, not a checkout; no edits, upstream script) | `.chezmoiexternals/agent-root.toml` (desktop/laptop roles only) |
| `~/.config/nvim` | prdlk/nvim | `.chezmoiexternal.toml` (no refresh; local checkout wins) |
| `~/.config/tmux/plugins/tpm` | tmux-plugins/tpm | `.chezmoiexternal.toml` |
| `~/.config/bat/syntaxes/sublime-purescript-syntax` | tellnobody1/… | `.chezmoiexternal.toml` |

These stay on their GitHub URLs; they are separate repos, not part of this one.

Editing: `cd ~/.config/<app>` (the live checkout), edit, commit, push there. Nothing to commit in this repo. Do not `chezmoi add` these paths.

Local working copies under `~/Code/github.com/prdlk/<app>` are ordinary clones of the same repos; `~/.config/<app>` is the one chezmoi manages and the one tools read.

Pulling a remote change before the refresh window: `chezmoi apply --refresh-externals ~/.config/<app>` (or `git pull` in the checkout). `--ff-only` means a diverged local checkout silently stays put — commit or stash first.

## Moving a config out to an external

1. Create the repo, copy the files (strip chezmoi prefixes; a `symlink_x` file becomes a real symlink), commit, push.
2. Add `.chezmoiexternals/<app>.toml` copying `tmux.toml`.
3. `git rm -r dot_config/<app>`; drop any `<app>`-specific lines from `.chezmoiignore.tmpl` / `.gitignore`.
4. `mv ~/.config/<app> /tmp/bak && chezmoi apply --force ~/.config/<app>`; diff against the repo, then delete the backup.
5. Update `docs/` (the tool's page, `docs/terminal/README.md` or sibling index, `docs/chezmoi/externals-and-ignore.md`) and any alias pointing at the old source path (`dot_config/fish/conf.d/20-aliases.fish`, `.chezmoidata/aliases.yaml`).

## Packages: every referenced tool must be declared

`.chezmoidata/packages.yaml` is the install manifest; the goal is `chezmoi init --apply` on a fresh Omarchy machine yields a working setup. When a config, script, tmux-palette item, television cable `requirements`, or Hyprland binding starts calling a new binary, declare its package in the same change:

| Key | Installed by | When |
| --- | --- | --- |
| `arch.pacman` / `arch.aur` | `10-packages` (pacman / `yay` or `paru`; yay bootstrapped if neither exists) | every role |
| `arch.desktop.pacman` / `.aur` | same | roles `desktop`, `laptop` |
| `arch.desktop.omarchy` | pacman, only if `pacman-conf -l` lists `omarchy` | Omarchy machines |
| `shared.cargo` | `15-tools`, after installing rustup if `cargo` is missing | every role |
| `shared.mise` | `15-tools`: `mise use -g` for tools absent from the global config | every role |
| `shared.gh_extensions` | `20-gh-extensions` (fish script, so fish config is sourced) | every role |

Find the package with `pacman -Qo "$(command -v <bin>)"`; `pacman -Qm` lists AUR/foreign packages, `pacman -Si <pkg>` shows the repo (`extra` vs `omarchy`). Verify names before committing: `pacman -Si` for repo packages, `https://aur.archlinux.org/rpc/v5/info?arg[]=<pkg>` for AUR, `mise registry <tool>` for mise (no registry entry: use a backend spec such as `github:owner/repo`). Hyprland/Waybar/`omarchy-*` come with Omarchy and are not declared. CLIs that mise can install (omp, opencode, …) go in `shared.mise`, not a curl installer; `15-tools` curl-installs only rustup and strata. `shared.mise` mirrors the global `~/.config/mise/config.toml`: a tool added there with `mise use -g` belongs in the list too.

## Verify

- `chezmoi diff` empty after apply.
- `chezmoi managed | grep <app>` shows the target.
- Externals: `git -C ~/.config/<app> status -sb` clean and tracking `origin/main`.
