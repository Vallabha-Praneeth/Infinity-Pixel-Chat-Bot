#!/usr/bin/env bash

# Create ticket test
# Usage:
#   N8N_WEBHOOK_BASE=https://your-n8n \
#   N8N_TICKET_WEBHOOK_PATH=/webhook/ticket \
#   ./test_create.sh

set -euo pipefail

WEBHOOK_BASE="${N8N_WEBHOOK_BASE:-}"
WEBHOOK_PATH="${N8N_TICKET_WEBHOOK_PATH:-}"
AUTH_HEADER="${AUTH_HEADER:-}"

if [[ -z "$WEBHOOK_BASE" || -z "$WEBHOOK_PATH" ]]; then
  echo "Missing N8N_WEBHOOK_BASE or N8N_TICKET_WEBHOOK_PATH" >&2
  exit 1
fi

call_webhook() {
  local payload="$1"
  local headers=("-H" "Content-Type: application/json")
  [[ -n "$AUTH_HEADER" ]] && headers+=("-H" "$AUTH_HEADER")
  curl -sS -X POST "${WEBHOOK_BASE}${WEBHOOK_PATH}" "${headers[@]}" -d "$payload"
}

payload='{
  "action":"create",
  "name":"Sample User",
  "email":"sample@example.com",
  "channel":"chat",
  "subject":"Sample ticket created from template",
  "description":"This is a sample description of the user'\''s issue.",
  "priority":"medium",
  "additionalContext":"Sample internal notes field."
}'

resp=$(call_webhook "$payload")
echo "Response: $resp"

ticketId=""
if echo "$resp" | jq -e '.ticketId' >/dev/null 2>&1; then
  ticketId=$(echo "$resp" | jq -r '.ticketId')
else
  ticketId=$(echo "$resp" | jq -r '.messageForUser' | grep -o 'TCK-[A-Za-z0-9-]*' | head -n1)
fi

if [[ -z "$ticketId" ]]; then
  echo "❌ Could not extract ticketId" >&2
  exit 1
fi

echo "✅ ticket created: $ticketId"
echo "$ticketId"
