# free-router

[freellmapi](https://github.com/tashfeenahmed/freellmapi) (an OpenAI/Anthropic-compatible router over free LLM provider tiers) running under Bun as a systemd user service on `http://localhost:9876`. Shells get the endpoint's port and API key as `FREE_ROUTER_PORT` and `FREE_ROUTER_API_KEY`. Linux desktop/laptop roles only.

| Piece | Source in repo | Target in `$HOME` |
| --- | --- | --- |
| Settings | `dot_config/free-router/env` | `~/.config/free-router/env` (symlink) |
| Launcher | `dot_local/bin/executable_free-router` | `~/.local/bin/free-router` |
| Unit | `dot_config/systemd/user/free-router.service` | `~/.config/systemd/user/free-router.service` |
| Router source | `.chezmoiexternals/freellmapi.toml` | `~/.local/share/freellmapi` (upstream checkout) |
| State | none | `~/.local/state/free-router/` (`freeapi.db`, `encryption-key`, `built-head`) |

## Settings

**~/.config/free-router/env**

```sh
FREE_ROUTER_PORT=9876
FREE_ROUTER_API_KEY=sk_gz58b6RRX5
```

One file, three readers: `free-router.service` loads it with `EnvironmentFile=`, bash and zsh source it with `set -a` (`.bashrc`, `.zshrc`), and fish exports each `KEY=VALUE` line (`conf.d/10-env.fish`). Keep it to plain `KEY=VALUE` lines so all three parse it. After a change, run `systemctl --user restart free-router` and open a new shell.

## Launcher

`free-router` is a Bun script (`#!/usr/bin/env bun`). It needs `FREE_ROUTER_PORT` and `FREE_ROUTER_API_KEY` in its environment and exits 1 without them or without the checkout.

1. **Build, once per upstream commit.** If `git rev-parse HEAD` of the checkout differs from `built-head`, it runs `bun install --no-save` and `bun --bun run build` in `client/` (the dashboard), then records the commit. `--no-save` keeps a `bun.lock` out of the checkout, so chezmoi's `--ff-only` pulls never conflict.
2. **Encryption key.** Generates `encryption-key` (32 random bytes, hex, mode `0600`) on first run and passes it as `ENCRYPTION_KEY`. Provider keys in the database are encrypted with it: losing the file orphans them.
3. **Environment.** `NODE_ENV=production`, `HOST=127.0.0.1`, `PORT=$FREE_ROUTER_PORT`, `FREEAPI_DB_PATH=~/.local/state/free-router/freeapi.db`.
4. **SQLite driver.** Bun refuses to load `better-sqlite3` ([oven-sh/bun#4290](https://github.com/oven-sh/bun/issues/4290)). A Bun plugin serves `require('better-sqlite3')` from the server's own `node:sqlite` adapter (`server/src/db/node-sqlite.ts`, its Android/Termux driver).
5. **API key.** Runs the migrations, writes `FREE_ROUTER_API_KEY` to the `unified_api_key` setting, then imports `server/src/index.ts`. The key is set before the server listens, so the random key upstream generates is never accepted.

Regenerating the unified key in the dashboard replaces it until the next restart, which writes `FREE_ROUTER_API_KEY` back.

## Service

```ini
[Service]
EnvironmentFile=%h/.config/free-router/env
ExecStart=%h/.local/bin/free-router
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```

[`30-user-services`](../chezmoi/scripts.md#30-user-services) enables it with `--now`. It starts with the user's systemd manager at login and is restarted 5 s after any exit. Without lingering (`loginctl enable-linger`), it does not run before the first login after a reboot. The first start after a new upstream commit takes longer (install and dashboard build); `journalctl --user -u free-router -f` shows progress.

## Using it

1. Open `http://localhost:9876`, create the dashboard account (a browser on this machine needs no setup code), and add provider keys on the **Keys** page. Until then, completions fail with `no_providers`.
2. Point clients at `http://localhost:$FREE_ROUTER_PORT/v1` with `$FREE_ROUTER_API_KEY`:

```sh
curl -s http://localhost:$FREE_ROUTER_PORT/v1/chat/completions \
  -H "Authorization: Bearer $FREE_ROUTER_API_KEY" -H 'content-type: application/json' \
  -d '{"model":"auto","messages":[{"role":"user","content":"hi"}]}'
```

## Updating

chezmoi fast-forwards `~/.local/share/freellmapi` at most once a week (`refreshPeriod = "168h"`), or now with `chezmoi apply --refresh-externals ~/.local/share/freellmapi`. The running service keeps the old code; `systemctl --user restart free-router` rebuilds and starts the new commit.
