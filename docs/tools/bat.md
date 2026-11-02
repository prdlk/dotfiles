# bat

bat with the cyberdream tmTheme, an external PureScript syntax, and automatic cache rebuilds on apply.

[bat](https://github.com/sharkdp/bat) is a `cat` replacement with syntax highlighting and git gutter marks. The repo sets its theme to cyberdream, adds a PureScript grammar, and rebuilds bat's cache whenever those inputs change.

| | |
| --- | --- |
| Sources | `dot_config/bat/config`, `dot_config/bat/themes/cyberdream.tmTheme` |
| External | `.config/bat/syntaxes/sublime-purescript-syntax` in `.chezmoiexternal.toml` |
| Targets | `~/.config/bat/config`, `~/.config/bat/themes/cyberdream.tmTheme`, `~/.config/bat/syntaxes/sublime-purescript-syntax/` |
| Packages | `bat` (pacman) |

## config

bat's config file holds default command-line flags. One is active:

**~/.config/bat/config**

```sh
--theme="cyberdream"
```

The file also carries bat's stock commented examples (`--italic-text=always`, `--paging=never`, a mouse-enabled `--pager`, `--map-syntax`); none are enabled.

## Theme

`cyberdream.tmTheme` is a TextMate theme named "Cyberdream". Base settings:

| Key | Color |
| --- | --- |
| `background` | `#16181a` |
| `foreground`, `caret` | `#ffffff` |
| `lineHighlight`, `selection` | `#3c4048` |
| `findHighlight` | `#5ef1ff` |
| `activeGuide` | `#ffbd5e` |
| `bracketsForeground` | `#ff5ea0` (underlined) |
| Comments | `#7b8496` |

The same file is also used outside bat:

- The [yazi](yazi.md) cyberdream flavor points `syntect_theme` at `~/.config/bat/themes/cyberdream.tmTheme`.
- Yazi text previews run `bat -p --color=always` through the piper plugin, so they get this theme via the config file.

## PureScript syntax

**.chezmoiexternal.toml**

```toml
[".config/bat/syntaxes/sublime-purescript-syntax"]
    type = "git-repo"
    url = "https://github.com/tellnobody1/sublime-purescript-syntax.git"
    [".config/bat/syntaxes/sublime-purescript-syntax".pull]
        args = ["--ff-only"]
```

chezmoi clones the Sublime grammar when it is missing. With no `refreshPeriod`, it only pulls (`--ff-only`) on `chezmoi apply --refresh-externals`. See [externals and ignore rules](../chezmoi/externals-and-ignore.md).

## Cache rebuilds

bat only sees custom themes and syntaxes after `bat cache --build`. Two scripts run it:

| Script | When it runs |
| --- | --- |
| `run_onchange_after_build-bat-cache.sh.tmpl` | Embeds SHA-256 hashes of `cyberdream.tmTheme` and `config`, so it re-runs whenever either file changes. Exits quietly if `bat` is missing. |
| `.chezmoiscripts/run_onchange_after_40-post.sh.tmpl` | Post-apply housekeeping (also runs `fc-cache` on Linux). Runs `bat cache --build` when its own rendered content changes, which includes the first apply. |

> [!NOTE]
> Neither hash covers the PureScript external. If the grammar updates, run `bat cache --build` by hand.

## Other consumers

- `lc-elir` previews candidate files with `bat --color=always --line-range=:40` inside fzf. See [LeetCode](leetcode.md).
- The kitty tab bar shows a book icon while `bat` runs.
