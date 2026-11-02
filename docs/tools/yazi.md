# Yazi

Yazi file manager config — layout, openers, bat previews, keymap, plugins, flavors, and the Neovim bridge.

[Yazi](https://yazi-rs.github.io) is a terminal file manager. It is the default way to browse files here: shell keybindings, aliases, and a kitty shortcut all open it, and it hands files to Neovim.

| | |
| --- | --- |
| Source | [prdlk/yazi](https://github.com/prdlk/yazi) via `.chezmoiexternals/yazi.toml` (`git-repo`, pulled `--ff-only` every 168h) |
| Target | `~/.config/yazi/` (git checkout; edit in place, commit and push from there) |
| Files | `yazi.toml`, `keymap.toml`, `init.lua`, `package.toml`, `theme.toml`, `vfs.toml`, `flavors/{cyberdream,ii-auto}.yazi/flavor.toml`, `plugins/bunny.yazi/` (vendored) |
| Helper | `dot_local/bin/executable_yazi-nvim-open` → `~/.local/bin/yazi-nvim-open` |
| Packages | `yazi` plus preview backends `ffmpeg`, `ffmpegthumbnailer`, `poppler`, `resvg`, `imagemagick`, `7zip`, `unzip` |
| Plugins | `run_onchange_after_install-yazi-plugins.sh.tmpl` → `ya pkg install` |

The whole directory is a symlink into the source tree, so edits apply without `chezmoi apply`.

```text
yazi/
  yazi.toml
  keymap.toml
  init.lua
  package.toml
  theme.toml
  vfs.toml
  flavors/
    cyberdream.yazi/
      flavor.toml
    ii-auto.yazi/
      flavor.toml
  plugins/
    bunny.yazi/
```

## yazi.toml

Plain TOML, not a template. The `open` opener runs `xdg-open`.

**~/.config/yazi/yazi.toml**

```toml
[mgr]
ratio = [0, 2, 6]

[opener]
play = [
	{ run = "mpv %s", orphan = true, for = "unix" },
]
edit = [
	{ run = 'yazi-nvim-open %s', block = true, for = "unix" },
]
open = [
	{ run = "xdg-open %s1", desc = "Open" },
]

[open]
prepend_rules = [
	{ url = "*.{md,markdown}", use = [ "fry", "edit", "open" ] },
]

[[plugin.prepend_previewers]]
mime = "text/*"
run = 'piper -- bat -p --color=always --terminal-width=$w "$1"'

[[plugin.prepend_previewers]]
mime = "application/{mbox,javascript,wine-extension-ini}"
run = 'piper -- bat -p --color=always --terminal-width=$w "$1"'
```

| Setting | Effect |
| --- | --- |
| `mgr.ratio = [0, 2, 6]` | Hides the parent column; the file list takes 2/8 of the width and the preview 6/8. |
| `opener.play` | `mpv`, detached from yazi (`orphan = true`). |
| `opener.edit` | `yazi-nvim-open`, blocking, so yazi waits for the editor. |
| `opener.open` | `xdg-open` on the first selected file. |
| `open.prepend_rules` | Markdown files list `fry`, then `edit`, then `open`. No `fry` opener is defined in this file. |
| Previewers | Text MIME types, plus mbox, JavaScript, and wine `.ini`, preview through the `piper` plugin running `bat -p --color=always`, so previews use the [bat](bat.md) cyberdream theme. Markdown falls under `text/*` too. |

## Keymap

All bindings in `keymap.toml` are `[[mgr.prepend_keymap]]` entries, so they take priority over yazi's defaults and leave the rest of the default keymap intact.

### Navigation

| Keys | Action |
| --- | --- |
| <kbd>l</kbd> | `plugin smart-enter`: enter a directory, or open a file |
| <kbd>g</kbd> <kbd>r</kbd> | cd to the git root (`git rev-parse --show-toplevel`) |
| <kbd>g</kbd> <kbd>C</kbd> | cd to `~/.local/share/chezmoi` |
| <kbd>g</kbd> <kbd>d</kbd> | cd to `~/Downloads` |
| <kbd>g</kbd> <kbd>D</kbd> <kbd>d</kbd> | cd to `$GHQ_ROOT/github.com` |
| <kbd>g</kbd> <kbd>D</kbd> <kbd>w</kbd> | cd to `$GHQ_ROOT/github.com/wltbs` |
| <kbd>g</kbd> <kbd>D</kbd> <kbd>p</kbd> | cd to `$GHQ_ROOT/github.com/prdlk` |
| <kbd>g</kbd> <kbd>l</kbd> | cd to `~/.local` |
| <kbd>g</kbd> <kbd>p</kbd> | cd to `~/Pictures` |
| <kbd>g</kbd> <kbd>o</kbd> <kbd>p</kbd> | cd to `~/Documents/Obsidian/Personal` |
| <kbd>g</kbd> <kbd>o</kbd> <kbd>r</kbd> | cd to `~/Documents/Obsidian/Research` |
| <kbd>g</kbd> <kbd>o</kbd> <kbd>w</kbd> | cd to `~/Documents/Obsidian/Walletbase` |
| <kbd>g</kbd> <kbd>b</kbd> | Back to the previous directory |
| <kbd>g</kbd> <kbd>f</kbd> | Forward to the next directory |
| <kbd>g</kbd> <kbd>m</kbd> <kbd>p</kbd> | cd to `sftp://gdrive-personal` |
| <kbd>g</kbd> <kbd>m</kbd> <kbd>s</kbd> | cd to `sftp://gdrive-sonr` |
| <kbd>g</kbd> <kbd>m</kbd> <kbd>h</kbd> | cd to `sftp://gdrive-hyperauth` |
| <kbd>;</kbd> | Open the bunny hop menu |
| <kbd>'</kbd> | Bunny fuzzy search over hops |

`$GHQ_ROOT` is `~/Code`, exported in `dot_config/fish/conf.d/10-env.fish`, `dot_zshrc`, and `dot_bashrc`. The `g m` bindings need the SFTP services in `vfs.toml`, which are commented out (see [vfs.toml](#vfstoml)).

### Finding and opening

| Keys | Action |
| --- | --- |
| <kbd>F</kbd> | `plugin smart-filter`: live filter; enters the directory or opens the file when one match remains |
| <kbd>Ctrl</kbd>+<kbd>t</kbd> | `plugin tv`: jump to a file with television |
| <kbd>Ctrl</kbd>+<kbd>g</kbd> | `plugin tv ghq`: jump to a ghq repo |
| <kbd>Ctrl</kbd>+<kbd>d</kbd> | `plugin tv dirs`: jump to a directory |
| <kbd>Ctrl</kbd>+<kbd>f</kbd> | `plugin tv text`: search text and open the match in Neovim at that line |
| <kbd>Ctrl</kbd>+<kbd>v</kbd> | `yazi-nvim-open vsplit` on the selection (inside an nvim terminal only) |
| <kbd>Ctrl</kbd>+<kbd>x</kbd> | `yazi-nvim-open split` on the selection (inside an nvim terminal only) |

The `tv` plugin shells out to [television](https://github.com/alexpasmantier/television), which is not in `packages.yaml`.

### Files and session

| Keys | Action |
| --- | --- |
| <kbd>A</kbd> | Create a directory (`create --dir`) |
| <kbd>N</kbd> | Bulk-create files (`bulk_create`) |
| <kbd>Shift</kbd>+<kbd>Tab</kbd> | Drop into `$SHELL` in the current directory (blocking) |
| <kbd>Ctrl</kbd>+<kbd>q</kbd> | Quit |

In the shell opened by <kbd>Shift</kbd>+<kbd>Tab</kbd>, the `q` function (fish, bash, zsh) runs `ya emit quit` when `$YAZI_ID` is set, then exits. That closes the parent yazi too instead of returning to it.

## Plugins

`package.toml` pins every plugin to a commit and hash. `~/.config/yazi` is the [prdlk/yazi](https://github.com/prdlk/yazi) checkout, so `ya pkg install` writes plugins into its `plugins/`, which that repo's `.gitignore` excludes (`plugins/*`, `!plugins/bunny.yazi/`). The post-apply script reinstalls from the manifest:

**run_onchange_after_install-yazi-plugins.sh.tmpl**

```sh
#!/bin/sh
# Install the yazi plugins pinned in ~/.config/yazi/package.toml whenever it
# changes. ~/.config/yazi is a git-repo external (prdlk/yazi); plugins land in
# its plugins/ dir (gitignored there, except the vendored bunny.yazi).
{{- $pkg := joinPath .chezmoi.homeDir ".config/yazi/package.toml" }}
# package.toml hash: {{ if stat $pkg }}{{ include $pkg | sha256sum }}{{ end }}
set -eu
command -v ya >/dev/null 2>&1 || exit 0
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/yazi/package.toml" ] || exit 0
# ya's clone cache is disposable and clones made by an older ya can break a
# newer one, so rebuild it once before giving up.
ya pkg install || {
	rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/yazi/packages"
	ya pkg install
}
```

The embedded hash makes chezmoi re-run the script whenever `package.toml` changes.

bunny is not in `package.toml`: it is vendored at `71b14a3` in `plugins/bunny.yazi/` of the yazi repo, because its repo contains a Git symlink to a directory (`test/plugins/bunny.yazi -> ../..`) that `ya pkg` cannot materialize. To update it, re-copy the files from upstream.

| Plugin | Rev | Used by |
| --- | --- | --- |
| `yazi-rs/plugins:smart-filter` | `efa4d79` | <kbd>F</kbd> |
| `uhs-robert/sshfs` | `a8b8903` | `require("sshfs"):setup()` in `init.lua` |
| `yazi-rs/plugins:smart-enter` | `efa4d79` | <kbd>l</kbd> |
| `yazi-rs/plugins:piper` | `efa4d79` | bat previewers in `yazi.toml` |
| `Rolv-Apneseth/starship` | `ea92cf4` | Installed; not set up in `init.lua` |
| `mikavilpas/easyjump.yazi:easyjump` | `4aa1a06` | Installed; not bound in `keymap.toml` |
| `cap153/tv` | `b6b1f12` | <kbd>Ctrl</kbd>+<kbd>t</kbd>/<kbd>g</kbd>/<kbd>d</kbd>/<kbd>f</kbd> |
| `stelcodes/bunny` | `71b14a3` (vendored) | <kbd>;</kbd> and <kbd>'</kbd>, configured in `init.lua` |
| `coder0x6675/osc7` | `ae73046` | Installed; not referenced in config |
| `WhoSowSee/mdv-previewer` | `ea4732b` | Installed; not referenced in `yazi.toml` |
| `yazi-rs/plugins:vcs-files` | `efa4d79` | Installed; not bound in `keymap.toml` |
| `yazi-rs/plugins:git` | `efa4d79` | `require("git"):setup { order = 1500 }` |
| `yazi-rs/plugins:no-status` | `efa4d79` | `require("no-status"):setup()` |

`[flavor] deps` is empty: flavors ship as files in `flavors/`, not as packages.

### init.lua

**~/.config/yazi/init.lua**

```lua
require("sshfs"):setup()
require("bunny"):setup({ hops = { ... }, desc_strategy = "path", ephemeral = true, tabs = true, notify = false, fuzzy_cmd = "fzf" })
require("git"):setup { order = 1500 }
require("no-status"):setup()
```

- **sshfs**: default setup, for mounting remote hosts over SSHFS.
- **git**: git status signs in the file list, ordered at `1500` in the linemode.
- **no-status**: removes the status bar.
- **bunny**: bookmark "hops", with ephemeral hops and tab hops on, no notification after hopping, `fzf` for fuzzy search, and the path as the label when a hop has no `desc`.

| Hop key | Path | Label |
| --- | --- | --- |
| <kbd>/</kbd> | `/` | |
| <kbd>t</kbd> | `/tmp` | |
| <kbd>~</kbd> | `~` | Home |
| <kbd>m</kbd> | `~/Music` | Music |
| <kbd>d</kbd> | `~/Desktop` | Desktop |
| <kbd>D</kbd> | `~/Developer` | Developer |
| <kbd>c</kbd> | `~/.config` | Config files |
| <kbd>l</kbd> <kbd>s</kbd> | `~/.local/share` | Local share |
| <kbd>l</kbd> <kbd>b</kbd> | `~/.local/bin` | Local bin |
| <kbd>l</kbd> <kbd>t</kbd> | `~/.local/state` | Local state |

## Theme and flavors

**~/.config/yazi/theme.toml**

```toml
[flavor]
light = "cyberdream"
dark = "cyberdream"
use = "cyberdream"
```

Cyberdream is active in both light and dark mode, the palette shared with Ghostty, tmux, nvim, and television. Two flavors ship in `flavors/`:

| Flavor | Origin | Notes |
| --- | --- | --- |
| `cyberdream.yazi` | Hand-maintained cyberdream palette | Active. Sets `syntect_theme = "~/.config/bat/themes/cyberdream.tmTheme"`, so yazi's built-in code preview shares the [bat](bat.md) theme. Cyan cwd (`#5ef1ff`), green find keyword (`#5eff6c`), yellow and red copy/cut markers. |
| `ii-auto.yazi` | Generated by the ii wallpaper theming system ("Do not edit manually") | Not selected. Monochrome palette taken from the wallpaper. |

To switch, change `use` (and `light`/`dark`) in `theme.toml` to `ii-auto`.

### Icons

`theme.toml` also carries a large `[icon]` table:

- `prepend_dirs`: Nerd Font icons for named directories: `Applications`, `Code`, `Desktop`, `Developer`, `github.com`, `prdlk`, `wltbs`, `Shared`, `Templates`, `env`, `go`, `js`, `dart`, `py`, `rs`, `tex`, `md`, `docs`, `prad.codes`.
- `files` and `exts`: several hundred filename and extension rules, from dotfiles like `.gitignore` and `.zshrc` to formats like `kicad_pcb` and `wrangler.toml`. Each rule sets a Nerd Font glyph and a foreground color from the Catppuccin Mocha palette (`#a6e3a1`, `#f38ba8`, `#89b4fa`, `#cba6f7`, `#fab387`, ...).

Glyphs need a Nerd Font. The terminal uses VictorMono Nerd Font (see [Terminal](../terminal/README.md)).

## vfs.toml

Every line is commented out. The file sketches three SFTP services (`gdrive-personal`, `gdrive-sonr`, `gdrive-hyperauth`) on local ports, meant to be served by a local SFTP bridge to Google Drive. Until they are uncommented and the bridge is running, the <kbd>g</kbd> <kbd>m</kbd> bindings have nothing to connect to.

## Neovim bridge: yazi-nvim-open

`~/.local/bin/yazi-nvim-open [vsplit|split|tabedit] file...` backs the `edit` opener and the <kbd>Ctrl</kbd>+<kbd>v</kbd>/<kbd>Ctrl</kbd>+<kbd>x</kbd> bindings. It lives on `PATH` because yazi does not expand `$HOME` in opener commands.

1. **Parse mode**

   A first argument of `vsplit`, `split`, or `tabedit` selects the mode; anything else means `edit`.

2. **Standalone yazi ($NVIM unset)**

   `edit` runs `exec nvim "$@"`. Split modes do nothing and exit 0.

3. **Inside an nvim terminal ($NVIM set)**

   Each file is resolved with `realpath`, escaped for a Vimscript string, and sent to the host with `nvim --server "$NVIM" --remote-expr "v:lua.EditFromYazi(mode, path)"`. The nvim side opens the file and hides the yazi window.

Set `YAZI_OPEN_TRACE` to a file path to log each call's `$NVIM`, mode, and arguments.

## Launching yazi

| Entry point | Behavior |
| --- | --- |
| `y` / `yy` (fish functions) | Run yazi with `--cwd-file`, then `cd` to the directory yazi was in on exit. The two are identical apart from `y` calling `command rm`. |
| `yy` (bash, zsh functions) | Same wrapper for bash and zsh. |
| <kbd>Ctrl</kbd>+<kbd>e</kbd> / <kbd>Ctrl</kbd>+<kbd>f</kbd> | fish and zsh keybindings that run `yy` and repaint the prompt. |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>f</kbd> | [Kitty](../terminal/kitty.md): yazi in a new tab at the current directory. |
| Aliases | `e.y`, `e.k`, `e.n`, `e.f`, `e.v` open config directories in yazi; `cdc`, `cdl`, `cdw`, and `,,` (fish only; chezmoi source) cd first, then start yazi. |

[tmux](../terminal/tmux.md) sets `allow-passthrough on` so yazi's kitty-protocol image previews work inside tmux. Kitty's tab bar and the tmux window-name map show a folder icon for yazi. See [aliases](../shell/aliases.md) and [fish](../shell/fish.md) for the shell side.
