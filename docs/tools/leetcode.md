# LeetCode

LeetCode CLI workspace config, its tracked state files, and the lc-elir helper that sends solutions to omp.

The repo tracks the state directory of a terminal LeetCode client, plus a helper that feeds solution files to omp prompt commands. The `~/.leetcode` layout (workspaces with `collab.json`, `timer.json`, and `snapshots/`) matches [night-slayer18/leetcode-cli](https://github.com/night-slayer18/leetcode-cli), which is invoked as `leetcode`.

| | |
| --- | --- |
| Source | `dot_leetcode/` |
| Target | `~/.leetcode/` |
| Packages | The CLI is not declared in `packages.yaml`; install it separately |
| Alias | `lc` = `leetcode` (fish, bash, zsh) |

```text
dot_leetcode/
  workspaces.json
  star-prompt.json
  version-cache.json
  workspaces/
    default/
      config.json
      collab.json
      timer.json
      snapshots/
        .keep
```

## Workspaces

`workspaces.json` lists one workspace, `default`, and marks it active.

**~/.leetcode/workspaces/default/config.json**

```json
{
  "workDir": "/home/prad/Code/github.com/prdlk/leetcode/work/1",
  "lang": "python3",
  "site": "leetcode.com",
  "editor": "nvim",
  "syncRepo": "https://github.com/prdlk/leetcode.git"
}
```

| Key | Value | Effect |
| --- | --- | --- |
| `workDir` | `~/Code/github.com/prdlk/leetcode/work/1` (absolute path in the file) | Where problem files are written. It sits inside the ghq checkout of the solutions repo, under `$GHQ_ROOT`. |
| `lang` | `python3` | Default solution language. |
| `site` | `leetcode.com` | Target site. |
| `editor` | `nvim` | Opens problems in [Neovim](neovim.md). |
| `syncRepo` | `https://github.com/prdlk/leetcode.git` | Repo that solutions sync to. |

The path is absolute, so on a machine with a different username or `$GHQ_ROOT`, edit `workDir`.

The other workspace files start empty: `collab.json` has `"session": null`, `timer.json` has no solve times and no active timer, and `snapshots/` holds only a `.keep` placeholder.

## Tracked state files

| File | Contents |
| --- | --- |
| `star-prompt.json` | Counter for the CLI's "star the repo" prompt: accepted-submission total, milestones already shown, submissions since the last prompt, timestamps, and a `dismissed` flag. |
| `version-cache.json` | Last update check time, latest known version, and whether it has breaking changes. |

These are runtime files. In chezmoi's symlink mode, non-template, non-private files are symlinks into the source directory, so the CLI writes these straight into the repo working tree. Expect them to show up as diffs.

## lc-elir

`lc-elir [root]` picks LeetCode solution files with fzf and runs the omp `/leetcode-eli5` command on each one.

| | |
| --- | --- |
| Sources | `dot_local/bin/executable_lc-elir` (POSIX sh), `dot_config/fish/functions/lc-elir.fish` (fish port) |
| Targets | `~/.local/bin/lc-elir`, `~/.config/fish/functions/lc-elir.fish` |
| Needs | `fd`, `fzf`, `bat`, `omp` |

1. **Find candidates**

   `fd --type f '^\d+\..+\.(js|ts)$'` under `root` (default `.`) matches numbered problem files such as `1365.some-slug.js`.

2. **Pick**

   `fzf --multi` with prompt `eli5> `, showing the last three path segments (`--delimiter=/ --with-nth=-3..`). The right-hand 60% preview shows the first 40 lines through `bat --color=always --line-range=:40`.

3. **Run**

   For each selected file it prints a separator line, then runs `omp -p "/leetcode-eli5 <file>"`. It exits 1 if nothing was picked.

## omp commands

`lc-elir` runs the `/leetcode-eli5` omp command, which lives in `~/.omp/agent/commands/` and is not managed by this repo.
