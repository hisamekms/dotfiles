#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook dispatcher for Bash tool.
# Detects `gh pr create` and triggers Codex review on the newly created PR.

REVIEW_SCRIPT="$HOME/.claude/skills/review-pr/scripts/codex-review-pr.sh"

# --- Read stdin JSON ---
input="$(cat)"

# --- Check if this is a `gh pr create` command ---
command="$(echo "$input" | jq -r '.tool_input.command // empty')"
[[ "$command" == *"gh pr create"* ]] || exit 0

# --- Check exit code ---
exit_code="$(echo "$input" | jq -r '.tool_response.exit_code // empty')"
[[ "$exit_code" == "0" ]] || exit 0

# --- Get cwd and resolve PR number ---
cwd="$(echo "$input" | jq -r '.cwd // empty')"
[[ -n "$cwd" ]] || exit 0

pr_number="$(cd "$cwd" && gh pr view --json number -q '.number' 2>/dev/null)" || exit 0
[[ -n "$pr_number" ]] || exit 0

# --- Run review in background ---
(cd "$cwd" && "$REVIEW_SCRIPT" "$pr_number") &

exit 0
