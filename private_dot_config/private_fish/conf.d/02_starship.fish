if not status is-interactive; or not test -t 1
  exit
end

starship init fish | source
