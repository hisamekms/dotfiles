#!/usr/bin/env bash
# Create a draft task file and print metadata to stdout.
# Usage: ./scripts/create-draft-task.sh "<description>"

set -euo pipefail

description="${*:-}"
if [ -z "$description" ]; then
  echo "usage: $0 <description>" >&2
  exit 2
fi

if project_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  :
else
  project_root="$(pwd)"
fi

tasks_dir="${project_root}/tasks.local"
mkdir -p "$tasks_dir"

max_id=0
for file in "$tasks_dir"/*.md; do
  [ -e "$file" ] || continue
  base="$(basename "$file")"
  if [[ "$base" =~ ^([0-9]{3})- ]]; then
    id_num=$((10#${BASH_REMATCH[1]}))
    if [ "$id_num" -gt "$max_id" ]; then
      max_id="$id_num"
    fi
  fi
done

new_id="$(printf '%03d' $((max_id + 1)))"
title="$(
  printf '%s' "$description" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g'
)"
[ -z "$title" ] && title="task-${new_id}"

task_file="${tasks_dir}/${new_id}-${title}.md"

cat > "$task_file" <<EOF
---
id: "${new_id}"
title: ${title}
status: draft
session_id:
branch:
depends_on: []
tags: []
started_at:
completed_at:
---

EOF

echo "id=${new_id}"
echo "title=${title}"
echo "path=${task_file}"
