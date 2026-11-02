# GitHub CLI

gh config and aliases, the four gh extensions installed on apply, and the gh-dash dashboard layout.

`gh` is GitHub's official CLI. The repo manages its global config, installs a fixed set of extensions, and configures [gh-dash](https://github.com/dlvhdr/gh-dash), a TUI dashboard for pull requests, issues, and notifications.

| | |
| --- | --- |
| Sources | `dot_config/gh/private_config.yml`, `dot_config/gh-dash/config.yml` |
| Targets | `~/.config/gh/config.yml` (mode `0600`, from the `private_` prefix), `~/.config/gh-dash/config.yml` |
| Packages | `github-cli` (pacman) |
| Extensions | `packages.shared.gh_extensions` in `.chezmoidata/packages.yaml` |

> [!NOTE]
> Authentication is per machine: run `gh auth login` once. Tokens live in gh's `hosts.yml` or the system keyring, which the repo does not manage.

## gh config

| Key | Value | Effect |
| --- | --- | --- |
| `version` | `1` | Config schema version. |
| `git_protocol` | `https` | gh clones and adds remotes over HTTPS. Pushes still go over SSH because of the `pushInsteadOf` rewrite in [Git](git.md). |
| `editor` | empty | Falls back to the environment; fish exports `EDITOR=nvim`. |
| `prompt` | `enabled` | Interactive prompts on. |
| `prefer_editor_prompt` | `disabled` | Prompts inline instead of opening an editor. |
| `pager` | empty | Falls back to the environment. |
| `http_unix_socket` | empty | Default transport. |
| `browser` | empty | Falls back to the environment. |
| `color_labels` | `disabled` | Labels are not drawn in their RGB colors. |
| `accessible_colors` | `disabled` | |
| `accessible_prompter` | `disabled` | |
| `spinner` | `enabled` | Animated progress spinner. |

### Aliases

| Alias | Expands to |
| --- | --- |
| `gh co` | `gh pr checkout` |

## Extensions

| Extension | Command | Purpose |
| --- | --- | --- |
| `davidraviv/gh-clean-branches` | `gh clean-branches` | Deletes local branches that no longer have a remote counterpart. |
| `prdlk/gh-commit` | `gh commit` | The owner's commit helper; lazygit binds it as "Smart commit with AI". |
| `dlvhdr/gh-dash` | `gh dash` | PR, issue, and notification dashboard (configured below). |
| `meiji163/gh-notify` | `gh notify` | Notification viewer. |

`.chezmoiscripts/run_onchange_after_20-gh-extensions.sh.tmpl` installs them. It is a fish script, so fish's config is sourced first and `PATH` and `GITHUB_TOKEN` match a fish session:

1. **Re-run trigger**

   The rendered script embeds a SHA-256 of the `gh_extensions` list, so chezmoi re-runs it whenever the list changes.

2. **Guards**

   If `gh` is missing, or `gh auth status` fails, it prints a warning and exits 0. Run `gh auth login`, then `chezmoi apply` again.

3. **Install**

   Reads `gh extension list` and runs `gh extension install` only for entries not already present.

See [chezmoi scripts](../chezmoi/scripts.md) for the full script order.

## gh-dash

Launched with `gh dash`, or <kbd>Ctrl</kbd>+<kbd>d</kbd> in lazygit's files panel.

### Sections

### Pull requests

| Title | Filter |
| --- | --- |
| My Pull Requests | `is:open author:@me` |
| Needs My Review | `is:open review-requested:@me` |
| Involved | `is:open involves:@me -author:@me` |

### Issues

| Title | Filter |
| --- | --- |
| My Issues | `is:open author:@me` |
| Assigned | `is:open assignee:@me` |
| Involved | `is:open involves:@me -author:@me` |

### Notifications

| Title | Filter |
| --- | --- |
| All | (none) |
| Created | `reason:author` |
| Participating | `reason:participating` |
| Mentioned | `reason:mention` |
| Review Requested | `reason:review-requested` |
| Assigned | `reason:assign` |
| Subscribed | `reason:subscribed` |
| Team Mentioned | `reason:team-mention` |

### Defaults

| Key | Value |
| --- | --- |
| `defaults.view` | `prs` |
| `defaults.preview.open` / `width` | `true` / `0.45` |
| `defaults.prsLimit`, `issuesLimit`, `notificationsLimit` | `20` each |
| `defaults.prApproveComment` | `LGTM` |
| `defaults.refetchIntervalMinutes` | `30` |
| `repo.branchesRefetchIntervalSeconds` | `30` |
| `repo.prsRefetchIntervalSeconds` | `60` |
| `repoPaths` | empty |
| `confirmQuit` | `false` |
| `showAuthorIcons` | `true` |
| `smartFilteringAtLaunch` | `true` |
| `includeReadNotifications` | `true` |
| `theme.ui.sectionsShowCount` | `true` |
| `theme.ui.table.showSeparator` / `compact` | `true` / `false` |

### Column layout

| View | Column | Width | Hidden |
| --- | --- | --- | --- |
| PRs | `updatedAt`, `createdAt` | 5 | no |
| PRs | `repo` | 20 | no |
| PRs | `author` | 15 | no |
| PRs | `authorIcon` | | no |
| PRs | `assignees` | 20 | yes |
| PRs | `base` | 15 | yes |
| PRs | `lines` | 15 | no |
| Issues | `updatedAt`, `createdAt` | 5 | no |
| Issues | `repo` | 15 | no |
| Issues | `creator` | 10 | no |
| Issues | `creatorIcon` | | no |
| Issues | `assignees` | 20 | yes |

### Keybindings

| View | Key | Command |
| --- | --- | --- |
| PRs | <kbd>T</kbd> | `gh enhance -R {{.RepoName}} {{.PrNumber}}` |

`gh enhance` is a gh extension that is not in the managed extension list; install it separately for this binding to work.

### Pager

**~/.config/gh-dash/config.yml**

```yaml
pager:
  diff: "hunk pager"
```

PR diffs open in [Hunk](hunk.md).

## Other integrations

- [Lazygit](lazygit.md) custom commands call `gh repo sync && gh clean-branches --force`, `gh commit`, `gh pr create --fill -w`, `gh dash`, and `gh browse`.
- `ghn` creates github.com repos with `gh`, and `gh-sonr-org-migrate` scripts gh for an org migration.
- The tmux window-name map gives `gh` its own Nerd Font icon.
