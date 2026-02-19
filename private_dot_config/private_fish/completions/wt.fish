# Completions for wt (git worktree manager)

# Disable file completions by default
complete -c wt -f

# Helper: list worktree branch names
function __wt_complete_branches
    git worktree list --porcelain 2>/dev/null | while read -l line
        if string match -qr '^branch ' -- $line
            string replace 'branch refs/heads/' '' -- $line
        end
    end
end

# Helper: check if a subcommand has already been given
function __wt_needs_subcmd
    set -l cmd (commandline -opc)
    for subcmd in add rm remove ls list cd
        if contains -- $subcmd $cmd
            return 1
        end
    end
    return 0
end

function __wt_using_subcmd --argument-names subcmd
    set -l cmd (commandline -opc)
    contains -- $subcmd $cmd
end

# Subcommand completions
complete -c wt -n __wt_needs_subcmd -a add -d "Create a worktree"
complete -c wt -n __wt_needs_subcmd -a rm -d "Remove a worktree"
complete -c wt -n __wt_needs_subcmd -a ls -d "List worktrees"
complete -c wt -n __wt_needs_subcmd -a cd -d "Change directory to a worktree"

# `wt add` — complete with local branch names for base arg
complete -c wt -n '__wt_using_subcmd add' -a '(git for-each-ref --format="%(refname:short)" refs/heads/ 2>/dev/null)'

# `wt rm` — complete with worktree branch names
complete -c wt -n '__wt_using_subcmd rm' -a '(__wt_complete_branches)'
complete -c wt -n '__wt_using_subcmd remove' -a '(__wt_complete_branches)'

# `wt cd` — complete with worktree branch names
complete -c wt -n '__wt_using_subcmd cd' -a '(__wt_complete_branches)'
