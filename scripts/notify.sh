#!/usr/bin/env bash
# Post a deployment notification to Slack.
set -euo pipefail

# ORCA-DEMO: Secret (history) – FAKE Slack bot token. It is removed in the very next
# commit; Orca still detects it from git history with label
# shiftleft:secret_detection:only_in_history
SLACK_BOT_TOKEN="xoxb-578167102771-0842384935463-JYLIdjamOMWCcy07PUAjWMcZ"
CHANNEL="${SLACK_CHANNEL:-#orca-demo-deploys}"
MESSAGE="${1:-orca-appsec-demo deployed}"

curl -sS -X POST https://slack.com/api/chat.postMessage \
  -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
  -H "Content-Type: application/json; charset=utf-8" \
  --data "{\"channel\": \"${CHANNEL}\", \"text\": \"${MESSAGE}\"}"
