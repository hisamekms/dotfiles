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

    # github.com/user/repo -> user/repo, others keep site/user/repo
    set -l selected
    switch "$selector"
        case fzf fzf-tmux
            ghq list | string replace 'github.com/' '' | "$selector" $selector_options $flags | read selected
        case fzy sk
            ghq list | string replace 'github.com/' '' | "$selector" $selector_options $flags | read selected
        case \*
            printf "\nERROR: plugin-ghq is not support '$selector'.\n"
    end
    if [ -n "$selected" ]
        set -l target "$root/$selected"
        if not test -d "$target"
            set target "$root/github.com/$selected"
        end
        if test -d "$target"
            cd "$target"
        end
    end
    commandline -f repaint
end
