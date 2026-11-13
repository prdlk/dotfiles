# ~/.config/fish/functions/gtm.fish
# Migrate GitHub repos → prad.codes (Gitea) via tea.
# Usage: gtm [<owner>/<repo> | <github-url>]  — no arg: multi-select via fzf

function gtm --description "Migrate GitHub repo(s) to a prad.codes org via tea"
    # -- Preflight ------------------------------------------------------------
    for bin in gh tea gum jq
        if not command -q $bin
            echo "gtm: missing dependency: $bin" >&2
            return 1
        end
    end

    set -l gh_token (gh auth token 2>/dev/null)
    if test -z "$gh_token"
        echo "gtm: gh not authenticated (run: gh auth login)" >&2
        return 1
    end

    # -- Resolve source repos -------------------------------------------------
    # Each entry: nameWithOwner \t isPrivate
    set -l repos

    if test (count $argv) -ge 1
        # Direct mode: accepts owner/repo, https://…, ssh://…, git@host:…
        # Same normalization as ghg-clone: strip scheme, user@, scp colon, .git
        set -l rel (
            printf '%s\n' $argv[1] \
            | sed -E 's#^[[:alnum:]]+://##; s#^[^@/]+@##; s#:#/#; s#\.git$##; s#/+$##'
        )
        # Reduce to owner/repo: take the last two path segments
        set -l parts (string split / -- $rel | string match -rv '^$')
        if test (count $parts) -lt 2
            echo "usage: gtm [<owner>/<repo> | <github-url>]" >&2
            return 1
        end
        # If a host segment is present, it must be github.com — that's the
        # only source this migrator pulls from (clone-url is hardcoded to it)
        if test (count $parts) -gt 2; and test "$parts[-3]" != github.com
            echo "gtm: source must be a github.com repo, got host: $parts[-3]" >&2
            return 1
        end
        set -l nwo "$parts[-2]/$parts[-1]"
        if not string match -qr '^[\w.-]+/[\w.-]+$' -- $nwo
            echo "gtm: could not parse owner/repo from: $argv[1]" >&2
            return 1
        end
        set -l meta (
            gh repo view $nwo \
                --json nameWithOwner,isPrivate \
                --jq '[.nameWithOwner, (.isPrivate|tostring)] | @tsv' 2>/dev/null
        )
        if test -z "$meta"
            echo "gtm: repo not found or inaccessible: $nwo" >&2
            return 1
        end
        set repos $meta
    else
        # Interactive mode: fzf multi-select
        if not command -q fzf
            echo "gtm: missing dependency: fzf" >&2
            return 1
        end
        set repos (
            gh repo list --limit 200 \
                --json nameWithOwner,isPrivate,description \
                --jq '.[] | [.nameWithOwner, (.isPrivate|tostring), .description // ""] | @tsv' \
            | fzf --multi \
                  --delimiter '\t' \
                  --with-nth 1,3 \
                  --prompt 'migrate> ' \
                  --header 'TAB: multi-select · ENTER: confirm' \
                  --preview 'gh repo view {1}' \
                  --preview-window 'right:50%:wrap'
        )
        if test (count $repos) -eq 0
            echo "gtm: nothing selected" >&2
            return 1
        end
    end

    # -- Select target org on prad.codes --------------------------------------
    set -l owner (
        tea organizations list -o simple \
        | string trim \
        | string match -rv '^$' \
        | gum choose --header "Target org on prad.codes"
    )
    if test -z "$owner"
        echo "gtm: no target org selected" >&2
        return 1
    end

    # -- Options --------------------------------------------------------------
    set -l extras (
        gum choose --no-limit \
            --header "Migration options (space to toggle)" \
            "wiki" "issues" "labels" "pull-requests" "releases" "milestones" "lfs" "mirror"
    )
    set -l extra_flags
    for opt in $extras
        set -a extra_flags "--$opt"
    end

    # -- Migrate --------------------------------------------------------------
    set -l failed
    set -l migrated    # repo names successfully landed on prad.codes/$owner
    for line in $repos
        set -l fields (string split \t -- $line)
        set -l nwo $fields[1]
        set -l is_private $fields[2]
        set -l name (string split -m1 / -- $nwo)[2]

        set -l flags --name $name --owner $owner \
            --clone-url "https://github.com/$nwo.git" \
            --service git \
            --auth-token $gh_token \
            $extra_flags

        if test "$is_private" = true
            set -a flags --private
        end

        echo "→ migrating $nwo → prad.codes/$owner/$name"
        if tea repos migrate $flags
            set -a migrated $name
        else
            set -a failed $nwo
            echo "✗ failed: $nwo" >&2
        end
    end

    # -- Optional local clone -------------------------------------------------
    if test (count $migrated) -gt 0
        and gum confirm "Clone "(count $migrated)" migrated repo(s) locally via ghg-clone?"
        set -l last_dir
        for name in $migrated
            set -l dir (ghg-clone "https://prad.codes/$owner/$name")
            if test -n "$dir"
                set last_dir $dir
            else
                echo "✗ clone failed: $owner/$name" >&2
            end
        end
        # Single repo → drop into it (function runs in-shell, so cd sticks)
        if test (count $migrated) -eq 1 -a -n "$last_dir"
            cd $last_dir
        end
    end

    # -- Summary --------------------------------------------------------------
    if test (count $failed) -gt 0
        echo
        echo "gtm: "(count $failed)" migration(s) failed:" >&2
        printf '  %s\n' $failed >&2
        return 1
    end
    echo
    echo "✓ done — "(count $repos)" repo(s) migrated to $owner"
end
