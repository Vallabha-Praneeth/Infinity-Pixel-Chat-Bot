#!/usr/bin/env bash

# Status check test
# Usage:
#   export N8N_WEBHOOK_BASE=...
#   export N8N_TICKET_WEBHOOK_PATH=...
#   ./test_status.sh <ticketId>

set -euo pipefail

WEBHOOK_BASE="${N8N_WEBHOOK_BASE:-}"
WEBHOOK_PATH="${N8N_TICKET_WEBHOOK_PATH:-}"
AUTH_HEADER="${AUTH_HEADER:-}"

if [[ -z "$WEBHOOK_BASE" || -z "$WEBHOOK_PATH" ]]; then
  echo "Missing N8N_WEBHOOK_BASE or N8N_TICKET_WEBHOOK_PATH" >&2
  exit 1
fi

ticketId="${1:-}"
if [[ -z "$ticketId" ]]; then
  echo "Usage: ./test_status.sh <ticketId>" >&2
  exit 1
fi

call_webhook() {
  local payload="$1"
  local headers=("-H" "Content-Type: application/json")
  [[ -n "$AUTH_HEADER" ]] && headers+=("-H" "$AUTH_HEADER")
  curl -sS -X POST "${WEBHOOK_BASE}${WEBHOOK_PATH}" "${headers[@]}" -d "$payload"
}

payload=$(jq -nc --arg t "$ticketId" '{action:"status", ticketId:$t}')
resp=$(call_webhook "$payload")
echo "Response: $resp"

if echo "$resp" | jq -e '.action' >/dev/null 2>&1; then
  act=$(echo "$resp" | jq -r '.action')
else
  act=""
fi

if [[ "$act" != "status" && "$act" != "create" ]]; then
  echo "❌ Unexpected action in response: $act" >&2
  exit 1
fi

echo "✅ status call completed"
