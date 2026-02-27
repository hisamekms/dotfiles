#!/usr/bin/env bash
# Shared library for task-local scripts
# Usage: source "$(dirname "$0")/lib.sh"

set -euo pipefail

log() {
  printf '[task-local] %s\n' "$*" >&2
}

on_error() {
  local exit_code=$?
  log "FAILED (exit=${exit_code}) at line ${BASH_LINENO[0]}: ${BASH_COMMAND}"
  exit "$exit_code"
}

trap on_error ERR

# Locate tasks.local/ directory from current directory or git root
find_tasks_dir() {
  if [ -d "tasks.local" ]; then
    echo "tasks.local"
    return
  fi

  local git_root
  if git_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    if [ -d "${git_root}/tasks.local" ]; then
      echo "${git_root}/tasks.local"
      return
    fi
  fi

  log "tasks.local/ ディレクトリが見つかりません"
  exit 1
}

# Parse frontmatter field from a file
# Usage: parse_field <file> <field_name>
parse_field() {
  local file="$1"
  local field="$2"
  awk -v field="$field" '
    BEGIN { in_fm = 0 }
    /^---$/ {
      if (in_fm) exit
      in_fm = 1
      next
    }
    in_fm && $0 ~ "^" field ":" {
      val = $0
      sub("^" field ":[[:space:]]*", "", val)
      # Strip surrounding quotes
      gsub(/^["'\'']|["'\'']$/, "", val)
      print val
      exit
    }
  ' "$file"
}

# Parse depends_on array from a file
# Returns one dependency ID per line
parse_depends_on() {
  local file="$1"
  awk '
    BEGIN { in_fm = 0 }
    /^---$/ {
      if (in_fm) exit
      in_fm = 1
      next
    }
    in_fm && /^depends_on:/ {
      val = $0
      sub("^depends_on:[[:space:]]*", "", val)
      # Remove brackets
      gsub(/[\[\]]/, "", val)
      # Remove quotes
      gsub(/"/, "", val)
      gsub(/'\''/, "", val)
      # Split by comma and print each trimmed value
      n = split(val, parts, ",")
      for (i = 1; i <= n; i++) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", parts[i])
        if (parts[i] != "") print parts[i]
      }
      exit
    }
  ' "$file"
}

# Load all task files and populate TASK_STATUS associative array
# Sets: TASKS_DIR, task_files[], TASK_STATUS[]
load_tasks() {
  TASKS_DIR="$(find_tasks_dir)"

  task_files=()
  while IFS= read -r -d '' file; do
    task_files+=("$file")
  done < <(find "$TASKS_DIR" -maxdepth 1 -name '*.md' -print0 | sort -z)

  if [ ${#task_files[@]} -eq 0 ]; then
    log "タスクファイルが見つかりません"
    exit 1
  fi

  declare -g -A TASK_STATUS
  for file in "${task_files[@]}"; do
    id="$(parse_field "$file" "id")"
    status="$(parse_field "$file" "status")"
    if [ -n "$id" ] && [ -n "$status" ]; then
      TASK_STATUS["$id"]="$status"
    fi
  done
}

# Update a frontmatter field in a task file
# Usage: update_field <file> <field_name> <new_value>
update_field() {
  local file="$1"
  local field="$2"
  local value="$3"
  local tmp="${file}.tmp"

  awk -v field="$field" -v value="$value" '
    BEGIN { in_fm = 0; replaced = 0 }
    /^---$/ {
      if (in_fm) { in_fm = 0 }
      else { in_fm = 1 }
      print
      next
    }
    in_fm && $0 ~ "^" field ":" {
      print field ": " value
      replaced = 1
      next
    }
    { print }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

# Check if a task is blocked by unfinished dependencies
# Usage: is_blocked <file>
# Returns: 0 if blocked, 1 if not blocked
is_blocked() {
  local file="$1"
  while IFS= read -r dep_id; do
    [ -z "$dep_id" ] && continue
    local dep_status="${TASK_STATUS[$dep_id]:-}"
    if [ "$dep_status" != "done" ]; then
      return 0
    fi
  done < <(parse_depends_on "$file")
  return 1
}
