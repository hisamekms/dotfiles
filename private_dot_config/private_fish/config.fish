set DOTFILES_HOME ~/.dotfiles
set PATH ~/.anyenv/bin $PATH
set PATH ~/go/bin $PATH

if command -v anyenv >/dev/null
  eval (anyenv init - fish | source)
end

if command -v direnv >/dev/null
  eval (direnv hook fish)
end

set -U GHQ_SELECTOR peco
set -x EDITOR vim

if test -e $DOTFILES_HOME/config.local.fish
  source $DOTFILES_HOME/config.local.fish
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

function __ghq_ctrl_g
  set -l query (commandline)

  set -l flags
  if test -n "$query"
    set flags --query "$query"
  end

  set -l repo (ghq list -p | peco --tty (tty) $flags)

  if test -n "$repo"
    cd "$repo"
    commandline -r ''
    commandline -f repaint
  end
end

function fish_user_key_bindings
  # unbind fish-ghq key bindings
  bind -e \cg
  bind \cr '__ghq_ctrl_g'
  bind \cq '__peco_z'
  bind \ch peco_select_history
end

mise activate fish | source

# Git
abbr -a g 'git'
abbr -a ga 'git add'
abbr -a gaa 'git add -A'
abbr -a gcm 'git commit -m'
abbr -a gst 'git status'
abbr -a gpl 'git pull'
abbr -a gps 'git push'
abbr -a gplr 'git pull --rebase'
abbr -a gpr 'git push --rebase'
abbr -a gplr 'git pull --rebase'

# Others
abbr -a m 'mise'
