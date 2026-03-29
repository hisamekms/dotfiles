#!/usr/bin/env bash
# Hook: clear-cmux-status
# タスク完了/キャンセル時にcmuxのlabelを削除し、workspace名をidle状態にする
set -euo pipefail

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

# cmux labelを削除
cmux set-status label "" >/dev/null 2>&1

# cmux workspace名を <project_name>#idle-<timestamp> に変更
cmux rename-workspace --workspace "$WS_ID" "${PROJECT_NAME}#idle-$(date +%Y%m%d%H%M%S)"
