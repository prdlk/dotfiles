# AGENTS.md

Cross-platform chezmoi dotfiles: a self-contained developer environment (shells, editors, terminals, tmux, TUI tools) for Arch, macOS and Ubuntu. Remote: `https://github.com/prdlk/dotfiles` (`git@github.com:prdlk/dotfiles.git`, public), branch `main`.

Location: `~/.local/share/chezmoi`, chezmoi's default source directory: one working tree that chezmoi reads and that you commit from.

`mode = "symlink"`: plain files in `$HOME` are symlinks into this repo, so editing `~/.config/foo/bar` edits `dot_config/foo/bar` directly. Templates (`*.tmpl`), `private_`, `executable_` targets are rendered copies — edit the source, then `chezmoi apply`.

The Omarchy desktop layer (Hyprland, Waybar, uwsm, vicinae, fontconfig, mimeapps, systemd user units, `omarchy-*` scripts, `~/.config/omarchy`) is **not** here: it is the second chezmoi source [env/omarchy-desktop](https://prad.codes/env/omarchy-desktop) at `~/.local/share/omarchy-desktop`, driven by `~/.local/bin/chezmoi-desktop` (own config and state). `.chezmoiscripts/run_after_50-omarchy-desktop.sh` clones and applies it after every apply on machines with `omarchy` on `PATH`. Anything that only makes sense on Omarchy/Hyprland goes there; read its AGENTS.md before editing it.

Config lives in two places. Check which one before editing.

## 1. Local (this repo)

`dot_*` trees committed here. Edit in place, commit here. Docs for each tool are in `docs/`; update the matching page (`docs/**/*.md`) when behavior changes.

- Never edit a rendered copy of a `.tmpl`; edit the `.tmpl` and run `chezmoi apply <path>`.
- Scripts: `.chezmoiscripts/run_*`. Data: `.chezmoidata/*.yaml` (packages, aliases, skills).
- Ignore rules: `.chezmoiignore.tmpl`. Repo docs (`AGENTS.md`, `README.md`, `docs/`) are listed there so they never land in `$HOME`.
- No machine roles: what differs per machine is decided by OS (`.chezmoi.os`, `.chezmoi.osRelease.id`) and, for the desktop layer, by Omarchy being installed.
- Every config here must work on Arch, macOS and Ubuntu, or be gated on `.chezmoi.os` in `.chezmoiignore.tmpl` / the script.

## 2. Externals (`.chezmoiexternals/*.toml`, `.chezmoiexternal.toml`)

`git-repo` externals. chezmoi clones them into `$HOME` when missing and fast-forwards (`--ff-only`) at most every `refreshPeriod`. The source tree holds nothing for these — only the `.toml`.

|Target|Repo|Declared in|
|---|---|---|
|`~/.config/kitty`|prdlk/kitty|`.chezmoiexternals/kitty.toml`|
|`~/.config/television`|prdlk/television|`.chezmoiexternals/television.toml`|
|`~/.config/yazi`|prdlk/yazi|`.chezmoiexternals/yazi.toml`|
|`~/.config/herdr`|prdlk/herdr|`.chezmoiexternals/herdr.toml` (`plugins/github/` gitignored, runtime plugin checkouts)|
|`~/.omp`|prdlk/omp|`.chezmoiexternals/omp.toml`|
|`~/.config/nvim`|prdlk/nvim|`.chezmoiexternal.toml` (no refresh; local checkout wins)|
|`~/.config/tmux/plugins/tpm`|tmux-plugins/tpm|`.chezmoiexternal.toml`|
|`~/.config/bat/syntaxes/sublime-purescript-syntax`|tellnobody1/…|`.chezmoiexternal.toml`|

These stay on their GitHub URLs; they are separate repos, not part of this one. Ghostty (`dot_config/ghostty`), tmux (`dot_config/tmux`) and tmux-palette (`dot_config/tmux-palette`) are local files here, not externals.

Editing: `cd ~/.config/<app>` (the live checkout), edit, commit, push there. Nothing to commit in this repo. Do not `chezmoi add` these paths.

Local working copies under `~/Code/github.com/prdlk/<app>` are ordinary clones of the same repos; `~/.config/<app>` is the one chezmoi manages and the one tools read.

Pulling a remote change before the refresh window: `chezmoi apply --refresh-externals ~/.config/<app>` (or `git pull` in the checkout). `--ff-only` means a diverged local checkout silently stays put — commit or stash first.

## Moving a config out to an external

1. Create the repo, copy the files (strip chezmoi prefixes; a `symlink_x` file becomes a real symlink), commit, push.
2. Add `.chezmoiexternals/<app>.toml` copying `kitty.toml`.
3. `git rm -r dot_config/<app>`; drop any `<app>`-specific lines from `.chezmoiignore.tmpl` / `.gitignore`.
4. `mv ~/.config/<app> /tmp/bak && chezmoi apply --force ~/.config/<app>`; diff against the repo, then delete the backup.
5. Update `docs/` (the tool's page, `docs/terminal/README.md` or sibling index, `docs/chezmoi/externals-and-ignore.md`) and any alias pointing at the old source path (`dot_config/fish/conf.d/20-aliases.fish`, `.chezmoidata/aliases.yaml`).

Moving one back in is the reverse: copy the tracked files into `dot_config/<app>` (with `executable_` prefixes), `git rm` the `.toml`, move the checkout's `.git` aside, `chezmoi apply --force ~/.config/<app>`.

## Packages: every referenced tool must be declared, for every OS

`.chezmoidata/packages.yaml` is the install manifest; the goal is `chezmoi init --apply` on a fresh Arch, macOS or Ubuntu machine yields a working setup. When a config, script, tmux-palette item, television cable `requirements`, or alias starts calling a new binary, declare it in the same change.

`packages.tools` has one entry per tool, saying how each OS gets it (`10-packages`):

|Key|Used on|Installed by|
|---|---|---|
|`arch`|Arch|pacman, only names no installed package provides (`pacman -T`)|
|`aur`|Arch|`yay` or `paru` (yay bootstrapped if neither exists)|
|`brew` / `cask`|macOS|Homebrew formula / cask (Homebrew bootstrapped if missing)|
|`apt`|Ubuntu|`apt-get install`|
|`mise`|Ubuntu, when the entry has no `apt`|`mise use -g <spec>` in `15-tools` (registry short name or backend spec such as `aqua:owner/repo`)|

A key left out means the tool is not installed on that OS. Verify names before committing: `pacman -Si` / the AUR RPC (`https://aur.archlinux.org/rpc/v5/info?arg[]=<pkg>`), `https://formulae.brew.sh/api/formula/<name>.json` (or `cask/`), `https://packages.ubuntu.com/noble/<pkg>`, `mise registry <tool>`. Prefer `mise` over `apt` on Ubuntu when apt's version is years behind or the binary is renamed (`batcat`, `fdfind`).

|Key|Installed by|When|
|---|---|---|
|`shared.cargo`|`15-tools`, after installing rustup if `cargo` is missing|every OS|
|`shared.mise`|`15-tools`: `mise use -g` for tools absent from the global config|every OS|
|`shared.gh_extensions`|`20-gh-extensions` (fish script, so fish config is sourced)|every OS|

CLIs that mise can install (omp, opencode, …) go in `shared.mise`, not a curl installer; `15-tools` curl-installs only rustup and, on Ubuntu, mise itself (`https://mise.run`). `shared.mise` mirrors the global `~/.config/mise/config.toml`: a tool added there with `mise use -g` belongs in the list too. Desktop-only packages (Wayland utilities, GUI apps) belong in env/omarchy-desktop.

## Verify

- `chezmoi diff` empty after apply; on Omarchy also `chezmoi-desktop diff`.
- `chezmoi managed | grep <app>` shows the target.
- Externals: `git -C ~/.config/<app> status -sb` clean and tracking `origin/main`.
- Ubuntu: `docker run --rm -it ubuntu:24.04` with this repo mounted, `chezmoi init --apply` inside.
