


for dotfile in .*
do
  if [[ $dotfile != '.' && $dotfile != '..' && $dotfile != '.git' ]] ; then
    ln -s -f ~/dotfiles/$dotfile ~/$dotfile
  fi
done
