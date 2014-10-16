#!/bin/zsh
RootDir=~/dotfiles

# Optional settings
for opt in $@; do
  case $opt in
    '-f'|'--force')
      Force=1
      shift 1
      ;;
    -*)
      echo "$PROGNAME: illegal option -- '$(echo $1 | sed 's/^-*//')'" 1>&2
      exit 1
      ;;
  esac
done

if [ ! -e $RootDir ]; then
  echo '~/dotfiles does not exist.' 1>&2
  exit 1
fi

CreatedFiles=()
for dotfile in `find $RootDir -name '.*' -type file`; do
  if [ $dotfile != '.gitignore' ]; then
    Sl=~/`basename $dotfile`
    # if [ ls ~/.zshrc | wc = 1 ]; then
    #   echo already exists
    # fi
    if [ -e $Sl ]; then
      if [ ! $Force ]; then 
        # echo "$Sl already exists!" 1>&2
        # exit 1
        while true; do
          read Ans\?"`basename $dotfile` already exists.Overwrite it? [Y/n]"
          case $Ans in
            [Yy]* )
              ln -s -f $dotfile $Sl
              CreatedFiles=($CreatedFiles `basename $dotfile`)
              break;
              ;;
            [Nn]* )
              break;
              ;;
            * )
              echo 'Please answer yes or no.'
              ;;
          esac
        done
      else
        ln -s -f $dotfile $Sl
        CreatedFiles=($CreatedFiles `basename $dotfile`)
      fi
    else
      ln -s -f $dotfile $Sl
      CreatedFiles=($CreatedFiles `basename $dotfile`)
    fi
  fi
done

if [ $#CreatedFiles != 0 ]; then
  echo $CreatedFiles 1>&2
fi
exit 0
