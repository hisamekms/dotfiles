function __ghq_repository_search -d 'Repository search'
    set -l selector
    [ -n "$GHQ_SELECTOR" ]; and set selector $GHQ_SELECTOR; or set selector fzf
    set -l selector_options
    [ -n "$GHQ_SELECTOR_OPTS" ]; and set selector_options $GHQ_SELECTOR_OPTS

    if not type -qf $selector
        printf "\nERROR: '$selector' not found.\n"
        return 1
    end

    set -l query (commandline -b)
    [ -n "$query" ]; and set flags --query="$query"; or set flags

    set -l root (ghq root)

    # Build entries: short_label \t full_path
    # github.com/user/repo -> user/repo, others keep site/user/repo
    set -l entries
    for full in (ghq list --full-path)
        set -l rel (string replace -- "$root/" '' "$full")
        set -l short (string replace -- 'github.com/' '' "$rel")
        set -a entries "$short\t$full"
    end

    set -l select
    switch "$selector"
        case fzf fzf-tmux
            printf '%s\n' $entries | "$selector" $selector_options $flags --delimiter='\t' --with-nth=1 | read select
        case peco percol fzy sk
            # selectors without --with-nth: show short label, look up full path after
            set -l picked (printf '%s\n' $entries | string split -f1 \t | "$selector" $selector_options $flags)
            [ -n "$picked" ]; and set select (printf '%s\n' $entries | string match -- "$picked\t*")
        case \*
            printf "\nERROR: plugin-ghq is not support '$selector'.\n"
    end
    if [ -n "$select" ]
        set -l full_path (string split \t -- "$select")[2]
        cd "$full_path"
    end
    commandline -f repaint
end
