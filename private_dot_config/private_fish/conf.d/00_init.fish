fish_add_path ~/.local/bin

if test -x /opt/homebrew/bin/brew
  /opt/homebrew/bin/brew shellenv | source
end

mise activate fish | source

if command -v direnv >/dev/null
  direnv hook fish | source
end
