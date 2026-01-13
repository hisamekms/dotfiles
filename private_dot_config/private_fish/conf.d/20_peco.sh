if not status is-interactive; or not test -t 1
  exit
end


function __peco_z
  set -l query (commandline)

  if test -n $query
    set flags --query "$query"
  end

  cat $Z_DATA | awk 'BEGIN{FS="|"} { print $3,$1 }' | sort -nr | awk '{ print $2 }' | peco $flags | read foo
  if [ $foo ]
      cd $foo
      commandline -r ''
      commandline -f repaint
  end
end

function peco_select_history
  if test (count $argv) = 0
    set flags
  else
    set flags --query "$argv"
  end

  history|peco $flags|read foo

  if [ $foo ]
    commandline $foo
  else
    commandline ''
  end
end

function ghq_peco
    set -l repo (ghq list --full-path | peco)
    if test -n "$repo"
        cd "$repo"
    end
end

function fish_user_key_bindings
  # unbind fish-ghq key bindings
  bind \cr 'ghq_peco'
  bind \cq '__peco_z'
  bind \ch peco_select_history
end