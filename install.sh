#!/usr/bin/env bash

command_exists () {
    type "$1" &> /dev/null;
}

# Install commands.
if [[ "$OSTYPE" == "darwin"* ]]; then
  if ! command_exists xcode ; then
    sudo xcodebuild -license accept
  fi
  if ! command_exists brew ; then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
  if ! command_exists zsh ; then
    brew install zsh
    chsh -s /bin/zsh
  fi
fi
# TODO other OS case.

if [ ! -d ~/.antigen ]; then
  git clone https://github.com/zsh-users/antigen.git ~/.antigen
fi

# Install & bootstrap dotfiles.
DOTFILES_BASE = ${HOME}/.dotfiles
if [ ! -d ${DOTFILES_BASE} ]; then
  git clone --depth 1 https://github.com/hisamekms/dotfiles.git ${DOTFILES_BASE}
fi
${DOTFILES_BASE}/bootstrap.sh
