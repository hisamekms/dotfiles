peco-find-cd() {
  local FILENAME="$1"
  local MAXDEPTH="${2:-3}"
  local BASE_DIR="${3:-`pwd`}"

  if [ -z "$FILENAME" ] ; then
    echo "Usage: peco-find-cd <FILENAME> [<MAXDEPTH> [<BASE_DIR>]]" >&2
    return 1
  fi

  local DIR=$(find ${BASE_DIR} -maxdepth ${MAXDEPTH} -name ${FILENAME} | peco | head -n 1)

  if [ -n "$DIR" ] ; then
    DIR=${DIR%/*}
    echo "pushd \"$DIR\""
    pushd "$DIR"
  fi
}

alias -g L='ls | peco'
alias -g F='peco-find-cd'
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
bindkey '^]' peco-src