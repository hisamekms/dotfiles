#!/usr/bin/env bash
# Finalize task metadata by setting status=todo and depends_on/tags/priority values.
# Usage:
#   ./scripts/finalize-task-metadata.sh <task_file> [--depends <id>]... [--tag <tag>]... [--priority <p0|p1|p2|p3>]

set -euo pipefail

task_file="${1:-}"
[ -n "$task_file" ] || { echo "usage: $0 <task_file> [--depends <id>]... [--tag <tag>]... [--priority <p0|p1|p2|p3>]" >&2; exit 2; }
shift || true

[ -f "$task_file" ] || { echo "task file not found: $task_file" >&2; exit 2; }

depends=()
tags=()
priority="p2"
while [ $# -gt 0 ]; do
  case "$1" in
    --depends)
      shift
      [ $# -gt 0 ] || { echo "missing value for --depends" >&2; exit 2; }
      depends+=("$1")
      ;;
    --tag)
      shift
      [ $# -gt 0 ] || { echo "missing value for --tag" >&2; exit 2; }
      tags+=("$1")
      ;;
    --priority)
      shift
      [ $# -gt 0 ] || { echo "missing value for --priority" >&2; exit 2; }
      case "$1" in
        p0|p1|p2|p3)
          priority="$1"
          ;;
        *)
          echo "invalid value for --priority: $1 (expected p0|p1|p2|p3)" >&2
          exit 2
          ;;
      esac
      ;;
    *)
      echo "unknown option: $1" >&2
      exit 2
      ;;
  esac
  shift
done

join_yaml_array() {
  if [ $# -eq 0 ]; then
    printf '[]'
    return
  fi
  local out="["
  local first=1
  local v=""
  for v in "$@"; do
    if [ "$first" -eq 1 ]; then
      first=0
    else
      out+=", "
    fi
    out+="\"${v}\""
  done
  out+="]"
  printf '%s' "$out"
}

depends_yaml='[]'
if [ "${#depends[@]}" -gt 0 ]; then
  depends_yaml="$(join_yaml_array "${depends[@]}")"
fi

tags_yaml='[]'
if [ "${#tags[@]}" -gt 0 ]; then
  tags_yaml="$(join_yaml_array "${tags[@]}")"
fi

tmp="${task_file}.tmp"
awk -v depends="$depends_yaml" -v tags="$tags_yaml" -v priority="$priority" '
  BEGIN { in_fm = 0 }
  /^---$/ {
    print
    if (in_fm == 1) {
      in_fm = 0
    } else {
      in_fm = 1
    }
    next
  }
  in_fm && /^status:/ { print "status: todo"; next }
  in_fm && /^priority:/ { print "priority: " priority; next }
  in_fm && /^depends_on:/ { print "depends_on: " depends; next }
  in_fm && /^tags:/ { print "tags: " tags; next }
  in_fm && /^started_at:/ { print "started_at: "; next }
  in_fm && /^completed_at:/ { print "completed_at: "; next }
  { print }
' "$task_file" > "$tmp"
mv "$tmp" "$task_file"

echo "path=${task_file}"
echo "status=todo"
echo "priority=${priority}"
echo "depends_on=${depends_yaml}"
echo "tags=${tags_yaml}"
