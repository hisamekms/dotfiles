if not status is-interactive; or not test -t 1
  exit
end

# Git
abbr -a g 'git'
abbr -a ga 'git add'
abbr -a gaa 'git add -A'
abbr -a gcm 'git commit -m'
abbr -a gst 'git status'
abbr -a gpl 'git pull'
abbr -a gps 'git push'
abbr -a gplr 'git pull --rebase'
abbr -a gpr 'git push --rebase'
abbr -a gplr 'git pull --rebase'

# exa
abbr -a ls 'eza -lah --git'

# Bat
abbr -a cat 'bat'

# Others
abbr -a m 'mise'
abbr -a mr 'mise run'
abbr -a che 'chezmoi'

