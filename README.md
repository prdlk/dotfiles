# dotfiles

My dev environment for Arch, macOS and Ubuntu, managed with [chezmoi](https://chezmoi.io).

## Install

```sh
gh auth login   # private config repos need GitHub access
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply prdlk/dotfiles
```

It asks two things:

1. **Master password**: decrypts secrets. Press enter to skip them.
2. **Software**: everything is ticked; `x` unticks, enter installs.

## Update

```sh
chezmoi update
```

More in [docs](docs/README.md).
