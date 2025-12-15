#!/usr/bin/env bash

# End-to-end scenario smoke tests for the ticket manager chatbot workflows.
# Requirements:
# - curl, jq
# - Set N8N_WEBHOOK_BASE (e.g., https://your-n8n/webhook) and N8N_TICKET_WEBHOOK_PATH
#   (e.g., /call-ticket-manager) to point at the workflow trigger that fronts the Ticket Manager.
# - Optionally set AUTH_HEADER (e.g., "Authorization: Bearer XXX") if your n8n instance requires it.

set -euo pipefail

WEBHOOK_BASE="${N8N_WEBHOOK_BASE:-}"
WEBHOOK_PATH="${N8N_TICKET_WEBHOOK_PATH:-}"
AUTH_HEADER="${AUTH_HEADER:-}"

if [[ -z "$WEBHOOK_BASE" || -z "$WEBHOOK_PATH" ]]; then
  echo "Missing N8N_WEBHOOK_BASE or N8N_TICKET_WEBHOOK_PATH env vars." >&2
  exit 1
fi

call_webhook() {
  local payload="$1"
  local headers=("-H" "Content-Type: application/json")
  [[ -n "$AUTH_HEADER" ]] && headers+=("-H" "$AUTH_HEADER")
  curl -sS -X POST "${WEBHOOK_BASE}${WEBHOOK_PATH}" "${headers[@]}" -d "$payload"
}

assert_contains() {
  local json="$1" field="$2"
  if ! echo "$json" | jq -e ".$field" >/dev/null 2>&1; then
    echo "❌ Missing field '$field' in response: $json" >&2
    exit 1
  fi
}

assert_equals() {
  local json="$1" field="$2" expected="$3"
  local val
  val=$(echo "$json" | jq -r ".$field // empty")
  if [[ "$val" != "$expected" ]]; then
    echo "❌ Expected $field=$expected but got '$val'. Response: $json" >&2
    exit 1
  fi
}

run_create() {
  echo "▶️ create" >&2
  local payload='{
    "action":"create",
    "name":"Jane Doe",
    "email":"praneethvallabha@gmail.com",
    "subject":"Login broken",
    "description":"Cannot login after password reset",
    "priority":"high"
  }'
  resp=$(call_webhook "$payload")
  # ticketId may be in messageForUser; extract if missing
  if echo "$resp" | jq -e '.ticketId' >/dev/null 2>&1; then
    ticketId=$(echo "$resp" | jq -r '.ticketId')
  else
    ticketId=$(echo "$resp" | jq -r '.messageForUser' | grep -o 'TCK-[A-Za-z0-9-]*' | head -n1)
  fi
  if [[ -z "$ticketId" ]]; then
    echo "❌ Could not extract ticketId from response: $resp" >&2
    exit 1
  fi
  assert_equals "$resp" "status" "open"
  echo "✅ create ok -> $ticketId" >&2
  echo "$ticketId"
}

run_status() {
  local ticketId="$1"
  echo "▶️ status"
  local payload=$(jq -nc --arg t "$ticketId" '{action:"status", ticketId:$t}')
  resp=$(call_webhook "$payload")
  assert_equals "$resp" "ticketId" "$ticketId"
  assert_contains "$resp" "status"
  echo "✅ status ok"
}

run_update() {
  local ticketId="$1"
  echo "▶️ update"
  local payload=$(jq -nc --arg t "$ticketId" '{action:"update", ticketId:$t, description:"Adding more details"}')
  resp=$(call_webhook "$payload")
  assert_equals "$resp" "ticketId" "$ticketId"
  echo "✅ update ok"
}

run_update_no_text() {
  local ticketId="$1"
  echo "▶️ update (missing text should block)"
  local payload=$(jq -nc --arg t "$ticketId" '{action:"update", ticketId:$t, description:""}')
  resp=$(call_webhook "$payload")
  msg=$(echo "$resp" | jq -r '.messageForUser // empty')
  if [[ "$msg" != "Please provide the update details so I can add them to your ticket." ]]; then
    echo "❌ Expected missing-text block, got: $resp" >&2
    exit 1
  fi
  echo "✅ update without text blocked"
}

run_close() {
  local ticketId="$1"
  echo "▶️ close"
  local payload=$(jq -nc --arg t "$ticketId" '{action:"close", ticketId:$t}')
  resp=$(call_webhook "$payload")
  assert_equals "$resp" "ticketId" "$ticketId"
  assert_equals "$resp" "status" "closed"
  echo "✅ close ok"
}

run_closed_update_block() {
  local ticketId="$1"
  echo "▶️ update after closed (should block)"
  local payload=$(jq -nc --arg t "$ticketId" '{action:"update", ticketId:$t, description:"try update"}')
  resp=$(call_webhook "$payload")
  msg=$(echo "$resp" | jq -r '.messageForUser // empty')
  if [[ "$msg" != "Ticket $ticketId is closed and cannot be updated. Please open a new ticket or ask to reopen." && "$msg" != "Ticket $ticketId is resolved and cannot be updated. Please open a new ticket or ask to reopen." ]]; then
    echo "❌ Expected closed/resolved block, got: $resp" >&2
    exit 1
  fi
  echo "✅ closed update blocked"
}

main() {
  ticketId=$(run_create)
  run_status "$ticketId"
  run_update "$ticketId"
  run_update_no_text "$ticketId"
  run_close "$ticketId"
  run_closed_update_block "$ticketId"
  echo "🎉 All tests passed"
}

main "$@"
