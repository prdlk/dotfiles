# Config and OS family

The .chezmoi.toml.tmpl config template, its two prompts, the os-family template, symlink mode, age encryption, and where the resulting data is used.

`.chezmoi.toml.tmpl` is rendered once by `chezmoi init` into `~/.config/chezmoi/chezmoi.toml`. It asks two questions, turns on symlink mode and age encryption, and stores the answers as template data for every other `.tmpl` file. There are no machine roles; per-OS behavior comes from the [os-family template](#os-family).

## Source

**.chezmoi.toml.tmpl**

```toml
{{- $name := promptStringOnce . "name" "Full name" "Prad Nukala" -}}
{{- $email := promptStringOnce . "email" "Email" "prad@sonr.io" -}}

mode = "symlink"
encryption = "age"

[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age19tdqgavaekhvgqsd75n8a09vvshen2ykzy8kw6tenczz73449anqc3l7a6"
    useBuiltin = true

[data]
    name = {{ $name | quote }}
    email = {{ $email | quote }}
```

## Prompts

| Key | Prompt | Type | Default |
| --- | --- | --- | --- |
| `name` | `Full name` | `promptStringOnce` | `Prad Nukala` |
| `email` | `Email` | `promptStringOnce` | `prad@sonr.io` |

The `*Once` functions only prompt when the key is missing from the existing config, so re-running `chezmoi init` keeps earlier answers. `chezmoi init --prompt` forces both prompts again.

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
| `age.identity` | `~/.config/chezmoi/key.txt` | Private key used to decrypt. Distributed by hand between machines, never committed. |
| `age.recipient` | `age19tdqgavaekhvgqsd75n8a09vvshen2ykzy8kw6tenczz73449anqc3l7a6` | Public key files are encrypted to. Safe to publish. |
| `age.useBuiltin` | `true` | Uses chezmoi's built-in age implementation; the `age` binary is not required. |

No source file currently carries the `encrypted_` attribute, so the key is only exercised when a secret is added with `chezmoi add --encrypt`. The [Installation](../installation.md) page still asks for the key to be copied into place before the first apply:

```sh
mkdir -p ~/.config/chezmoi
scp <existing-machine>:.config/chezmoi/key.txt ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt
```

## Template data

The `[data]` table exposes `.name` and `.email` to every template. chezmoi also merges `.chezmoidata/*.yaml` into the same namespace (`.packages`, `.aliases`, `.skills`; see [Data files](data.md)) and provides built-ins such as `.chezmoi.os` and `.chezmoi.osRelease`.

| Variable | Consumed by | Use |
| --- | --- | --- |
| `.name` | `dot_gitconfig.tmpl` | `[user] name` in `~/.gitconfig` |
| `.email` | `dot_gitconfig.tmpl` | `[user] email` in `~/.gitconfig` |
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
