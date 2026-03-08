if not status is-interactive; or not test -t 1
  exit
end


function __fzf_z
  set -l query (commandline)

  if test -n $query
    set flags --query "$query"
  end

  cat $Z_DATA | awk 'BEGIN{FS="|"} { print $3,$1 }' | sort -nr | awk '{ print $2 }' | fzf --height 40% --reverse $flags | read foo
  if [ $foo ]
      cd $foo
      commandline -r ''
      commandline -f repaint
  end
end

function fzf_select_history
  if test (count $argv) = 0
    set fzf_flags --height 40% --reverse
  else
    set fzf_flags --height 40% --reverse --query "$argv"
  end

  history | fzf $fzf_flags | read foo

  if [ $foo ]
    commandline $foo
  else
    commandline ''
  end
end
