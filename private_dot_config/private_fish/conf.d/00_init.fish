fish_add_path ~/.local/bin
fish_add_path ~/.anyenv/bin

if command -v anyenv >/dev/null
end
  eval (anyenv init - fish | source)

if command -v direnv >/dev/null
  eval (direnv hook fish)
end

if test -x /opt/homebrew/bin/brew
  /opt/homebrew/bin/brew shellenv | source
end

mise activate fish | source