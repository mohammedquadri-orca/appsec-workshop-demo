#!/usr/bin/env bash
# Post a deployment notification to Slack.
set -euo pipefail

# Token now comes from the environment. The previously hardcoded (FAKE) token
# is still in git history – see DEMO.md "Secrets history".
: "${SLACK_BOT_TOKEN:?SLACK_BOT_TOKEN must be set}"
CHANNEL="${SLACK_CHANNEL:-#orca-demo-deploys}"
MESSAGE="${1:-orca-appsec-demo deployed}"

curl -sS -X POST https://slack.com/api/chat.postMessage \
  -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
  -H "Content-Type: application/json; charset=utf-8" \
  --data "{\"channel\": \"${CHANNEL}\", \"text\": \"${MESSAGE}\"}"
