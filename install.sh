#!/bin/bash
dotfile_dir="$HOME/.dotfiles"
CI="\e[32m"
CD="\e[m"

if test -d $dotfile_dir ; then
  echo Already installed
else
  echo -e $CI"Install dotfiles..."$CD
  git clone git@github.com:hisamekms/dotfiles.git $dotfile_dir
  cd $dotfile_dir
  sh ./setup.sh
fi
