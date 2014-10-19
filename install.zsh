#!/bin/zsh
ROOT_DIR=`pwd`
EXCLUDES=('.gitignore' '.git')

# Optional settings
for opt in $@; do
  case $opt in
    '-f'|'--force')
      force=1
      shift 1
      ;;
    -*)
      echo "$PROGNAME: illegal option -- '$(echo $1 | sed 's/^-*//')'" 1>&2
      exit 1
      ;;
  esac
done

# Install dotfiles
createdFiles=()
for dotfile in `find $ROOT_DIR -maxdepth 1 -name '.*'`; do
  filename=`basename ${dotfile}`
  if [[ ${EXCLUDES[(r)${filename}]} != ${filename} ]]; then
    if [ -e ~/${filename} ]; then
      if [ ! $force ]; then 
        while true; do
          read ans\?"${filename} already exists.Overwrite it? [Y/n]"
          case $ans in
            ''|[Yy]* )
              ln -s -f $dotfile ~/${filename}
              createdFiles=($createdFiles ${filename})
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
        ln -s -f $dotfile ~/${filename}
        createdFiles=($createdFiles ${filename})
      fi
    else
      ln -s -f $dotfile ~/${filename}
      createdFiles=($createdFiles ${filename})
    fi
  fi
done

if [ ${#CreatedFiles} != 0 ]; then
  echo $CreatedFiles 1>&2
fi
exit 0
