# peco + ls
function ls-peco() {
  FILTERD_LS=$(ls | peco)
  BUFFER=${BUFFER}${FILTERD_LS}
  CURSOR=$#BUFFER
}
alias -g L='$(ls-peco)'
zle -N ls-peco
bindkey "^l" ls-peco
