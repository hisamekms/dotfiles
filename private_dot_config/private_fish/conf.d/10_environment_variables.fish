if not status is-interactive; or not test -t 1
  exit
end

set -U GHQ_SELECTOR peco
set -x EDITOR vim
set -x DCW_DOCKER_PATH podman
set -x DCW_DOCKER_COMPOSE_PATH "podman compose"
set -x DOCKER_HOST "unix:///tmp/podman.sock"