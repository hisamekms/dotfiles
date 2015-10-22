#!/usr/bin/env bash
ROOT_DIR=${DOTFILES_BASE}
if [ -n "${ROOT_DIR}"]; then
  ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE:-${(%):-%N}}")"; pwd)"
fi
declare -a EXCLUDES=(".gitignore" ".git" ".gitkeep" ".DS_Store" ".gitmodules")

contains () {
  local e
  for e in "${@:2}"; do
    [[ "$e" == "$1" ]] && return 0;
  done
  return 1
}

# Optional settings
for opt in $@; do
  case $opt in
    '-f'|'--force')
      force=1
      shift 1
      ;;
    -*)
      echo "illegal option -- '$(echo $1 | sed 's/^-*//')'" 1>&2
      exit 1
      ;;
  esac
done

# Install dotfiles
echo ${ROOT_DIR}
symlinks=()
for dotfile in `find ${ROOT_DIR} -type d -name 'antigen' -prune -o -type f -name '.*' -print`; do
  filename=`basename ${dotfile}`
  echo $filename

  # skip if this file type is link.
  if [ -L ${dotfile} ]; then
    continue
  fi

  # skip if this file name is in EXCLUDES.
  contains ${filename} ${EXCLUDES[@]}
  if [ $? -eq 0 ]; then
    continue
  fi

  # Create symlinks.
  if [ -e ~/${filename} ]; then
    if [ ! $force ]; then
      while true; do
        read -p "${filename} already exists.Overwrite it? [Y/n]" answer;

        case $answer in
          ''|[Yy]* )
            ln -s -f $dotfile ~/${filename}
            symlinks=("$symlinks[@]" ${filename})
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
      symlinks=("${symlinks[@]}" ${filename})
    fi
  else
    ln -s -f $dotfile ~/${filename}
    symlinks=("${symlinks[@]}" ${filename})
  fi
done

exit 0
