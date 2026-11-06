# omarchy

chezmoi source for an [Omarchy](https://omarchy.org) machine (Arch + Hyprland), hosted at <https://prad.codes/env/omarchy>.

Install Omarchy first, then on that machine:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://prad.codes/env/omarchy.git
# or over SSH:
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@prad.codes:env/omarchy.git
```

chezmoi clones the `dot_config/fish` and `dot_config/hypr` submodules during `init`.

First apply prompts once for name, email, and machine role
(`desktop` | `laptop` | `server`, default `desktop`). `desktop` and `laptop` get
the Omarchy layer (Hyprland config, Waybar, uwsm env, fontconfig, mimeapps,
systemd user units, `omarchy-*` scripts); `server` gets the universal toolset only.

## Prerequisites

- **Omarchy** installed (provides Hyprland, Waybar, the `omarchy-*` commands and `yay`).
  `sudo` for pacman; if no `yay`/`paru` exists the install script bootstraps `yay`.
- **Secrets**: `age`-encrypted files need the key at
  `~/.config/chezmoi/key.txt`. Copy it there **before** `chezmoi apply`
  (distributed manually, never committed):

  ```sh
  mkdir -p ~/.config/chezmoi
  scp <existing-machine>:.config/chezmoi/key.txt ~/.config/chezmoi/key.txt
  chmod 600 ~/.config/chezmoi/key.txt
  ```

## What's managed

Universal: fish, bash + zsh (starship prompt, shared aliases), nvim, tmux,
kitty, ghostty, yazi, lazygit, lazydocker, gh (+ extensions), topgrade, git,
ssh config, Claude Code and agent skills.
Packages are declared in `.chezmoidata/packages.yaml` and installed by
`.chezmoiscripts` (idempotent, re-run when the manifest changes).

Aliases are defined once in `.chezmoidata/aliases.yaml` and rendered
into fish (`fish/conf.d/20-aliases.fish`) and bash/zsh
(`~/.config/shell/aliases.sh`, sourced by `.bashrc`/`.zshrc`).

Shell utilities live as standalone sh/bash executables in `~/.local/bin`
so all shells share one implementation; helpers that must mutate shell state
(`cd`-style) are per-shell functions in `fish/functions/`, `bash/functions/`,
and `zsh/functions/`.

Agent skills are not vendored: they all come from
[prdlk/skills](https://github.com/prdlk/skills), and
`.chezmoiscripts/run_onchange_after_25-skills.sh.tmpl` installs every skill in
it with the Skills CLI (removing skills from any other source) whenever
`.chezmoidata/skills.yaml` changes.

Omarchy layer (roles `desktop`/`laptop`): `dot_config/hypr` (submodule),
`dot_config/waybar`, `dot_config/uwsm`, fontconfig, mimeapps,
`xdg-terminals.list`, systemd user units, and the `omarchy-*` scripts in
`dot_local/bin`.

## Submodules and externals

- Submodules: `dot_config/fish` (prdlk/fish), `dot_config/hypr` (prdlk/hypr).
- Externals (`.chezmoiexternals/`): kitty, ghostty, tmux, tmux-palette,
  television, yazi, herdr, omp, omarchy (`~/.config/omarchy`), agent-root,
  plus nvim, tpm and a bat syntax in `.chezmoiexternal.toml`.

`gh` needs `gh auth login` once per machine; the extension install script
skips gracefully until then and re-runs on the next apply.

## Docs

See [`docs/README.md`](docs/README.md). Agent rules for working in this repo: [`AGENTS.md`](AGENTS.md).
