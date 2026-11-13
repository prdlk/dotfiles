function gh-wiki --description "Clone a GitHub wiki and build one PDF from its Markdown pages"
    # Usage: gh-wiki <WIKI URL> [-o OUTPUT.pdf] [-t TEMPLATE] [-d] [-k]
    argparse 'h/help' 'o/output=' 't/template=' 'd/docker' 'k/keep' -- $argv
    or return 1

    if set -q _flag_help; or test (count $argv) -eq 0
        echo "Usage: gh-wiki <WIKI URL> [-o OUTPUT.pdf] [-t TEMPLATE] [-d] [-k]"
        echo "  -o  Output PDF path (default: <repo>-wiki.pdf in the current directory)"
        echo "  -t  Pandoc template (default: eisvogel, from ~/.local/share/pandoc/templates)"
        echo "  -d  Use the pandoc/extra Docker image instead of the local pandoc"
        echo "  -k  Keep the clone in /tmp"
        return 0
    end

    # --- Check dependencies ---------------------------------------------
    set -l deps git gum
    set -l engine
    if set -q _flag_docker
        set -a deps docker
    else
        set -a deps pandoc
        # Eisvogel needs a XeTeX engine; tectonic is a self-contained one.
        for e in xelatex tectonic
            command -q $e; and set engine $e; and break
        end
        if test -z "$engine"
            echo "gh-wiki: install xelatex or tectonic, or pass -d to use Docker" >&2
            return 1
        end
    end
    for bin in $deps
        if not command -q $bin
            echo "gh-wiki: '$bin' is not installed" >&2
            return 1
        end
    end

    set -l url $argv[1]

    # Accept a plain repo URL and turn it into the wiki URL.
    if not string match -q '*.wiki.git' $url
        set url (string replace -r '(\.git)?/?$' '.wiki.git' $url)
    end

    # Repo name: https://github.com/user/repo.wiki.git -> repo
    set -l repo (string replace -r '\.wiki\.git$' '' (basename $url))
    set -l clone_dir (mktemp -d /tmp/gh-wiki-$repo-XXXXXX)
    set -l out "$repo-wiki.pdf"
    set -q _flag_output; and set out $_flag_output

    # --- Clone ----------------------------------------------------------
    gum spin --show-error --spinner dot --title "Cloning $url" -- \
        git clone --quiet --depth 1 $url $clone_dir
    or begin
        gum log --level error "Clone failed: $url"
        rm -rf $clone_dir
        return 1
    end

    # --- Collect pages --------------------------------------------------
    # Home first, then the rest in alphabetical order. Skip wiki chrome.
    set -l pages
    test -f $clone_dir/Home.md; and set -a pages $clone_dir/Home.md
    for f in (find $clone_dir -maxdepth 1 -name '*.md' | sort)
        set -l name (basename $f)
        string match -q 'Home.md' $name; and continue
        string match -q '_*' $name; and continue
        set -a pages $f
    end

    if test (count $pages) -eq 0
        gum log --level error "No Markdown pages found in $url"
        rm -rf $clone_dir
        return 1
    end
    gum log --level info "Found "(count $pages)" pages"

    # --- Build one Markdown source --------------------------------------
    # Each page becomes a chapter. Its own headings move one level down.
    set -l src_name _combined.md
    set -l src $clone_dir/$src_name
    for f in $pages
        set -l title (string replace -a -- '-' ' ' (basename $f .md))
        printf '\n# %s\n\n' "$title" >> $src
        cat $f >> $src
        printf '\n\n' >> $src
    end

    # --- Shared pandoc options ------------------------------------------
    set -l template eisvogel
    set -q _flag_template; and set template $_flag_template
    set -l common_args \
        --from gfm \
        --shift-heading-level-by=1 \
        --toc --toc-depth=2 \
        --number-sections \
        -M title="$repo Wiki" \
        -M date=(date +%Y-%m-%d) \
        -V titlepage=true \
        -V toc-own-page=true

    # --- Render ---------------------------------------------------------
    set -l status_code 0
    if set -q _flag_docker
        # pandoc/extra ships pandoc, LaTeX and Eisvogel. Mount the clone as
        # /data, write the PDF there, then move it to the requested path.
        set -l tmp_pdf _out.pdf
        gum spin --show-error --spinner line --title "Rendering $out" -- \
            docker run --rm \
            --volume "$clone_dir:/data" \
            --user (id -u):(id -g) \
            pandoc/extra $src_name -o $tmp_pdf \
            --resource-path /data \
            --template $template --pdf-engine xelatex \
            $common_args
        set status_code $status
        test $status_code -eq 0; and mv $clone_dir/$tmp_pdf $out
    else
        set -l pandoc_args --pdf-engine $engine
        # Tectonic's bundle lacks Eisvogel's default sourcesans/sourcecodepro
        # packages; naming system fonts makes the template skip them.
        test $engine = tectonic; and set -a pandoc_args \
            -V mainfont="Noto Sans" -V monofont="JetBrains Mono"
        set -l data_dir (pandoc --version | string match -r 'User data directory: (.*)' | tail -n1)
        if test -f "$data_dir/templates/$template.latex"; or test -f "$template"
            set -a pandoc_args --template $template
        else
            gum log --level warn "Template '$template' not found; using the pandoc default"
        end
        gum spin --show-error --spinner line --title "Rendering $out" -- \
            pandoc $src -o $out \
            --resource-path $clone_dir \
            $pandoc_args \
            $common_args
        set status_code $status
    end

    # --- Clean up -------------------------------------------------------
    if set -q _flag_keep
        gum log --level info "Clone kept at $clone_dir"
    else
        rm -rf $clone_dir
    end

    if test $status_code -ne 0
        gum log --level error "pandoc failed"
        return $status_code
    end
    gum log --level info "Wrote $out"
end
