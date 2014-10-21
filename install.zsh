#!/bin/zsh
ROOT_DIR=`pwd`
EXCLUDES=('.gitignore' '.git' '.gitkeep')

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
for dotfile in `find $ROOT_DIR -name '.*'`; do
  filename=`basename ${dotfile}`
  if [ -L ${dotfile} ]; then
    continue
  fi

  if [[ ${EXCLUDES[(r)${filename}]} == ${filename} ]]; then
    continue
  fi

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
done

if [ ${#createdFiles} != 0 ]; then
  echo $createdFiles 1>&2
fi
exit 0
