if not status is-interactive; or not test -t 1
  exit
end

zoxide init fish | source
