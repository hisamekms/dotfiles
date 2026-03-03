#!/usr/bin/env bash
set -euo pipefail

msg="${1:-}"

if [[ -z "${CLAUDE_SESSION_ID:-}" ]]; then
  echo "NG: CLAUDE_SESSION_ID is empty"
  exit 1
fi

echo "OK: bash script executed"
echo "CLAUDE_SESSION_ID=${CLAUDE_SESSION_ID}"
[[ -n "$msg" ]] && echo "message=$msg"
