function wt --description "Manage git worktrees"
    if not command -v git >/dev/null 2>&1
        echo "wt: git is not installed" >&2
        return 1
    end

    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "wt: not a git repository" >&2
        return 1
    end

    set -l subcmd $argv[1]
    set -e argv[1]

    switch "$subcmd"
        case add
            __wt_add $argv
        case rm remove
            __wt_rm $argv
        case ls list
            __wt_ls
        case cd
            __wt_cd $argv
        case ''
            __wt_usage
            return 1
        case '*'
            echo "wt: unknown subcommand '$subcmd'" >&2
            __wt_usage
            return 1
    end
end

function __wt_usage
    echo "Usage: wt <subcommand> [args]"
    echo ""
    echo "Subcommands:"
    echo "  add <branch> [base]  Create a worktree for <branch>"
    echo "  rm <branch>          Remove a worktree by branch name"
    echo "  ls                   List worktrees"
    echo "  cd [branch]          Change directory to a worktree (fzf if no arg)"
end

function __wt_repo_root
    set -l git_common_dir (git rev-parse --git-common-dir 2>/dev/null)
    if test $status -ne 0
        return 1
    end
    # --git-common-dir returns path relative to cwd or absolute
    # If it ends with "/.git", strip it to get repo root
    # If it's ".git", use cwd's repo root
    set -l resolved (realpath "$git_common_dir")
    string replace -r '/\.git$' '' -- $resolved
end

function __wt_resolve_path --argument-names branch
    set -l lines (git worktree list --porcelain 2>/dev/null)
    set -l current_path ""
    for line in $lines
        if string match -qr '^worktree ' -- $line
            set current_path (string replace 'worktree ' '' -- $line)
        else if string match -qr '^branch ' -- $line
            set -l ref (string replace 'branch ' '' -- $line)
            set -l b (string replace 'refs/heads/' '' -- $ref)
            if test "$b" = "$branch"
                echo $current_path
                return 0
            end
        end
    end
    return 1
end

function __wt_add
    if test (count $argv) -lt 1
        echo "Usage: wt add <branch> [base]" >&2
        return 1
    end

    set -l branch $argv[1]
    set -l base $argv[2]
    set -l repo_root (__wt_repo_root)
    set -l wt_path "$repo_root/worktrees/$branch"

    # Check if worktree already exists for this branch
    if __wt_resolve_path "$branch" >/dev/null 2>&1
        echo "wt: worktree for '$branch' already exists" >&2
        return 1
    end

    # Check if branch already exists
    if git show-ref --verify --quiet "refs/heads/$branch"
        # Existing branch — checkout
        git worktree add "$wt_path" "$branch"
    else
        # New branch
        if test -n "$base"
            git worktree add -b "$branch" "$wt_path" "$base"
        else
            git worktree add -b "$branch" "$wt_path"
        end
    end

    if test $status -eq 0
        echo "Created worktree at $wt_path"
    end
end

function __wt_rm
    if test (count $argv) -lt 1
        echo "Usage: wt rm <branch>" >&2
        return 1
    end

    set -l branch $argv[1]
    set -l wt_path (__wt_resolve_path "$branch")
    if test $status -ne 0
        echo "wt: no worktree found for branch '$branch'" >&2
        return 1
    end

    # Refuse to remove the main worktree
    set -l repo_root (__wt_repo_root)
    if test "$wt_path" = "$repo_root"
        echo "wt: refusing to remove main worktree" >&2
        return 1
    end

    # If we're inside the worktree being removed, cd to repo root first
    if string match -q "$wt_path*" -- (pwd)
        cd "$repo_root"
    end

    git worktree remove "$wt_path"
    if test $status -eq 0
        echo "Removed worktree for '$branch'"
    end
end

function __wt_ls
    set -l repo_root (__wt_repo_root)
    set -l lines (git worktree list --porcelain 2>/dev/null)
    set -l current_path ""
    set -l current_branch ""
    set -l entries

    for line in $lines
        if string match -qr '^worktree ' -- $line
            set current_path (string replace 'worktree ' '' -- $line)
            set current_branch "(detached)"
        else if string match -qr '^branch ' -- $line
            set -l ref (string replace 'branch ' '' -- $line)
            set current_branch (string replace 'refs/heads/' '' -- $ref)
        else if test -z "$line"
            # Empty line = end of entry
            if test -n "$current_path"
                set -l display_path
                if test "$current_path" = "$repo_root"
                    set display_path "."
                else
                    set display_path (string replace "$repo_root/" '' -- $current_path)
                end
                set -a entries (printf "%-30s %s" "$current_branch" "$display_path")
            end
            set current_path ""
            set current_branch ""
        end
    end

    # Handle last entry (porcelain output may not end with blank line)
    if test -n "$current_path"
        set -l display_path
        if test "$current_path" = "$repo_root"
            set display_path "."
        else
            set display_path (string replace "$repo_root/" '' -- $current_path)
        end
        set -a entries (printf "%-30s %s" "$current_branch" "$display_path")
    end

    for entry in $entries
        echo $entry
    end
end

function __wt_cd
    if test (count $argv) -ge 1
        # Direct cd to specified branch
        set -l wt_path (__wt_resolve_path "$argv[1]")
        if test $status -ne 0
            echo "wt: no worktree found for branch '$argv[1]'" >&2
            return 1
        end
        cd "$wt_path"
        return
    end

    # Interactive selection with fzf
    if not command -v fzf >/dev/null 2>&1
        echo "wt: fzf is required for interactive selection" >&2
        return 1
    end

    set -l repo_root (__wt_repo_root)
    set -l lines (git worktree list --porcelain 2>/dev/null)
    set -l current_path ""
    set -l current_branch ""
    set -l candidates

    for line in $lines
        if string match -qr '^worktree ' -- $line
            set current_path (string replace 'worktree ' '' -- $line)
            set current_branch "(detached)"
        else if string match -qr '^branch ' -- $line
            set -l ref (string replace 'branch ' '' -- $line)
            set current_branch (string replace 'refs/heads/' '' -- $ref)
        else if test -z "$line"
            if test -n "$current_path"
                set -a candidates "$current_branch\t$current_path"
            end
            set current_path ""
            set current_branch ""
        end
    end

    # Handle last entry
    if test -n "$current_path"
        set -a candidates "$current_branch\t$current_path"
    end

    if test (count $candidates) -eq 0
        echo "wt: no worktrees found" >&2
        return 1
    end

    set -l selected (printf '%s\n' $candidates | fzf --with-nth=1 --delimiter='\t')
    if test -n "$selected"
        set -l target (string split \t -- $selected)[2]
        cd "$target"
        commandline -f repaint
    end
end
