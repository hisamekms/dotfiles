if command -v wtp > /dev/null 2>&1
    wtp completion fish | source
end

if not status is-interactive; or not test -t 1
  exit
end

function wtp_fzf
    if not command -v fzf > /dev/null 2>&1
        echo "fzf is not installed"
        return 1
    end

    if not command -v wtp > /dev/null 2>&1
        echo "wtp is not installed"
        return 1
    end

    set -l selected (wtp list --quiet | fzf)
    if test -n "$selected"
        set -l cd_path (wtp cd $selected)
        if test -n "$cd_path"
            cd "$cd_path"
        end
        commandline -f repaint
    end
end
