# SSH and mosh

`~/.ssh/config` with the goliath host, and the interactive session behind `SUPER + SHIFT + G`: `kitten ssh` at home, mosh elsewhere.

| | |
| --- | --- |
| Source | `private_dot_ssh/config` |
| Target | `~/.ssh/config` (symlink; `private_` keeps `~/.ssh` at `0700`) |
| Packages | `mosh`, `tailscale` (every OS, so goliath has `mosh-server` too; Ubuntu's tailscale comes from the pkgs.tailscale.com repo) |

Keys, `known_hosts` and the agent socket are not managed; only `config` is. The agent comes from fish's [`30-ssh-agent.fish`](../shell/fish.md#30-ssh-agentfish). On Omarchy, keepalives come from `/etc/ssh/ssh_config.d/20-omarchy-keepalive.conf` (`ServerAliveInterval 15`, `ServerAliveCountMax 3`, `ConnectTimeout 10`).

## Host goliath

| Option | Value | Why |
| --- | --- | --- |
| `HostName` | `100.115.218.84` | goliath's Tailscale IPv4 address: the same address at home and away, with no DNS lookup. The LAN's DNS answers `goliath` with an IPv6 address only. Changes only if goliath is re-added to the tailnet (`tailscale ip -4` on goliath) |
| `HostKeyAlias` | `goliath` | Host keys stay filed under the short name already in `known_hosts` |
| `User` | `prad` | |
| `IdentityFile` / `IdentitiesOnly` | `~/.ssh/id_ed25519` / `yes` | Offers one key instead of trying every default |
| `ControlMaster` / `ControlPath` / `ControlPersist` | `auto` / `~/.ssh/cm-%C` / `10m` | One shared connection: later ssh, scp and git runs skip the handshake, and it stays up 10 minutes after the last one exits |

## goliath sessions: kitten ssh or mosh

On Omarchy, `SUPER + SHIFT + G` ([Hyprland](https://prad.codes/env/omarchy-desktop/src/branch/main/docs/hyprland.md), desktop layer) opens `kitty --class=kitty-goliath --title=goliath --session=none --config ~/.config/kitty/goliath.conf goliath`; new tabs and splits in that window run `goliath` too (see [kitty](../terminal/kitty.md#goliath-super--shift--g)). [`goliath`](../shell/scripts.md#goliath) reads the active Wi-Fi SSID and connects:

| Network | Transport | Why |
| --- | --- | --- |
| `Fios-kM4W5` (home) | `kitten ssh goliath` (plain `ssh` outside kitty) | Same LAN, stable link: kitty's ssh kitten gives the full kitty terminal on goliath (graphics, undercurl, keyboard protocol, clipboard) and shares one connection per window (`share_connections yes` in `ssh.conf`) |
| Anything else | `mosh goliath` | Roaming: the session survives suspend, Wi-Fi changes and dropped links, and echoes keystrokes locally while the link is slow |

`goliath --ssh` / `goliath --mosh` (or `GOLIATH_TRANSPORT=ssh|mosh`) force one; `GOLIATH_HOME_SSID` changes the home network.

For mosh: it logs in over ssh with this host block (`%h` is the Tailscale IP), starts `mosh-server` on goliath, which binds UDP 60000–61000 on `100.115.218.84`, and the session runs over Tailscale.

- mosh's bootstrap ssh runs with `-S none`, so it never uses the shared connection; key auth through the agent must work non-interactively.
- goliath runs no firewall, and Tailscale carries the UDP traffic.
- mosh passes the client's `LANG` (`en_US.UTF-8`); goliath has `en_US.utf8` generated, which `mosh-server` needs.
- Inside mosh `TERM` is `xterm-256color`: kitty-only features (undercurl, graphics, the keyboard protocol) are unavailable.
- Closing the kitty window kills `mosh-client` without telling the server, so that `mosh-server` stays on goliath until it is killed (`pkill mosh-server` on goliath).
