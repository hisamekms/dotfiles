#!/usr/bin/env bash
# Hook: close-idle-workspace
# SENKO_AUTO時、実行可能なタスクがなければcmux workspaceを閉じる
set -euo pipefail

if [[ "${SENKO_AUTO:-}" == "true" ]] && [[ -n "${CMUX_WORKSPACE_ID:-}" ]]; then
  cmux close-workspace --workspace "$CMUX_WORKSPACE_ID"
fi
