# drydock

drydock fleet view of uncommitted, unpushed, and unreleased work, scanning the ghq root.

drydock lists what is uncommitted, unpushed, and unreleased across every repo under its roots.

| | |
| --- | --- |
| Source | `dot_config/drydock/config.toml` |
| Target | `~/.config/drydock/config.toml` (holds live beside it in `holds.toml`, unmanaged) |
| Packages | Not declared in `packages.yaml`; installed with cargo (`~/.cargo/bin/drydock`) |

## config.toml

**~/.config/drydock/config.toml**

```toml
roots = ["~/Code"]
```

Only `roots` is set; everything else stays at drydock's defaults (`drydock config show` prints the effective config). The root is the ghq root, where repos sit at `<host>/<owner>/<repo>`, within the default `max_depth = 4`. `~/Projects` would find nothing: it holds only symlinks (made by [`projects-sync`](https://prad.codes/env/omarchy-desktop/src/branch/main/docs/scripts.md#projects-sync) in the desktop layer), and drydock does not follow symlinks by default (`follow_symlinks = false`).

`drydock --root <path>` replaces the configured roots for one run.
