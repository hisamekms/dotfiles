#!/usr/bin/env bash
# List active tasks (todo, in_progress) with optional OR tag filters.
# Usage: ./scripts/list-active-tasks.sh [--tag <tag>]...

source "$(dirname "$0")/lib.sh"

set -euo pipefail

tag_filters=()
while [ $# -gt 0 ]; do
  case "$1" in
    --tag)
      shift
      [ $# -gt 0 ] || { echo "missing value for --tag" >&2; exit 2; }
      tag_filters+=("$1")
      ;;
    *)
      echo "unknown option: $1" >&2
      exit 2
      ;;
  esac
  shift
done

parse_tags() {
  local file="$1"
  awk '
    BEGIN { in_fm = 0 }
    /^---$/ {
      if (in_fm) exit
      in_fm = 1
      next
    }
    in_fm && /^tags:/ {
      val = $0
      sub("^tags:[[:space:]]*", "", val)
      gsub(/[\[\]]/, "", val)
      gsub(/"/, "", val)
      gsub(/'\''/, "", val)
      n = split(val, parts, ",")
      for (i = 1; i <= n; i++) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", parts[i])
        if (parts[i] != "") print parts[i]
      }
      exit
    }
  ' "$file"
}

task_body_excerpt() {
  local file="$1"
  awk '
    BEGIN { fm = 0; body = 0; printed = 0 }
    /^---$/ {
      fm++
      if (fm == 2) body = 1
      next
    }
    body {
      if ($0 ~ /^[[:space:]]*$/) next
      print
      printed++
      if (printed >= 3) exit
    }
  ' "$file"
}

load_tasks

rows=()
for file in "${task_files[@]}"; do
  id="$(parse_field "$file" "id")"
  title="$(parse_field "$file" "title")"
  status="$(parse_field "$file" "status")"

  if [ "$status" != "todo" ] && [ "$status" != "in_progress" ]; then
    continue
  fi

  tags=()
  while IFS= read -r tag; do
    [ -n "$tag" ] && tags+=("$tag")
  done < <(parse_tags "$file")

  if [ ${#tag_filters[@]} -gt 0 ]; then
    matched=1
    for filter in "${tag_filters[@]}"; do
      for tag in "${tags[@]}"; do
        if [ "$tag" = "$filter" ]; then
          matched=0
          break 2
        fi
      done
    done
    [ "$matched" -eq 0 ] || continue
  fi

  if [ ${#tags[@]} -eq 0 ]; then
    tag_csv="-"
  else
    tag_csv="$(IFS=,; echo "${tags[*]}")"
  fi

  excerpt="$(task_body_excerpt "$file" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/[[:space:]]+$//')"
  [ -z "$excerpt" ] && excerpt="-"
  rows+=("${id}|${status}|${title}|${tag_csv}|${excerpt}|${file}")
done

if [ ${#rows[@]} -eq 0 ]; then
  echo "タスクがありません"
  exit 1
fi

echo "| ID | Status | Title | Tags | Excerpt |"
echo "|---|---|---|---|---|"
for row in "${rows[@]}"; do
  IFS='|' read -r id status title tag_csv excerpt _ <<< "$row"
  echo "| ${id} | ${status} | ${title} | ${tag_csv} | ${excerpt} |"
done
