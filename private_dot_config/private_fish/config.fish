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

function ghq_peco
    set -l repo (ghq list --full-path | peco)
    if test -n "$repo"
        cd "$repo"
    end
end

function __fzf_wtp_cd
    set -l selected
    if command -v wtp >/dev/null 2>&1; and command -v fzf >/dev/null 2>&1
        set selected (wtp list 2>/dev/null | awk 'NR>2 && NF>0 {print $1}' | fzf --height 40% --border)
        if test -n "$selected"
            if test "$selected" = "@"
                cd "/workspace"
            else
                cd "/workspace/worktrees/$selected"
            end
        end
    end
end

function fish_user_key_bindings
  # unbind fish-ghq key bindings
  bind -e \cg
  bind \cr 'ghq_peco'
  bind \cq '__peco_z'
  bind \ch peco_select_history
  bind \cw '__fzf_wtp_cd'
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
abbr -a mr 'mise run'
abbr -a che 'chezmoi'

wtp shell-init fish | source
