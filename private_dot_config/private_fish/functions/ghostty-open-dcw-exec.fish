function ghostty-open-dcw-exec --description "Open Ghostty and run dcw exec <cmd>, optionally repeated"
    argparse 'r=' -- $argv
    or return 1

    if test (count $argv) -lt 1
        echo "Usage: ghostty-open-dcw-exec [-r <count>] <command>"
        return 1
    end

    set -l cmd $argv[1]
    set -l dir (pwd)
    set -l n 1
    if test -n "$_flag_r"
        set n $_flag_r
    end

    for i in (seq $n)
        open -na Ghostty.app --args -e fish -c "cd $dir; dcw exec $cmd"
    end
end
