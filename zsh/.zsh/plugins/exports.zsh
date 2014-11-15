export BREWFILE=~/.brewfile
export EDITOR=vim
export LANG=ja_JP.UTF-8
export KCODE=u
# export AUTOFEATURE=true  # autotestでfeatureを動かす

export PATH=/usr/local/bin:$PATH

if [ -e ~/.anyenv ]; then
  export PATH="$HOME/.anyenv/bin:$PATH"
  eval "$(anyenv init -)"
else
  function install-anyenv () {
    git clone https://github.com/riywo/anyenv ~/.anyenv
  }
fi
# export PATH=$HOME/.nodebrew/current/bin:$PATH
export PATH=$PATH:~/go/bin

export GOPATH=~/go

export ANDROID_HOME=/usr/local/opt/android-sdk

