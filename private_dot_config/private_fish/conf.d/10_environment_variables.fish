if not status is-interactive; or not test -t 1
  exit
end

set -U GHQ_SELECTOR peco
set -x EDITOR vim