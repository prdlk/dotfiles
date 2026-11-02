# Fonts and default apps

Fontconfig monospace override to Victor Mono Nerd Font, the Nerd Font packages, and the XDG default-application table.

Two small files set system-wide defaults: `fonts.conf` picks the monospace font, and `mimeapps.list` picks which application opens each file type and URL scheme.

> [!NOTE]
> Linux `desktop` and `laptop` roles only. `.chezmoiignore.tmpl` skips `~/.config/fontconfig/**` and `~/.config/mimeapps.list` on other roles.

## Fontconfig

| Source (repo) | Target |
| --- | --- |
| `dot_config/fontconfig/fonts.conf` | `~/.config/fontconfig/fonts.conf` |

**~/.config/fontconfig/fonts.conf**

```xml
<fontconfig>
  <match target="pattern">
    <test name="family" qual="any">
      <string>monospace</string>
    </test>
    <edit name="family" mode="prepend_first" binding="strong">
      <string>VictorMono Nerd Font</string>
    </edit>
  </match>
</fontconfig>
```

Any font request that includes the generic `monospace` family gets `VictorMono Nerd Font` added to the front of its family list (`prepend_first`) with strong binding. Apps that ask for "monospace" therefore render in Victor Mono with Nerd Font glyphs, and fall back through fontconfig's normal monospace list if a glyph is missing. The file does not configure sans/serif families, hinting, antialiasing, or subpixel rendering. Those stay at system defaults.

Some tools set their own fonts. Waybar uses `CaskaydiaCove Nerd Font Propo` (see [Waybar](waybar.md)), and the terminals set fonts in their own configs (see [kitty](../terminal/kitty.md)).

### Font packages

Victor Mono Nerd Font is installed on every role by `run_onchange_before_10-packages.sh.tmpl` from `.chezmoidata/packages.yaml`, not only on desktop roles. The package is `ttf-victor-mono-nerd` (pacman, `packages.arch.pacman`). `fonts.conf` is Linux desktop only, but the font package is also installed on `server`.

## Default applications

| Source (repo) | Target |
| --- | --- |
| `dot_config/mimeapps.list` | `~/.config/mimeapps.list` |

`mimeapps.list` is the XDG file that `xdg-open`, GTK/Qt file dialogs, and browsers use to choose a handler. `[Default Applications]` sets the preferred handler. `[Added Associations]` adds entries to "Open with" lists.

### Default applications

| Group | MIME types / schemes | Handler (`.desktop`) |
| --- | --- | --- |
| Text and scripts | `text/plain`, `text/x-shellscript`, `text/x-python`, `text/x-script.python` | `vim.desktop` |
| Notes | `text/markdown`, `application/x-obsidian-canvas`, `application/x-obsidian-base`, `x-scheme-handler/obsidian` | `obsidian.desktop` (`obsidian` from `packages.arch.desktop.pacman`) |
| Web pages | `text/html`, `application/xhtml+xml`, `application/x-extension-htm`, `-html`, `-shtml`, `-xhtml`, `-xht` | `brave-origin.desktop` |
| Web links | `x-scheme-handler/http`, `https`, `chrome` | `brave-origin.desktop` |
| Browser internals | `x-scheme-handler/about`, `unknown` | `chromium.desktop` |
| PDF | `application/pdf` | `brave-origin.desktop` |
| Directories | `inode/directory` | `io.github.lgse.Strata.desktop` ([strata](../chezmoi/scripts.md#15-tools), which also registers the `org.freedesktop.FileManager1` service for "Open file location" and serves the portal file chooser) |
| Mail | `x-scheme-handler/mailto` | `omamail.desktop` |
| Windows executables | `application/vnd.microsoft.portable-executable` | `wine.desktop` |
| AI tools | `x-scheme-handler/claude` | `com.anthropic.Claude.desktop` |
| | `x-scheme-handler/claude-cli` | `claude-code-url-handler.desktop` |
| | `x-scheme-handler/opencode` | `ai.opencode.desktop.desktop` |
| | `x-scheme-handler/antigravity` | `antigravity.desktop` |
| | `x-scheme-handler/piebald` | `piebald-handler.desktop` |
| | `x-scheme-handler/openhuman` | `OpenHuman-handler.desktop` |
| Productivity | `x-scheme-handler/todoist`, `com.todoist` | `todoist.desktop` |
| | `x-scheme-handler/notion` | `notion.desktop` |
| | `x-scheme-handler/anytype` | `anytype.desktop` |
| | `x-scheme-handler/tolaria` | `tolaria-handler.desktop` |
| | `x-scheme-handler/tldraw-offline` | `tldraw-offline.desktop` |
| | `x-scheme-handler/figma` | `figma-linux.desktop` |
| Chat | `x-scheme-handler/slack` | `slack.desktop` |
| | `x-scheme-handler/discord-647066573147996160` | `discord-647066573147996161.desktop` |
| Feeds | `x-scheme-handler/follow`, `folo` | `folo.desktop` |

### Added associations

| MIME types / schemes | Also offered |
| --- | --- |
| `http`, `https`, `chrome` schemes; `text/html`, `application/xhtml+xml`, and the `x-extension-*` web types | `brave-origin.desktop`, `userapp-Floorp-8MTFP3.desktop` |
| `x-scheme-handler/mailto` | `userapp-Evolution-PCEYQ4.desktop` |
| `application/vnd.microsoft.portable-executable` | `wine.desktop` |
| `application/pdf` | `brave-origin.desktop` |
| `x-scheme-handler/opencode` | `ai.opencode.desktop.desktop` |

The added mail association is Evolution, but the default mail handler is `omamail.desktop`.

> [!TIP]
> In symlink mode, `~/.config/mimeapps.list` is a symlink into the repo. When `xdg-mime default` or a "set as default" dialog updates it, the tool either writes through the symlink and edits the repo file directly, or replaces the symlink with a regular file. Check `git status` or `chezmoi status` after changing defaults.

## Related

- [Hyprland](hyprland.md): the compositor these defaults serve.
- [Installation](../installation.md): role selection that decides whether this layer applies.
