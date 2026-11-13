function git-summary --description "Aggregate all AGENTS.md files in the current git repo via code2prompt"
    # Resolve the repo root so it works from any subdirectory
    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo_root"
        echo "git-summary: not inside a git repository" >&2
        return 1
    end
 
    set -l template ~/.config/code2prompt/agents-md.hbs
    if not test -f $template
        echo "git-summary: template not found at $template" >&2
        return 1
    end
 
    # Pass through any extra flags (e.g. --output-file, --tokens)
    code2prompt $repo_root \
        --include "AGENTS.md" \
        --include "**/AGENTS.md" \
        --template $template \
        $argv
end
 
