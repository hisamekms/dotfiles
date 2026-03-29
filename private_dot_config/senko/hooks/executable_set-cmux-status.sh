#!/usr/bin/env bash
# Hook: set-cmux-status
# タスク開始時にcmuxのworkspace名とlabelを設定する
set -euo pipefail

INPUT=$(cat -)
TASK_ID=$(echo "$INPUT" | jq -r '.task.id')
TASK_TITLE=$(echo "$INPUT" | jq -r '.task.title')

PROJECT_NAME="${SENKO_PROJECT_NAME:-}"
if [[ -z "$PROJECT_NAME" ]]; then
  echo "ERROR: SENKO_PROJECT_NAME is not set" >&2
  exit 1
fi

WS_ID="${CMUX_WORKSPACE_ID:-}"
if [[ -z "$WS_ID" ]]; then
  echo "ERROR: CMUX_WORKSPACE_ID is not set" >&2
  exit 1
fi

# cmux workspace名を <project_name>#<task_id> に変更
cmux rename-workspace --workspace "$WS_ID" "${PROJECT_NAME}#${TASK_ID}"

# cmux labelを設定
cmux set-status label "${TASK_TITLE}" --icon hammer --color "#f59e0b" >/dev/null 2>&1
