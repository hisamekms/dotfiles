#!/usr/bin/env bash
# Hook: relay-claude-workspace
# 新しいcmux workspaceでclaude /senko を起動し、SENKO_AUTO時は自分のworkspaceを閉じる
set -euo pipefail

if [[ -z "${SENKO_HOST_PROJECT_DIR:-}" ]]; then
  echo "ERROR: SENKO_HOST_PROJECT_DIR is not set" >&2
  exit 1
fi

# cmux で新しいworkspaceを作成
ws_name="senko-$(date +%Y%m%d%H%M%S)"
result=$(cmux new-workspace --cwd "$SENKO_HOST_PROJECT_DIR" --command "dcw exec fish")
ws_ref=$(echo "$result" | awk '{print $2}')
cmux rename-workspace --workspace "$ws_ref" "$ws_name"

# fish シェルが起動するまで少し待つ
sleep 2

# claude を起動して /senko を実行
cmux send --workspace "$ws_ref" "SENKO_AUTO=true claude --dangerously-skip-permissions /senko\n"

# SENKO_AUTO の場合、自分のworkspaceを閉じる
if [[ "${SENKO_AUTO:-}" == "true" ]] && [[ -n "${CMUX_WORKSPACE_ID:-}" ]]; then
  cmux close-workspace --workspace "$CMUX_WORKSPACE_ID"
fi
