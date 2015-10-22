export PATH=/usr/local/bin:$PATH

if [ -e ~/.anyenv ]; then
  export PATH="$HOME/.anyenv/bin:$PATH"
  eval "$(anyenv init -)"
else
  function install-anyenv () {
    git clone https://github.com/riywo/anyenv ~/.anyenv
  }
fi

export PATH=$PATH:~/go/bin
