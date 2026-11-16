# Config and OS family

The .chezmoi.toml.tmpl config template, its master password and software picker, the os-family template, symlink mode, age encryption, and where the resulting data is used.

`.chezmoi.toml.tmpl` is rendered by `chezmoi init` into `~/.config/chezmoi/chezmoi.toml`. It decrypts the age key with the master password, asks which software to install, turns on symlink mode and age encryption, and stores the choice as template data. There are no machine roles; per-OS behavior comes from the [os-family template](#os-family). The git name and email are fixed in `.chezmoidata/user.yaml`, not asked.

## Prompts

`chezmoi init` asks two things, in this order.

### Master password

Asked once per machine, before anything else: when `~/.config/chezmoi/key.txt` does not exist and the source has `key.txt.age`. The template reads the password from the terminal (`/dev/tty`, not echoed) and pipes it to `chezmoi --no-tty age decrypt --passphrase --output ~/.config/chezmoi/key.txt key.txt.age`, then makes the key mode 600. A wrong password asks again, up to three times.

Enter alone skips the secrets; so do three wrong tries and running without a terminal (a script, a container without `-it`). Without the key, `.chezmoiignore.tmpl` lists every `encrypted_` source file's target, so `chezmoi apply` leaves them out instead of failing to decrypt them. A later `chezmoi init` asks for the password again.

Encrypted today: `~/.ssh/id_ed25519` and `id_ed25519.pub`, `~/.config/fish/conf.d/secrets.fish`, and `~/.config/free-router/env` (also ignored off Omarchy). Edit one with `chezmoi edit <target>`; add one with `chezmoi add --encrypt <target>`.

`key.txt.age` is the age identity encrypted with the password (age's scrypt passphrase mode) and committed; `.chezmoiignore.tmpl` keeps it out of `$HOME`. The repo is public, so the password is the only protection of every secret in it: use a long one. To change it, re-encrypt the key on a machine that has it and commit the result:

```sh
chezmoi age encrypt --passphrase --output "$(chezmoi source-path)/key.txt.age" ~/.config/chezmoi/key.txt
```

### Software selection

A multi-select of everything `.chezmoidata/packages.yaml` can install: each `packages.tools` `name` (entries sharing a name are one choice, such as mdfried and its Ubuntu build libraries), each cargo crate, each global mise tool (by its spec's last path segment, `oh-my-pi`), and each gh extension (by repo name, `gh-commit`). Entries marked `core: true` (git, curl, the build tools, jq, mise) are always installed and not offered. `x` toggles, `←`/`→` page, `ctrl+a` selects all, enter confirms.

The choices left unticked are stored as `data.skip`; `.chezmoitemplates/packages` turns the manifest minus `skip` into the lists the [install scripts](scripts.md) use. Storing what to skip, not what to install, means a package added to the manifest later is installed everywhere without re-running init.

`chezmoi init` asks again, with the previous answer preselected and anything new ticked. `chezmoi init --promptDefaults` keeps the previous answer without asking. The next `chezmoi apply` installs what was added; nothing is uninstalled when a choice is removed.

## Source

**.chezmoi.toml.tmpl** (after the prompts above)

```toml
mode = "symlink"
encryption = "age"

[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1v6j26xeydxgn5vtv2unjszd5aq6a0l6s50plc6x539u95usmhyeqxcup96"
    useBuiltin = true

[data]
    skip = {{ $skip | toToml }}
```

## os-family

`.chezmoitemplates/os-family` renders to one word that scripts and templates use to pick a package manifest. Call it with `{{ template "os-family" . }}` (or `includeTemplate "os-family" .` to store the result).

| Output | Machines |
| --- | --- |
| `arch` | Linux whose `osRelease.id` or `idLike` contains `arch`: Arch and derivatives such as Omarchy |
| `debian` | Linux whose `id` or `idLike` contains `debian` or `ubuntu`: Ubuntu, Debian and derivatives |
| `darwin` | macOS |
| empty | Anything else; the package script prints a warning and installs nothing |

What differs by family is covered in [Apply scripts](scripts.md) and [Data files](data.md#per-os-install-keys). The Omarchy desktop layer is not selected here: [`run_after_50-omarchy-desktop.sh`](scripts.md#50-omarchy-desktop) checks for the `omarchy` command at run time.

## Mode

`mode = "symlink"` makes `chezmoi apply` link plain files in `$HOME` back to the source tree. Templates, `private_`, `executable_`, and encrypted files are still written as real files. The [overview](README.md#symlink-mode) covers the editing consequences.

## Age encryption

| Setting | Value | Effect |
| --- | --- | --- |
| `encryption` | `"age"` | `chezmoi add --encrypt` and `encrypted_` source files use age. |
| `age.identity` | `~/.config/chezmoi/key.txt` | Private key used to decrypt, written by the [master password](#master-password) prompt from `key.txt.age`. Never committed in plain text. |
| `age.recipient` | `age1v6j26xeydxgn5vtv2unjszd5aq6a0l6s50plc6x539u95usmhyeqxcup96` | Public key files are encrypted to. Safe to publish. |
| `age.useBuiltin` | `true` | Uses chezmoi's built-in age implementation; the `age` binary is not required. |

Add a secret with `chezmoi add --encrypt <file>`: the source gets an `encrypted_` file, every machine that has the key decrypts it on apply, and machines that skipped the password leave it out ([Master password](#master-password)).

## Template data

`.chezmoidata/*.yaml` is merged into the template data (`.name` and `.email` from `user.yaml`, `.packages`, `.aliases`, `.skills`; see [Data files](data.md)), next to the config's `[data]` (`.skip`) and built-ins such as `.chezmoi.os` and `.chezmoi.osRelease`.

| Variable | Consumed by | Use |
| --- | --- | --- |
| `.name` | `dot_gitconfig.tmpl` | `[user] name` in `~/.gitconfig` |
| `.email` | `dot_gitconfig.tmpl` | `[user] email` in `~/.gitconfig` |
| `.skip` | `.chezmoitemplates/packages` | Software left out at init; filters every install script |
| `os-family` | `run_onchange_before_10-packages.sh.tmpl` | Chooses pacman + AUR, Homebrew or apt |
| `os-family` | `run_onchange_after_15-tools.sh.tmpl` | Installs mise on Ubuntu and adds the `mise` specs of `packages.tools`; sources Homebrew's environment on macOS |
| `.chezmoi.os` | `run_onchange_after_40-post.sh.tmpl` | `fc-cache` on `linux` only |
| `.chezmoi.osRelease` | `run_onchange_before_10-packages.sh.tmpl` | Ubuntu codename for the tailscale repo |

**dot_gitconfig.tmpl**

```ini
[user]
	email = {{ .email }}
	name = {{ .name }}
```

The rest of `~/.gitconfig` is covered under [Tools](../tools/README.md).
