function ghuser --description "Manage GitHub user for gh CLI and mise"
    set -l subcmd $argv[1]
    set -e argv[1]

    switch "$subcmd"
        case switch sw
            __ghuser_switch $argv
        case init
            __ghuser_init $argv
        case status st
            __ghuser_status
        case ''
            __ghuser_usage
            return 1
        case '*'
            echo "ghuser: unknown subcommand '$subcmd'" >&2
            __ghuser_usage
            return 1
    end
end

function __ghuser_usage
    echo "Usage: ghuser <subcommand> [args]"
    echo ""
    echo "Subcommands:"
    echo "  switch [user]  Switch active GitHub user (fzf if no arg)"
    echo "  init [user]    Generate .mise.local.toml with GH_USER in current dir"
    echo "  status         Show current GitHub user"
end

function __ghuser_status
    echo "=== gh auth ==="
    gh auth status 2>&1
    echo ""
    if test -n "$GH_USER"
        echo "GH_USER: $GH_USER"
    else
        echo "GH_USER: (not set)"
    end
    if test -n "$GH_TOKEN"
        echo "GH_TOKEN: (set)"
    else
        echo "GH_TOKEN: (not set)"
    end
end

function __ghuser_list
    # Parse users from gh hosts.yml
    set -l hosts_file "$HOME/.config/gh/hosts.yml"
    if not test -f "$hosts_file"
        echo "ghuser: $hosts_file not found" >&2
        return 1
    end

    # Get active user
    set -l active_user (gh api user --jq .login 2>/dev/null)

    # Get all users: the top-level "user:" plus any under "users:"
    set -l users

    # Active user from config
    set -l main_user (string trim (grep -A0 '^\s*user:' "$hosts_file" | head -1 | sed 's/.*user:\s*//'))
    if test -n "$main_user"
        set -a users $main_user
    end

    # Additional users under "users:" section
    set -l in_users_block false
    for line in (cat "$hosts_file")
        if string match -qr '^\s+users:' -- $line
            set in_users_block true
            continue
        end
        if test "$in_users_block" = true
            if string match -qr '^\s{8}\w' -- $line
                set -l u (string trim -- $line | string replace -r ':$' '')
                if not contains -- $u $users
                    set -a users $u
                end
            else if not string match -qr '^\s{12}' -- $line
                # Exited the users block (not a sub-key of a user entry)
                if not string match -qr '^\s{8,}' -- $line
                    set in_users_block false
                end
            end
        end
    end

    printf '%s\n' $users
end

function __ghuser_switch
    set -l target $argv[1]

    if test -z "$target"
        # Interactive selection
        set -l users (__ghuser_list)
        if test $status -ne 0; or test (count $users) -eq 0
            echo "ghuser: no GitHub users found" >&2
            return 1
        end

        if test (count $users) -eq 1
            set target $users[1]
            echo "Only one user available: $target"
        else
            if not command -v fzf >/dev/null 2>&1
                echo "ghuser: fzf is required for interactive selection" >&2
                echo "Available users:"
                printf '  %s\n' $users
                return 1
            end
            set target (printf '%s\n' $users | fzf --prompt="Select GitHub user: ")
            if test -z "$target"
                return 1
            end
        end
    end

    # Switch gh auth
    gh auth switch --user "$target" 2>&1
    if test $status -ne 0
        echo "ghuser: failed to switch to '$target'" >&2
        return 1
    end

    # Set environment variables for current shell
    set -gx GH_USER "$target"
    set -gx GH_TOKEN (gh auth token --user "$target" 2>/dev/null)

    echo "Switched to $target"
    echo "GH_USER and GH_TOKEN set for current shell"
end

function __ghuser_init
    set -l target $argv[1]

    if test -z "$target"
        # Use current GH_USER or active user
        if test -n "$GH_USER"
            set target $GH_USER
        else
            set target (gh api user --jq .login 2>/dev/null)
        end
    end

    if test -z "$target"
        echo "ghuser: could not determine user. Specify: ghuser init <user>" >&2
        return 1
    end

    set -l gh_env_path "$HOME/.local/bin/gh-env"

    # Detect existing file: prefer whichever already exists, default to mise.local.toml
    set -l toml_file ""
    if test -f "mise.local.toml"
        set toml_file "mise.local.toml"
    else if test -f ".mise.local.toml"
        set toml_file ".mise.local.toml"
    else
        set toml_file "mise.local.toml"
    end

    if test -f "$toml_file"
        # Update or append GH_USER
        if grep -q 'GH_USER' "$toml_file"
            sed -i "s/GH_USER = \".*\"/GH_USER = \"$target\"/" "$toml_file"
            echo "Updated GH_USER in $toml_file → $target"
        else if grep -q '^\[env\]' "$toml_file"
            # [env] exists but no GH_USER — append GH_USER and _.source if needed
            sed -i "/^\[env\]/a GH_USER = \"$target\"" "$toml_file"
            if not grep -q '_.source' "$toml_file"
                sed -i "/^GH_USER/a _.source = \"$gh_env_path\"" "$toml_file"
            end
            echo "Added GH_USER to $toml_file → $target"
        else
            # No [env] section — append one
            echo "" >> "$toml_file"
            echo "[env]" >> "$toml_file"
            echo "GH_USER = \"$target\"" >> "$toml_file"
            echo "_.source = \"$gh_env_path\"" >> "$toml_file"
            echo "Added [env] with GH_USER to $toml_file → $target"
        end

        # Ensure _.source exists
        if not grep -q '_.source' "$toml_file"
            sed -i "/^GH_USER/a _.source = \"$gh_env_path\"" "$toml_file"
        end
    else
        # Create new file
        echo "[env]" > "$toml_file"
        echo "GH_USER = \"$target\"" >> "$toml_file"
        echo "_.source = \"$gh_env_path\"" >> "$toml_file"
        echo "Created $toml_file with GH_USER = \"$target\""
    end
end
