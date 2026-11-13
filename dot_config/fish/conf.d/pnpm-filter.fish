# ~/.config/fish/conf.d/pnpm-filter.fish

# Shared helper: pick a workspace package name via gum filter
function __pnpm_pick_pkg
    pnpm m ls --depth -1 --json 2>/dev/null \
        | jq -r '.[] | select(.name != null) | .name' \
        | gum filter --placeholder "Select package…" --height 12
end

# pnpmf: add deps to a selected package
# usage: pnpmf viem zod
function pnpmf -d "pnpm add to a workspace package (gum filter)"
    set -l pkg (__pnpm_pick_pkg); or return
    gum spin --title "Adding $argv → $pkg" -- pnpm --filter $pkg add $argv
end

# pnpmfd: add devDependencies
function pnpmfd -d "pnpm add -D to a workspace package"
    set -l pkg (__pnpm_pick_pkg); or return
    gum spin --title "Adding (dev) $argv → $pkg" -- pnpm --filter $pkg add -D $argv
end

# pnpmfr: remove deps
function pnpmfr -d "pnpm remove from a workspace package"
    set -l pkg (__pnpm_pick_pkg); or return
    pnpm --filter $pkg remove $argv
end

# pnpmfw: link a sibling workspace package (workspace:^)
function pnpmfw -d "pnpm add --workspace sibling package"
    set -l pkg (__pnpm_pick_pkg); or return
    set -l dep (__pnpm_pick_pkg); or return
    pnpm --filter $pkg add $dep --workspace
end

# pnpmfx: run a script in a selected package, script also picked via gum
function pnpmfx -d "pnpm run script in a workspace package"
    set -l pkg (__pnpm_pick_pkg); or return
    set -l dir (pnpm m ls --depth -1 --json | jq -r ".[] | select(.name == \"$pkg\") | .path")
    set -l script (jq -r '.scripts | keys[]' $dir/package.json | gum filter --placeholder "Script…"); or return
    pnpm --filter $pkg run $script
end
