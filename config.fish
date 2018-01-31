set PATH ~/.anyenv/bin $PATH
eval (anyenv init - | source)
set PATH ~/go/bin $PATH
set -U GHQ_SELECTOR peco

function fish_user_key_bindings
  # unbind fish-ghq key bindings
  bind -e \cg
  bind \cr '__ghq_crtl_g'
end
