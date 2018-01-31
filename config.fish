set PATH ~/.anyenv/bin $PATH
eval (anyenv init - | source)
set PATH ~/go/bin $PATH
set -U GHQ_SELECTOR peco
set DOTFILES_HOME ~/.dotfiles

function update
  fish $DOTFILES_HOME/setup.fish
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

function fish_user_key_bindings
  # unbind fish-ghq key bindings
  bind -e \cg
  bind \cr '__ghq_crtl_g'
  bind \cq '__peco_z'
  bind \ch 'peco_select_history (commandline -b)'
end
