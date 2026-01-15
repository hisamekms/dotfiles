set PATH ~/.anyenv/bin $PATH

if command -v anyenv >/dev/null
  eval (anyenv init - fish | source)
end

if command -v direnv >/dev/null
  eval (direnv hook fish)
end

if test -x /opt/homebrew/bin/brew
  /opt/homebrew/bin/brew shellenv | source
end

mise activate fish | source
