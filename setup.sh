#!/bin/bash
set -e

CI="\e[32m"
CD="\e[m"

fish_config=~/.config/fish/config.fish

if command -v brew >/dev/null ; then
  :
else
  echo -e $CI"Install brew..."$CD
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

if command -v fish >/dev/null ; then
  :
else
  echo -e $CI"Install frew..."$CD
  brew install fish
  if grep -q /usr/local/bin/fish /etc/shells ; then
    :
  else
    echo -e $CI"Change default shell to fish"$CD
    echo '/usr/local/bin/fish' | sudo tee -a /etc/shells
    chsh -s /usr/local/bin/fish
  fi
fi

fish setup.fish

exit 0
