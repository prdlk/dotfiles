# Config and roles

The .chezmoi.toml.tmpl config template, its three prompts, symlink mode, age encryption, and where the resulting data is used.

`.chezmoi.toml.tmpl` is rendered once by `chezmoi init` into `~/.config/chezmoi/chezmoi.toml`. It asks three questions, turns on symlink mode and age encryption, and stores the answers as template data for every other `.tmpl` file.

## Source

**.chezmoi.toml.tmpl**

```toml
{{- $name := promptStringOnce . "name" "Full name" "Prad Nukala" -}}
{{- $email := promptStringOnce . "email" "Email" "prad@sonr.io" -}}
{{- $roleDefault := "desktop" -}}
{{- $role := promptChoiceOnce . "role" "Machine role" (list "desktop" "laptop" "server") $roleDefault -}}

mode = "symlink"
encryption = "age"

[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age19tdqgavaekhvgqsd75n8a09vvshen2ykzy8kw6tenczz73449anqc3l7a6"
    useBuiltin = true

[data]
    name = {{ $name | quote }}
    email = {{ $email | quote }}
    role = {{ $role | quote }}
```

## Prompts

| Key | Prompt | Type | Default |
| --- | --- | --- | --- |
| `name` | `Full name` | `promptStringOnce` | `Prad Nukala` |
| `email` | `Email` | `promptStringOnce` | `prad@sonr.io` |
| `role` | `Machine role` | `promptChoiceOnce` from `desktop`, `laptop`, `server` | `desktop` |

The `*Once` functions only prompt when the key is missing from the existing config, so re-running `chezmoi init` keeps earlier answers. `chezmoi init --prompt` forces all three prompts again. Changing the role changes the rendered ignore file and package script, so the next `chezmoi apply` adds or drops the desktop layer and re-runs the package install.

### Machine roles

| Role | Intended platform | Linux desktop layer | Desktop packages (`packages.arch.desktop`) |
| --- | --- | --- | --- |
| `desktop` | Arch Linux | Applied | Installed |
| `laptop` | Arch Linux | Applied | Installed |
| `server` | Omarchy/Arch Linux, headless | Skipped | Skipped |

`desktop` and `laptop` behave identically in the current templates; nothing branches on one without the other. The desktop layer is also skipped whenever the OS is not Linux, whatever the role. See [the ignore rules](externals-and-ignore.md#chezmoiignoretmpl) for the exact list of gated paths.

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

The `[data]` table exposes `.name`, `.email`, and `.role` to every template. chezmoi also merges `.chezmoidata/*.yaml` into the same namespace (`.packages`, `.aliases`; see [Packages and aliases](data.md)) and provides built-ins such as `.chezmoi.os`.

| Variable | Consumed by | Use |
| --- | --- | --- |
| `.name` | `dot_gitconfig.tmpl` | `[user] name` in `~/.gitconfig` |
| `.email` | `dot_gitconfig.tmpl` | `[user] email` in `~/.gitconfig` |
| `.role` | `.chezmoiignore.tmpl` | Skips the Linux desktop layer unless role is `desktop` or `laptop` |
| `.role` | `.chezmoiscripts/run_onchange_before_10-packages.sh.tmpl` | Adds the `arch.desktop` pacman and AUR packages for `desktop`/`laptop` |
| `.chezmoi.os` | `.chezmoi.toml.tmpl` | Role default (`desktop`) |
| `.chezmoi.os` | `.chezmoiignore.tmpl` | Desktop layer requires `linux` |
| `.chezmoi.os` | `run_onchange_before_10-packages.sh.tmpl` | pacman/yay on `linux` |
| `.chezmoi.os` | `run_once_after_30-user-services.sh.tmpl` | systemd user units on `linux` only |
| `.chezmoi.os` | `run_onchange_after_40-post.sh.tmpl` | `fc-cache` on `linux` only |
| `.chezmoi.os`, `.role` | `run_onchange_after_15-tools.sh.tmpl` | strata install on `linux` with role `desktop`/`laptop` |

**dot_gitconfig.tmpl**

```ini
[user]
	email = {{ .email }}
	name = {{ .name }}
```

The rest of `~/.gitconfig` is covered under [Tools](../tools/README.md).
