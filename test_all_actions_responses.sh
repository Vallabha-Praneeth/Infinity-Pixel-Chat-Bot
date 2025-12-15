#!/usr/bin/env bash

# Test All Actions Response Validation
# Purpose: Verify all actions return proper HTTP responses

set -euo pipefail

WEBHOOK_BASE="${N8N_WEBHOOK_BASE:-}"
WEBHOOK_PATH="${N8N_TICKET_WEBHOOK_PATH:-}"

if [[ -z "$WEBHOOK_BASE" || -z "$WEBHOOK_PATH" ]]; then
  echo "❌ Error: Missing environment variables" >&2
  exit 1
fi

echo "============================================"
echo "  All Actions Response Validation Test"
echo "============================================"
echo ""

PASS_COUNT=0
FAIL_COUNT=0

test_action_response() {
  local action=$1
  local payload=$2
  local action_name=$3

  echo "-------------------------------------------"
  echo "Testing: $action_name"
  echo "-------------------------------------------"
  echo "Payload: $payload"
  echo ""

  response=$(curl -sS -X POST "${WEBHOOK_BASE}${WEBHOOK_PATH}" \
    -H "Content-Type: application/json" \
    -d "$payload")

  echo "Response:"
  echo "$response" | jq . 2>/dev/null || echo "$response"
  echo ""

  # Check if response is empty
  if [[ -z "$response" ]]; then
    echo "❌ FAIL: Empty response for $action_name"
    echo ""
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  # Check if response is valid JSON
  if ! echo "$response" | jq empty 2>/dev/null; then
    echo "❌ FAIL: Invalid JSON response for $action_name"
    echo "   Response: $response"
    echo ""
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi

  # Check if messageForUser exists
  if ! echo "$response" | jq -e '.messageForUser' >/dev/null 2>&1; then
    echo "⚠️  WARN: No messageForUser field in $action_name response"
  fi

  # Check for action field
  if echo "$response" | jq -e '.action' >/dev/null 2>&1; then
    actual_action=$(echo "$response" | jq -r '.action')
    echo "   Action: $actual_action"
  fi

  echo "✅ PASS: $action_name returns valid response"
  echo ""
  PASS_COUNT=$((PASS_COUNT + 1))
  return 0
}

# Test 1: Create a ticket
echo "Test 1: CREATE action"
create_payload='{
  "action": "create",
  "name": "Response Test User",
  "email": "responsetest@example.com",
  "subject": "All Actions Response Test",
  "description": "Testing that all actions return proper HTTP responses",
  "priority": "high"
}'

test_action_response "create" "$create_payload" "CREATE"

# Extract ticket ID for subsequent tests
echo "Extracting ticket ID from create response..."
ticket_id=$(curl -sS -X POST "${WEBHOOK_BASE}${WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d "$create_payload" | jq -r '.ticketId // .messageForUser' | grep -o 'TCK-[0-9]*-[0-9]*' | head -1)

if [[ -z "$ticket_id" ]]; then
  echo "⚠️  Could not extract ticket ID, using a test ID"
  ticket_id="TCK-1234567890123-456"
else
  echo "Using ticket ID: $ticket_id"
fi
echo ""

sleep 1

# Test 2: Status check
echo "Test 2: STATUS action"
status_payload=$(jq -nc --arg t "$ticket_id" '{action: "status", ticketId: $t}')
test_action_response "status" "$status_payload" "STATUS"

sleep 1

# Test 3: Update ticket
echo "Test 3: UPDATE action"
update_payload=$(jq -nc --arg t "$ticket_id" '{action: "update", ticketId: $t, description: "Adding test update via response validation"}')
test_action_response "update" "$update_payload" "UPDATE"

sleep 1

# Test 4: Close ticket
echo "Test 4: CLOSE action"
close_payload=$(jq -nc --arg t "$ticket_id" '{action: "close", ticketId: $t}')
test_action_response "close" "$close_payload" "CLOSE"

# Summary
echo "============================================"
echo "  Test Summary"
echo "============================================"
echo "Total Passed: $PASS_COUNT"
echo "Total Failed: $FAIL_COUNT"
echo ""

if [[ $FAIL_COUNT -eq 0 ]]; then
  echo "🎉 All response tests passed!"
  exit 0
else
  echo "❌ Some tests failed. Review the output above."
  exit 1
fi
