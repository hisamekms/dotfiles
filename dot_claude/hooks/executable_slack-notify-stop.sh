#!/usr/bin/env bash
set -euo pipefail

: "${SLACK_NOTIFICATION_WEBHOOK_URL:?SLACK_NOTIFICATION_WEBHOOK_URL is not set}"
: "${SLACK_NOTIFICATION_PROJECT:?SLACK_NOTIFICATION_PROJECT is not set}"

json=$(cat)

hook_event_name=$(echo "$json" | jq -r '.hook_event_name // ""')

text="[${SLACK_NOTIFICATION_PROJECT}]
event: ${hook_event_name}

停止しました"

payload=$(jq -n --arg text "$text" '{text: $text}')

curl -s -X POST -H 'Content-Type: application/json' -d "$payload" "$SLACK_NOTIFICATION_WEBHOOK_URL" > /dev/null
