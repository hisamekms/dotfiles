#!/usr/bin/env bash
set -euo pipefail

: "${SLACK_NOTIFICATION_WEBHOOK_URL:?SLACK_NOTIFICATION_WEBHOOK_URL is not set}"
: "${SLACK_NOTIFICATION_PROJECT:?SLACK_NOTIFICATION_PROJECT is not set}"

json=$(cat)

hook_event_name=$(echo "$json" | jq -r '.hook_event_name // ""')
notification_type=$(echo "$json" | jq -r '.notification_type // ""')
title=$(echo "$json" | jq -r '.title // ""')
message=$(echo "$json" | jq -r '.message // ""')

text="[${SLACK_NOTIFICATION_PROJECT}]
event: ${hook_event_name}
notification_type: ${notification_type}

${title}
${message}"

payload=$(jq -n --arg text "$text" '{text: $text}')

curl -s -X POST -H 'Content-Type: application/json' -d "$payload" "$SLACK_NOTIFICATION_WEBHOOK_URL" > /dev/null
