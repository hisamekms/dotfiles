# peco-find-cd() {
#   local FILENAME="$1"
#   local MAXDEPTH="${2:-3}"
#   local BASE_DIR="${3:-`pwd`}"

#   if [ -z "$FILENAME" ] ; then
#     echo "Usage: peco-find-cd <FILENAME> [<MAXDEPTH> [<BASE_DIR>]]" >&2
#     return 1
#   fi

#   local DIR=$(find ${BASE_DIR} -maxdepth ${MAXDEPTH} -name ${FILENAME} | peco | head -n 1)

#   if [ -n "$DIR" ] ; then
#     DIR=${DIR%/*}
#     echo "pushd \"$DIR\""
#     pushd "$DIR"
#   fi
# }

alias -g L='ls | peco'
# alias -g F='peco-find-cd'
alias peco-pushd="pushd +\$(dirs -p -v -l | sort -k 2 -k 1n | uniq -f 1 | sort -n | peco | head -n 1 | awk '{print \$1}')"
alias pp=peco-pushd

function peco-src () {
  local selected_dir=$(ghq list -p | peco --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N peco-src
bindkey '^[' peco-src

setopt hist_ignore_all_dups

function peco_select_history() {
  local tac
  if which tac > /dev/null; then
    tac="tac"
  else
    tac="tail -r"
  fi
  BUFFER=$(fc -l -n 1 | eval $tac | peco --query "$LBUFFER")
  CURSOR=$#BUFFER
  zle clear-screen
}
zle -N peco_select_history
bindkey '^h' peco_select_history

function peco-select-path() {
  local filepath="$(find . -maxdepth 5 | grep -v '/\.' | peco --prompt 'PATH>')"
  if [ "$LBUFFER" -eq "" ]; then
    if [ -d "$filepath" ]; then
      BUFFER="cd $filepath"
    elif [ -f "$filepath" ]; then
      BUFFER="$EDITOR $filepath"
    fi
  else
    BUFFER="$LBUFFER$filepath"
  fi
  CURSOR=$#BUFFER
  zle clear-screen
}

zle -N peco-select-path
bindkey '^E' peco-select-path

function peco-cd() {
  local filepath="$(find . -type d -maxdepth 5 | peco --prompt 'PATH>')"
  BUFFER="cd $filepath"
  zle accept-line
  zle clear-screen
}
zle -N peco-cd
bindkey '^F' peco-cd
