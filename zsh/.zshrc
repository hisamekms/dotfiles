#DOTFILES_BASE=${HOME}/.dotfiles
DOTFILES_BASE=${HOME}/.ghq/github.com/hisamekms/dotfiles
ANTIGEN_BASE=${HOME}/.antigen

# ------------------------------
# Antigen Settings
# ------------------------------
source ${ANTIGEN_BASE}/antigen.zsh

antigen use oh-my-zsh
antigen bundle git
antigen bundle osx
antigen bundle brew
antigen bundle brew-cask
antigen bundle cp

antigen bundle zsh-users/zsh-syntax-highlighting

# antigen theme dogrocker/oh-my-zsh-powerline-cute-theme cute-theme
antigen theme caiogondim/bullet-train-oh-my-zsh-theme bullet-train

BULLETTRAIN_TIME_SHOW=false
BULLETTRAIN_CONTEXT_SHOW=true
BULLETTRAIN_RUBY_SHOW=false

POWERLINE_HIDE_HOST_NAME="true"
POWERLINE_HIDE_GIT_PROMPT_STATUS="true"
POWERLINE_SHOW_GIT_ON_RIGHT="true"

antigen apply

# ------------------------------
# Install My Plugins
# ------------------------------
if [ -d ${DOTFILES_BASE}/zsh ]; then
  for plugin in `find ${DOTFILES_BASE}/zsh/plugins -name '*.zsh' -type f`; do
    echo "Loading plugin: ${plugin##*/}"
    source "$plugin"
  done

  for plugin in `find ${DOTFILES_BASE}/zsh/local -name '*.zsh' -type f`; do
    echo "Loading plugin: ${plugin##*/}"
    source "$plugin"
  done
fi

# ------------------------------
# General Settings
# ------------------------------
# bindkey -v              # キーバインドをviモードに設定

setopt auto_pushd        # cd時にディレクトリスタックにpushdする
#setopt correct           # コマンドのスペルを訂正する
setopt prompt_subst      # プロンプト定義内で変数置換やコマンド置換を扱う
setopt notify            # バックグラウンドジョブの状態変化を即時報告する
#setopt equals            # =commandを`which command`と同じ処理にする
setopt AUTO_CD

### Complement ###
autoload -U compinit; compinit # 補完機能を有効にする
setopt auto_list               # 補完候補を一覧で表示する(d)
setopt auto_menu               # 補完キー連打で補完候補を順に表示する(d)
setopt list_packed             # 補完候補をできるだけ詰めて表示する
setopt list_types              # 補完候補にファイルの種類も表示する
bindkey "^[[Z" reverse-menu-complete  # Shift-Tabで補完候補を逆順する("\e[Z"でも動作する)
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # 補完時に大文字小文字を区別しない

### History ###
export HISTFILE=~/.zsh_history   # ヒストリを保存するファイル
export HISTSIZE=10000            # メモリに保存されるヒストリの件数
export SAVEHIST=10000            # 保存されるヒストリの件数
setopt bang_hist          # !を使ったヒストリ展開を行う(d)
setopt extended_history   # ヒストリに実行時間も保存する
setopt hist_ignore_dups   # 直前と同じコマンドはヒストリに追加しない
setopt share_history      # 他のシェルのヒストリをリアルタイムで共有する
setopt hist_reduce_blanks # 余分なスペースを削除してヒストリに保存する

# マッチしたコマンドのヒストリを表示できるようにする
# autoload history-search-end
# zle -N history-beginning-search-backward-end history-search-end
# zle -N history-beginning-search-forward-end history-search-end
# bindkey "^P" history-beginning-search-backward-end
# bindkey "^N" history-beginning-search-forward-end
#
# すべてのヒストリを表示する
function history-all { history -E 1 }

# ------------------------------
# Other Settings
# ------------------------------

# cdコマンド実行後、lsを実行する
chpwd() ls

# Compile SSH Config
build_ssh_config() {
  local SSH_CONF_HOME=${DOTFILES_BASE}/ssh/conf.d
  if [ -d ${SSH_CONF_HOME} ]; then
    rm ${HOME}/.ssh/config
    for sshConf in `find ${SSH_CONF_HOME} -type f`; do
      cat $sshConf >> ~/.ssh/config
      echo '' >> ~/.ssh/config
    done
    chmod 600 ~/.ssh/config
  fi
}

reload_dotfiles() {
  ${DOTFILES_BASE}/bootstrap.sh
}
