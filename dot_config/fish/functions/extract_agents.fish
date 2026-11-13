function extract_agents -d "Copy all AGENTS.md files to a target directory while preserving structure"
    set -l out_dir $argv[1]

    # Validate input
    if test -z "$out_dir"
        echo "Error: Output directory required."
        echo "Usage: extract_agents <absolute_or_relative_output_path>"
        return 1
    end

    # Ensure output directory exists
    mkdir -p $out_dir

    # Find and copy preserving relative paths
    fd -t f -g "AGENTS.md" -x cp --parents "{}" $out_dir

    echo "Extraction complete. Check $out_dir."
end
