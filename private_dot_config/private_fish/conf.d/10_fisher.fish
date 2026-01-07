if not functions -q fisher
    set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
    curl -sL https://git.io/fisher | source
    fisher install < $XDG_CONFIG_HOME/fish/fish_plugins
end