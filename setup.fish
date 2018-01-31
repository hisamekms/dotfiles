#!/usr/local/bin/fish
set fish_config ~/.config/fish/config.fish
set fishfile ~/.config/fish/fishfile
set CI "\e[32m"
set CD "\e[m"

brew bundle

if test -L $fish_config
else
  echo -e $CI"Create config.fish symlink..."$CD
  if test -f $fish_config
    rm $fish_config
  end
  ln -s (pwd)/config.fish $fish_config
  source $fish_config
end

if test -L $fishfile
else
  echo -e $CI"Create fishfile symlink..."$CD
  if test -f $fishfile
    rm $fishfile
  end
  ln -s (pwd)/fishfile $fishfile
end

if command -v anyenv >/dev/null
else
  echo -e $CI"Install anyenv..."$CD
  git clone https://github.com/riywo/anyenv ~/.anyenv
  source $fish_config
end

if command -v goenv >/dev/null
else
  echo -e $CI"Install goenv..."$CD
  anyenv install goenv
  source $fish_config
end

if command -v go >/dev/null
else
  echo -e $CI"Install go..."$CD
  goenv install 1.9.2
  goenv global 1.9.2
  goenv rehash
  if grep -q 'set PATH ~/go/bin $PATH' $fish_config
  else
    echo 'set PATH ~/go/bin $PATH' >> $fish_config
  end
end

if command -v nodenv >/dev/null
else
  echo -e $CI"Install nodenv..."$CD
  anyenv install nodenv
  source $fish_config
end

if command -v node >/dev/null
else
  echo -e $CI"Install node..."$CD
  nodenv install 9.4.0
  nodenv global 9.4.0
  nodenv rehash
end

if command -v ghq >/dev/null
else
  echo -e $CI"Install ghq..."$CD
  go get github.com/motemen/ghq
end
