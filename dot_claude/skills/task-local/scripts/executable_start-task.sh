#!/usr/bin/env bash
# Mark a task as in_progress and set session_id/branch.
# Usage: ./scripts/start-task.sh <task_file> [--session-id <id>]

source "$(dirname "$0")/lib.sh"

set -euo pipefail

task_file="${1:-}"
[ -n "$task_file" ] || { echo "usage: $0 <task_file> [--session-id <id>]" >&2; exit 2; }
shift || true

session_id="${CLAUDE_SESSION_ID:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --session-id)
      shift
      [ $# -gt 0 ] || { echo "missing value for --session-id" >&2; exit 2; }
      session_id="$1"
      ;;
    *)
      echo "unknown option: $1" >&2
      exit 2
      ;;
  esac
  shift
done

[ -f "$task_file" ] || { echo "task file not found: $task_file" >&2; exit 2; }

id="$(parse_field "$task_file" "id")"
title="$(parse_field "$task_file" "title")"
[ -n "$id" ] || { echo "id is empty: $task_file" >&2; exit 2; }
[ -n "$title" ] || { echo "title is empty: $task_file" >&2; exit 2; }

branch="task/${id}-${title}"
started_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
update_field "$task_file" "status" "in_progress"
update_field "$task_file" "branch" "$branch"
update_field "$task_file" "session_id" "$session_id"
update_field "$task_file" "started_at" "$started_at"

echo "path=${task_file}"
echo "status=in_progress"
echo "branch=${branch}"
echo "session_id=${session_id}"
echo "started_at=${started_at}"
