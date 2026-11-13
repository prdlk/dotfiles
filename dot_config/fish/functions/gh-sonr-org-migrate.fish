#!/usr/bin/env fish
# sonr-consolidate.fish
# Migrates all repos from orgs matching "sonr" into sonr-io,
# prompting via gum for renames on collision, then deletes emptied orgs.
#
# Requires: gh (authenticated as org owner on all orgs), gum, jq

set -g TARGET_ORG sonr-io

# ── Preflight ────────────────────────────────────────────────────────────────
for bin in gh gum jq
    if not command -q $bin
        echo (set_color red)"missing dependency: $bin"(set_color normal)
        exit 1
    end
end

if not gh auth status &>/dev/null
    echo (set_color red)"gh is not authenticated"(set_color normal)
    exit 1
end

# ── Discover source orgs ─────────────────────────────────────────────────────
# All orgs the user belongs to whose login contains "sonr", excluding target.
set -l source_orgs (gh api user/orgs --paginate --jq '.[].login' \
    | string match -r '.*sonr.*' \
    | string match -v $TARGET_ORG)

if test (count $source_orgs) -eq 0
    echo "No source orgs found. Nothing to do."
    exit 0
end

echo (set_color cyan)"Source orgs:"(set_color normal)
printf '  %s\n' $source_orgs
echo (set_color cyan)"Target org:"(set_color normal)" $TARGET_ORG"
echo

# Let the user confirm / trim the list interactively
set -l selected_orgs (printf '%s\n' $source_orgs | gum choose --no-limit \
    --header "Select orgs to migrate into $TARGET_ORG (space to toggle, enter to confirm)")

if test (count $selected_orgs) -eq 0
    echo "Nothing selected. Exiting."
    exit 0
end

# ── Helpers ──────────────────────────────────────────────────────────────────
function repo_exists_in_target
    gh api "repos/$TARGET_ORG/$argv[1]" --silent &>/dev/null
end

function transfer_repo
    # $1 = source org, $2 = repo name, $3 = (optional) new name
    set -l src $argv[1]
    set -l repo $argv[2]
    set -l args -f new_owner=$TARGET_ORG
    if set -q argv[3]; and test -n "$argv[3]"
        set -a args -f new_name=$argv[3]
    end
    gh api -X POST "repos/$src/$repo/transfer" $args --silent
end

# ── Migration ────────────────────────────────────────────────────────────────
set -g failed_transfers

for org in $selected_orgs
    echo
    echo (set_color --bold cyan)"── $org ──"(set_color normal)

    set -l repos (gh api "orgs/$org/repos" --paginate --jq '.[].name')

    if test (count $repos) -eq 0
        echo "  (no repos)"
        continue
    end

    for repo in $repos
        set -l new_name ""

        if repo_exists_in_target $repo
            echo (set_color yellow)"  ⚠ $repo already exists in $TARGET_ORG"(set_color normal)
            while true
                set new_name (gum input \
                    --header "New name for $org/$repo (exists in $TARGET_ORG)" \
                    --placeholder "$org-$repo" \
                    --value "$org-$repo")
                if test -z "$new_name"
                    echo "    skipped $org/$repo"
                    set new_name __SKIP__
                    break
                end
                if repo_exists_in_target $new_name
                    echo (set_color yellow)"    $new_name also exists — pick another"(set_color normal)
                else
                    break
                end
            end
            test "$new_name" = __SKIP__; and continue
        end

        set -l label "$org/$repo → $TARGET_ORG/"(test -n "$new_name"; and echo $new_name; or echo $repo)
        if transfer_repo $org $repo $new_name
            echo (set_color green)"  ✓ $label"(set_color normal)
        else
            echo (set_color red)"  ✗ failed: $label"(set_color normal)
            set -a failed_transfers "$org/$repo"
        end
    end
end

if test (count $failed_transfers) -gt 0
    echo
    echo (set_color red)"Failed transfers (orgs containing these will NOT be deleted):"(set_color normal)
    printf '  %s\n' $failed_transfers
end

# ── Wait for transfers to settle ─────────────────────────────────────────────
# GitHub repo transfers are asynchronous; give them time to drain.
echo
gum spin --title "Waiting 30s for transfers to settle..." -- sleep 30

# ── Delete emptied orgs ──────────────────────────────────────────────────────
echo
for org in $selected_orgs
    # Skip orgs with failed transfers
    if string match -q "$org/*" -- $failed_transfers
        echo (set_color yellow)"skipping delete: $org (had failures)"(set_color normal)
        continue
    end

    set -l remaining (gh api "orgs/$org/repos" --paginate --jq '. | length' | jq -s 'add // 0')

    if test "$remaining" -gt 0
        echo (set_color yellow)"skipping delete: $org still has $remaining repo(s) (transfer pending?)"(set_color normal)
        continue
    end

    if gum confirm "Delete empty org $org?"
        if gh api -X DELETE "orgs/$org" --silent
            echo (set_color green)"✓ deleted $org"(set_color normal)
        else
            echo (set_color red)"✗ could not delete $org (API delete requires org owner; may need manual deletion in Settings)"(set_color normal)
        end
    else
        echo "kept $org"
    end
end

echo
echo (set_color --bold green)"Done."(set_color normal)
