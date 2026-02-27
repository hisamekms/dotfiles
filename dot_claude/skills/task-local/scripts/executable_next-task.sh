#!/usr/bin/env bash
# Find the next available task, claim it (set in_progress + session_id),
# and print its ID to stdout.
# Exit 1 if no task is available.
#
# Environment:
#   CLAUDE_SESSION_ID  - Session ID to set on the claimed task (optional)

source "$(dirname "$0")/lib.sh"

load_tasks

# Build candidate list: task file path and ID pairs
candidate_file=""
candidate_id=""

for file in "${task_files[@]}"; do
  id="$(parse_field "$file" "id")"
  status="$(parse_field "$file" "status")"

  if [ "$status" != "todo" ]; then
    continue
  fi

  if ! is_blocked "$file"; then
    # Keep track of the smallest ID
    if [ -z "$candidate_id" ] || [[ "$id" < "$candidate_id" ]]; then
      candidate_id="$id"
      candidate_file="$file"
    fi
  fi
done

if [ -z "$candidate_id" ]; then
  log "着手可能なタスクがありません"
  exit 1
fi

# Claim the task immediately
candidate_title="$(parse_field "$candidate_file" "title")"
branch="task/${candidate_id}-${candidate_title}"

update_field "$candidate_file" "status" "in_progress"
update_field "$candidate_file" "branch" "$branch"
if [ -n "${CLAUDE_SESSION_ID:-}" ]; then
  update_field "$candidate_file" "session_id" "$CLAUDE_SESSION_ID"
fi

log "タスク ${candidate_id} を in_progress に変更しました (branch: ${branch})"
echo "$candidate_id"
