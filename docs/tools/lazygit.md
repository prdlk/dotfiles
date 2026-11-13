# Lazygit

Lazygit with cyberdream colors, delta diffs, a full keybinding map, and custom commands wired to gh and helper scripts.

[Lazygit](https://github.com/jesseduffield/lazygit) is a terminal UI for git. The config sets cyberdream colors, renders diffs with delta, turns on background fetching and a whole-graph log, and adds custom commands that call `gh`.

| | |
| --- | --- |
| Source | `dot_config/lazygit/config.yml`, `dot_config/lazygit/ii-theme.yml` |
| Target | `~/.config/lazygit/config.yml`, `~/.config/lazygit/ii-theme.yml` |
| Packages | `lazygit` (pacman) |
| Ignored | `.config/lazygit/.omc/**` (agent tooling state) |

## Launching

| Entry point | Behavior |
| --- | --- |
| `gg` | Alias for `lazygit` (all shells) |
| <kbd>Ctrl</kbd>+<kbd>g</kbd> | fish and zsh keybinding |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>g</kbd> | [Kitty](../terminal/kitty.md): lazygit as an overlay on the current window. The tmux-host kitty config opens it in a 90% `tmux display-popup` instead. |

tmux-resurrect lists `lazygit` among the processes it restores.

## GUI

Colors are upstream `extras/lazygit/cyberdream.yml` from [cyberdream.nvim](https://github.com/scottmckendry/cyberdream.nvim), the palette shared with Ghostty, tmux, and omp:

| Theme key | Color |
| --- | --- |
| `activeBorderColor` | `#5ef1ff` |
| `inactiveBorderColor` | `#7b8496` |
| `searchingActiveBorderColor` | `#ff5ef1` |
| `optionsTextColor` | `#3c4048` |
| `selectedLineBgColor` | `#3c4048` |
| `cherryPickedCommitBgColor` | `#3c4048` |
| `cherryPickedCommitFgColor` | `#ff5ea0` |
| `unstagedChangesColor` | `#ffbd5e` |
| `defaultFgColor` | `#ffffff` |
| `authorColors."*"` | `#ffffff` (every author the same color) |

| Option | Value |
| --- | --- |
| `border` | `rounded` |
| `scrollHeight` / `scrollPastBottom` | `2` / `true` |
| `scrollOffMargin` / `scrollOffBehavior` | `2` / `margin` |
| `mouseEvents` | `true` |
| `skipDiscardChangeWarning` | `true` |
| `skipStashWarning` | `true` |
| `skipNoStagedFilesWarning` | `false` |
| `skipRewordInEditorWarning` | `false` |
| `sidePanelWidth` | `0.4` |
| `expandFocusedSidePanel` / `expandedSidePanelWeight` | `true` / `2` |
| `mainPanelSplitMode` | `horizontal` |
| `enlargedSideViewLocation` | `left` |
| `language` | `auto` |
| `timeFormat` / `shortTimeFormat` | `02 Jan 06` / `3:04PM` |
| `commitLength.show` | `true` |
| `showListFooter` | `true` |
| `showFileTree` | `true` |
| `showRandomTip` | `false` |
| `showCommandLog` / `commandLogSize` | `true` / `4` |
| `showBottomLine` | `false` (keybinding hint line hidden) |
| `showPanelJumps` | `false` |
| `showIcons`, `nerdFontsVersion`, `showFileIcons` | `true`, `"3"`, `true` |
| `commitAuthorShortLength` / `commitAuthorLongLength` | `2` (initials) / `17` |
| `commitHashLength` | `8` |
| `showBranchCommitHash` | `true` |
| `showDivergenceFromBaseBranch` | `arrowAndNumber` |
| `splitDiff` | `auto` |
| `screenMode` | `normal` |
| `animateExplosion` | `true` |
| `portraitMode` | `auto` |
| `filterMode` | `fuzzy` |
| `spinner.frames` / `spinner.rate` | ASCII bar (`\|`, `/`, `-`, `\`) / `50` ms |
| `statusPanelView` | `allBranchesLog` |

## Git

| Option | Value |
| --- | --- |
| `diffRenderers` | `delta --dark --paging=never` with `colorArg: always`. delta also reads the `[delta]` section of `~/.gitconfig`; see [Git](git.md). |
| `commit.signOff` | `false` |
| `commit.autoWrapCommitMessage` / `autoWrapWidth` | `true` / `72` |
| `merging.manualCommit` / `args` | `false` / empty |
| `merging.squashMergeMessage` | `Squash merge {{selectedRef}} into {{currentBranch}}` |
| `mainBranches` | `develop` |
| `skipHookPrefix` | `WIP` (a message starting with `WIP` skips pre-commit hooks) |
| `autoFetch` / `autoRefresh` / `fetchAll` | `true` / `true` / `true` |
| `branchLogCmd` | `git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium {{branchName}} --` |
| `allBranchesLogCmds` | `git log --graph --all --color=always --abbrev-commit --decorate --date=relative --pretty=medium` |
| `overrideGpg` | `false` |
| `disableForcePushing` | `false` |
| `commitPrefix` / `branchPrefix` | empty |
| `parseEmoji` | `true` |
| `log.order` / `showGraph` / `showWholeGraph` | `topo-order` / `always` / `true` |
| `truncateCopiedCommitHashesTo` | `8` |

## Refresh, updates, and OS

| Option | Value |
| --- | --- |
| `update.method` / `days` | `background` / `14` |
| `refresher.refreshInterval` | `10` s |
| `refresher.fetchInterval` | `60` s |
| `confirmOnQuit` | `false` |
| `quitOnTopLevelReturn` | `true` (<kbd>Esc</kbd> at top level quits) |
| `disableStartupPopups` | `true` |
| `notARepository` | `skip` (opens the most recent repo) |
| `promptToReturnFromSubprocess` | `false` |
| `os.edit`, `editAtLine`, `editAtLineAndWait`, `openDirInEditor`, `editPreset`, `open` | empty (lazygit defaults, which follow `$EDITOR` = nvim) |
| `os.openLink` | `bash -C` running `~/.local/share/omarchy/bin/omarchy-launch-webapp {{link}}` (absolute path in the file) |
| `os.copyToClipboardCmd` / `readFromClipboardCmd` | `wl-copy` / `wl-paste` |

> [!NOTE]
> The link opener (`omarchy-launch-webapp`) and the `wl-copy`/`wl-paste` clipboard commands are Wayland/Omarchy-specific. On macOS and Ubuntu, and on Arch without Omarchy, they are unavailable, so opening links and clipboard actions fail there.

## Custom commands

| Key | Context | Command | Output |
| --- | --- | --- | --- |
| <kbd>Ctrl</kbd>+<kbd>i</kbd> | global | `gitv {{.Repository.Owner}}/{{.Repository.Name}}` | terminal |
| <kbd>Ctrl</kbd>+<kbd>w</kbd> | global | `gwm` | terminal |
| <kbd>Ctrl</kbd>+<kbd>a</kbd> | global | `wrkflw` | terminal |
| <kbd>Ctrl</kbd>+<kbd>p</kbd> | global | `github prs` | terminal |
| <kbd>F</kbd> | files | `gh repo sync && gh clean-branches --force` ("Sync repo and clean branches, update DuckDB cache") | log |
| <kbd>A</kbd> | files | `gh commit` ("Smart commit with AI") | terminal |
| <kbd>C</kbd> | files | `gh commit` ("Smart commit with AI") | terminal |
| <kbd>a</kbd> | files | `git add` the file if it has unstaged changes, else `git reset` it ("Toggle file staged") | |
| <kbd>L</kbd> | files | `livediff` | terminal |
| <kbd>Ctrl</kbd>+<kbd>d</kbd> | files | `gh dash` | terminal |
| <kbd>Ctrl</kbd>+<kbd>o</kbd> | files | `gh browse` | |
| <kbd>o</kbd> | localBranches | `gh pr create --fill -w` ("start ai pull request") | |
| <kbd>C</kbd> | localBranches | `gh repo sync && gh clean-branches --force` | log |
| <kbd>O</kbd> | commits | `hub browse -- "commit/{{.SelectedLocalCommit.Hash}}"` | |
| <kbd>n</kbd> | worktrees | Prompts for a branch name, then `wt switch --create <branch> --no-cd` ("New branch + worktree in ~/Work") | terminal |
| <kbd>w</kbd> | localBranches | `wt switch <selected branch> --no-cd` ("Worktree for branch in ~/Work") | terminal |

Worktrees go to `~/Work/<repo>-<branch>`, from worktrunk's `worktree-path` (`dot_config/worktrunk/private_config.toml`). Clones stay under ghq's `~/Code`. lazygit's own worktree flow always names the directory after the branch alone, so the two worktree keys above replace the built-in ones and hand off to `wt`. `worktree.defaultPath: ~/Work` makes the built-in menus that remain, such as detached worktrees from commits and tags, offer `~/Work` as the parent directory. `ghostty-tmux` puts `~/.cargo/bin` on the tmux server's PATH so `wt` resolves in the `prefix g` popup.

`gh commit`, `gh clean-branches`, and `gh dash` are managed gh extensions (see [GitHub CLI](github-cli.md)). `gitv`, `gwm`, `wrkflw`, `github`, `livediff`, and `hub` are not installed by this repo.

> [!WARNING]
> Several custom keys share a key with a built-in binding in the same context: <kbd>C</kbd> and <kbd>a</kbd> in files (`commitChangesWithEditor`, `toggleStagedAll`), <kbd>Ctrl</kbd>+<kbd>w</kbd>, <kbd>Ctrl</kbd>+<kbd>p</kbd>, <kbd>Ctrl</kbd>+<kbd>d</kbd>, <kbd>Ctrl</kbd>+<kbd>o</kbd> against universal bindings, and <kbd>O</kbd> in commits. <kbd>Ctrl</kbd>+<kbd>i</kbd> is the same keycode as <kbd>Tab</kbd> in most terminals.

## Keybindings

The file writes out the full keybinding map. Most values match lazygit's defaults; they are listed so the file is the single reference.

### Universal

| Action | Key |
| --- | --- |
| `quit` / `quit-alt1` | <kbd>q</kbd> / <kbd>Ctrl</kbd>+<kbd>q</kbd> |
| `return` | <kbd>Esc</kbd> |
| `quitWithoutChangingDirectory` | <kbd>Q</kbd> |
| `togglePanel` | <kbd>Tab</kbd> |
| `prevItem` / `nextItem` | <kbd>Up</kbd> / <kbd>Down</kbd> |
| `prevItem-alt` / `nextItem-alt` | <kbd>k</kbd> / <kbd>j</kbd> |
| `prevPage` / `nextPage` | <kbd>,</kbd> / <kbd>.</kbd> |
| `scrollLeft` / `scrollRight` | <kbd>H</kbd> / <kbd>L</kbd> |
| `gotoTop` / `gotoBottom` | `<` / `>` |
| `toggleRangeSelect` | <kbd>v</kbd> |
| `rangeSelectDown` / `rangeSelectUp` | <kbd>Shift</kbd>+<kbd>Down</kbd> / <kbd>Shift</kbd>+<kbd>Up</kbd> |
| `prevBlock` / `nextBlock` | <kbd>Left</kbd> / <kbd>Right</kbd> |
| `prevBlock-alt` / `nextBlock-alt` | <kbd>h</kbd> / <kbd>l</kbd> |
| `nextBlock-alt2` / `prevBlock-alt2` | <kbd>Tab</kbd> / <kbd>Shift</kbd>+<kbd>Tab</kbd> |
| `jumpToBlock` | <kbd>1</kbd>–<kbd>5</kbd> |
| `nextMatch` / `prevMatch` | <kbd>n</kbd> / <kbd>N</kbd> |
| `startSearch` | <kbd>/</kbd> |
| `optionMenu` | <kbd>?</kbd> |
| `select` | <kbd>Space</kbd> |
| `goInto` / `confirm` | <kbd>Enter</kbd> |
| `confirmInEditor` | <kbd>Alt</kbd>+<kbd>Enter</kbd> |
| `remove` | <kbd>d</kbd> |
| `new` | <kbd>n</kbd> |
| `edit` | <kbd>e</kbd> |
| `openFile` | <kbd>o</kbd> |
| `scrollUpMain` / `scrollDownMain` | <kbd>PgUp</kbd> / <kbd>PgDn</kbd> |
| `scrollUpMain-alt1` / `scrollDownMain-alt1` | <kbd>K</kbd> / <kbd>J</kbd> |
| `scrollUpMain-alt2` / `scrollDownMain-alt2` | <kbd>Ctrl</kbd>+<kbd>u</kbd> / <kbd>Ctrl</kbd>+<kbd>d</kbd> |
| `createRebaseOptionsMenu` | <kbd>m</kbd> |
| `pushFiles` / `pullFiles` | <kbd>P</kbd> / <kbd>p</kbd> |
| `refresh` | <kbd>R</kbd> |
| `createPatchOptionsMenu` | <kbd>Ctrl</kbd>+<kbd>p</kbd> |
| `nextTab` / `prevTab` | <kbd>]</kbd> / <kbd>[</kbd> |
| `nextScreenMode` / `prevScreenMode` | <kbd>+</kbd> / <kbd>_</kbd> |
| `undo` / `redo` | <kbd>z</kbd> / <kbd>Ctrl</kbd>+<kbd>z</kbd> |
| `filteringMenu` | <kbd>Ctrl</kbd>+<kbd>s</kbd> |
| `diffingMenu` / `diffingMenu-alt` | <kbd>W</kbd> / <kbd>Ctrl</kbd>+<kbd>e</kbd> |
| `copyToClipboard` | <kbd>Ctrl</kbd>+<kbd>o</kbd> |
| `openRecentRepos` | <kbd>Ctrl</kbd>+<kbd>r</kbd> |
| `submitEditorText` | <kbd>Enter</kbd> |
| `extrasMenu` | <kbd>@</kbd> |
| `toggleWhitespaceInDiffView` | <kbd>Ctrl</kbd>+<kbd>w</kbd> |
| `increaseContextInDiffView` / `decreaseContextInDiffView` | `}` / `{` |
| `increaseRenameSimilarityThreshold` / `decrease...` | <kbd>)</kbd> / <kbd>(</kbd> |
| `openDiffTool` | <kbd>Ctrl</kbd>+<kbd>t</kbd> (runs the nvim `codediff` difftool) |
| `newWorktree` | <kbd>w</kbd> |

### Status

| Action | Key |
| --- | --- |
| `checkForUpdate` | <kbd>u</kbd> |
| `recentRepos` | <kbd>Enter</kbd> |
| `allBranchesLogGraph` | <kbd>a</kbd> |

### Files

| Action | Key |
| --- | --- |
| `commitChanges` | <kbd>c</kbd> |
| `commitChangesWithoutHook` | <kbd>w</kbd> |
| `amendLastCommit` | <kbd>E</kbd> |
| `commitChangesWithEditor` | <kbd>C</kbd> |
| `findBaseCommitForFixup` | <kbd>Ctrl</kbd>+<kbd>f</kbd> |
| `confirmDiscard` | <kbd>x</kbd> |
| `ignoreFile` | <kbd>i</kbd> |
| `refreshFiles` | <kbd>r</kbd> |
| `stashAllChanges` / `viewStashOptions` | <kbd>s</kbd> / <kbd>S</kbd> |
| `toggleStagedAll` | <kbd>a</kbd> |
| `viewResetOptions` | <kbd>D</kbd> |
| `fetch` | <kbd>f</kbd> |
| `toggleTreeView` | `` ` `` |
| `openMergeOptions` | <kbd>M</kbd> |
| `openStatusFilter` | <kbd>Ctrl</kbd>+<kbd>b</kbd> |
| `copyFileInfoToClipboard` | <kbd>y</kbd> |

### Branches

| Action | Key |
| --- | --- |
| `createPullRequest` | <kbd>1</kbd> |
| `viewPullRequestOptions` | <kbd>O</kbd> |
| `copyPullRequestURL` | <kbd>Ctrl</kbd>+<kbd>y</kbd> |
| `checkoutBranchByName` | <kbd>c</kbd> |
| `forceCheckoutBranch` | <kbd>F</kbd> |
| `rebaseBranch` | <kbd>r</kbd> |
| `renameBranch` | <kbd>R</kbd> |
| `mergeIntoCurrentBranch` | <kbd>M</kbd> |
| `viewGitFlowOptions` | <kbd>i</kbd> |
| `fastForward` / `fetchRemote` | <kbd>f</kbd> |
| `createTag` / `pushTag` | <kbd>T</kbd> / <kbd>P</kbd> |
| `setUpstream` | <kbd>u</kbd> |
| `sortOrder` | <kbd>s</kbd> |

### Commits

| Action | Key |
| --- | --- |
| `squashDown` | <kbd>s</kbd> |
| `renameCommit` / `renameCommitWithEditor` | <kbd>r</kbd> / <kbd>R</kbd> |
| `viewResetOptions` | <kbd>g</kbd> |
| `markCommitAsFixup` / `createFixupCommit` | <kbd>f</kbd> / <kbd>F</kbd> |
| `squashAboveCommits` | <kbd>S</kbd> |
| `moveDownCommit` / `moveUpCommit` | <kbd>Ctrl</kbd>+<kbd>j</kbd> / <kbd>Ctrl</kbd>+<kbd>k</kbd> |
| `resetCommitAuthor` | <kbd>a</kbd> |
| `pickCommit` | <kbd>p</kbd> |
| `revertCommit` | <kbd>t</kbd> |
| `cherryPickCopy` / `pasteCommits` | <kbd>C</kbd> / <kbd>V</kbd> |
| `markCommitAsBaseForRebase` | <kbd>B</kbd> |
| `tagCommit` | <kbd>T</kbd> |
| `checkoutCommit` | <kbd>Space</kbd> |
| `resetCherryPick` | <kbd>Ctrl</kbd>+<kbd>c</kbd> |
| `copyCommitAttributeToClipboard` | <kbd>y</kbd> |
| `openLogMenu` | <kbd>Ctrl</kbd>+<kbd>l</kbd> |
| `openInBrowser` | <kbd>o</kbd> |
| `viewBisectOptions` | <kbd>b</kbd> |
| `startInteractiveRebase` | <kbd>i</kbd> |

### Other panels

| Panel | Action | Key |
| --- | --- | --- |
| amendAttribute | `resetAuthor` / `setAuthor` / `addCoAuthor` | <kbd>a</kbd> / <kbd>A</kbd> / <kbd>c</kbd> |
| stash | `popStash` / `renameStash` | <kbd>g</kbd> / <kbd>r</kbd> |
| commitFiles | `checkoutCommitFile` | <kbd>c</kbd> |
| main | `toggleSelectHunk` / `pickBothHunks` / `editSelectHunk` | <kbd>a</kbd> / <kbd>b</kbd> / <kbd>E</kbd> |
| submodules | `init` / `update` / `bulkMenu` | <kbd>i</kbd> / <kbd>u</kbd> / <kbd>b</kbd> |
| commitMessage | `commitMenu` | <kbd>Ctrl</kbd>+<kbd>o</kbd> |

## ii-theme.yml

`ii-theme.yml` is generated by the ii wallpaper theming system and holds only a `gui.theme` block: white active border (bold), grey `#8F9192` inactive border, `#1F1F1F` selection and cherry-pick backgrounds, `#FFF17B` marked base commit, `#FF9BAD` unstaged changes, `#DFE3E3` default text.

Nothing in the repo loads it, so `config.yml`'s cyberdream colors are what lazygit uses. To apply it, pass both files: `LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml,$HOME/.config/lazygit/ii-theme.yml" lazygit`.
