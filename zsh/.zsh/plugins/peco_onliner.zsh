ONELINER_DIR=~/.oneliner
ONELINER_TXT=${ONELINER_DIR}/oneliner.txt
ONELINER_PARAM_MARKER_PREFIX="%%"

# ワンライナー登録
function _insert-oneliner() {
  autoload -Uz read-from-minibuffer
  read-from-minibuffer "Insert oneliner comment:"
  if [ -n ${REPLY} ]
  then
    if [ ! -d ${ONELINER_DIR} ]
    then
      mkdir ${ONELINER_DIR}
    fi
    echo ${BUFFER}"\t#"${REPLY} >> ${ONELINER_TXT}
    zle -M "Inserted \"${BUFFER}\" >> ${ONELINER_TXT}"
  fi
}
zle -N _insert-oneliner
bindkey "^[i" _insert-oneliner

# pecoで選択したonelinerコマンドを表示
function peco-search-oneliner() {
  BUFFER=$(cat ${ONELINER_TXT} | sort | peco | awk -F"\t" '{print $1}')
  zle clear-screen
  zle beginning-of-line
}
zle -N peco-search-oneliner
bindkey "^po" peco-search-oneliner

# コマンドライン上の可変パラメータ(%%HOGE)を置換
function _kill-oneliner-param-forward() {
  local AT
  AT=$(echo ${RBUFFER} | awk -v marker="${ONELINER_PARAM_MARKER_PREFIX}" '{print index($0, marker)}')
  if [ $AT -ne 0 ]
  then
    CURSOR=$((CURSOR+AT-1))
    for i in {1..${#ONELINER_PARAM_MARKER_PREFIX}}
    do
      zle delete-char-or-list
    done
    zle kill-word
  else
    zle end-of-line
  fi
}
zle -N _kill-oneliner-param-forward
bindkey "^[j" _kill-oneliner-param-forward