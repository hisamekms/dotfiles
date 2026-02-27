#!/usr/bin/env bash
# List all tasks as a Markdown table to stdout.
# Exit 1 if no tasks exist.

source "$(dirname "$0")/lib.sh"

load_tasks

# Collect task data into parallel arrays for formatting
ids=()
titles=()
statuses=()
deps_strs=()
blocked_strs=()

for file in "${task_files[@]}"; do
  id="$(parse_field "$file" "id")"
  title="$(parse_field "$file" "title")"
  status="$(parse_field "$file" "status")"

  # Build depends_on display string
  deps=()
  while IFS= read -r dep_id; do
    [ -z "$dep_id" ] && continue
    deps+=("$dep_id")
  done < <(parse_depends_on "$file")

  if [ ${#deps[@]} -eq 0 ]; then
    deps_str="-"
    blocked_str="-"
  else
    deps_str="$(IFS=,; echo "${deps[*]}")"
    if is_blocked "$file"; then
      blocked_str="yes"
    else
      blocked_str="-"
    fi
  fi

  ids+=("$id")
  titles+=("$title")
  statuses+=("$status")
  deps_strs+=("$deps_str")
  blocked_strs+=("$blocked_str")
done

# Calculate column widths
id_w=2      # "ID"
title_w=5   # "Title"
status_w=6  # "Status"
deps_w=10   # "Depends On"
blocked_w=7 # "Blocked"

for i in "${!ids[@]}"; do
  (( ${#ids[$i]} > id_w )) && id_w=${#ids[$i]}
  (( ${#titles[$i]} > title_w )) && title_w=${#titles[$i]}
  (( ${#statuses[$i]} > status_w )) && status_w=${#statuses[$i]}
  (( ${#deps_strs[$i]} > deps_w )) && deps_w=${#deps_strs[$i]}
  (( ${#blocked_strs[$i]} > blocked_w )) && blocked_w=${#blocked_strs[$i]}
done

# Print table
fmt="| %-${id_w}s | %-${title_w}s | %-${status_w}s | %-${deps_w}s | %-${blocked_w}s |"
sep="|-$(printf '%0.s-' $(seq 1 "$id_w"))-|-$(printf '%0.s-' $(seq 1 "$title_w"))-|-$(printf '%0.s-' $(seq 1 "$status_w"))-|-$(printf '%0.s-' $(seq 1 "$deps_w"))-|-$(printf '%0.s-' $(seq 1 "$blocked_w"))-|"

# shellcheck disable=SC2059
printf "$fmt\n" "ID" "Title" "Status" "Depends On" "Blocked"
echo "$sep"
for i in "${!ids[@]}"; do
  # shellcheck disable=SC2059
  printf "$fmt\n" "${ids[$i]}" "${titles[$i]}" "${statuses[$i]}" "${deps_strs[$i]}" "${blocked_strs[$i]}"
done
