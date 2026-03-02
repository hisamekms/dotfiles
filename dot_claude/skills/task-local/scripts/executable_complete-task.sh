#!/usr/bin/env bash
# Mark a task as done and set completed_at (UTC ISO-8601).
# Usage: ./scripts/complete-task.sh <task_file>

source "$(dirname "$0")/lib.sh"

set -euo pipefail

task_file="${1:-}"
[ -n "$task_file" ] || { echo "usage: $0 <task_file>" >&2; exit 2; }
[ -f "$task_file" ] || { echo "task file not found: $task_file" >&2; exit 2; }

completed_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
update_field "$task_file" "status" "done"
update_field "$task_file" "completed_at" "$completed_at"

echo "path=${task_file}"
echo "status=done"
echo "completed_at=${completed_at}"
