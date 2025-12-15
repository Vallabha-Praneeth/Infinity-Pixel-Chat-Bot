#!/usr/bin/env bash

# Close Bug Reproduction Test
# Purpose: Document the exact bug behavior before fixes

set -euo pipefail

WEBHOOK_BASE="${N8N_WEBHOOK_BASE:-}"
WEBHOOK_PATH="${N8N_TICKET_WEBHOOK_PATH:-}"

if [[ -z "$WEBHOOK_BASE" || -z "$WEBHOOK_PATH" ]]; then
  echo "❌ Error: Missing N8N_WEBHOOK_BASE or N8N_TICKET_WEBHOOK_PATH env vars." >&2
  echo "Set them like:" >&2
  echo "  export N8N_WEBHOOK_BASE='https://polarmedia.app.n8n.cloud'" >&2
  echo "  export N8N_TICKET_WEBHOOK_PATH='/webhook/tt'" >&2
  exit 1
fi

echo "============================================"
echo "  Close Bug Reproduction Test"
echo "============================================"
echo ""

# Step 1: Create a fresh ticket
echo "Step 1: Creating a new ticket..."
create_response=$(curl -sS -X POST "${WEBHOOK_BASE}${WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "create",
    "name": "Close Bug Test User",
    "email": "closetest@example.com",
    "subject": "Close Bug Reproduction Test",
    "description": "This ticket is created to test the close action bug",
    "priority": "medium"
  }')

echo "Create response:"
echo "$create_response" | jq . 2>/dev/null || echo "$create_response"
echo ""

# Extract ticket ID
if echo "$create_response" | jq -e '.ticketId' >/dev/null 2>&1; then
  ticket_id=$(echo "$create_response" | jq -r '.ticketId')
else
  ticket_id=$(echo "$create_response" | jq -r '.messageForUser // empty' | grep -o 'TCK-[0-9]*-[0-9]*' | head -1)
fi

if [[ -z "$ticket_id" ]]; then
  echo "❌ FAIL: Could not extract ticket ID from create response" >&2
  echo "Response was: $create_response" >&2
  exit 1
fi

echo "✅ Created ticket: $ticket_id"
echo ""

# Wait a moment to ensure Airtable write completes
sleep 2

# Step 2: Close the ticket
echo "Step 2: Closing ticket $ticket_id..."
close_response=$(curl -sS -X POST "${WEBHOOK_BASE}${WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d "{\"action\": \"close\", \"ticketId\": \"$ticket_id\"}")

echo "Close response:"
echo "$close_response" | jq . 2>/dev/null || echo "$close_response"
echo ""

# Step 3: Validate response
echo "Step 3: Validating response..."
echo ""

# Check if response is valid JSON
if ! echo "$close_response" | jq empty 2>/dev/null; then
  echo "❌ FAIL: Invalid JSON response or empty response" >&2
  echo "Expected valid JSON, got: $close_response" >&2
  exit 1
fi

# Extract ticket ID from response
response_ticket_id=$(echo "$close_response" | jq -r '.ticketId // empty')

if [[ -z "$response_ticket_id" ]]; then
  echo "⚠️  WARN: No ticketId field in response"
  echo "Trying to extract from messageForUser..."
  response_ticket_id=$(echo "$close_response" | jq -r '.messageForUser // empty' | grep -o 'TCK-[0-9]*-[0-9]*' | head -1)
fi

# Compare ticket IDs
echo "Comparison:"
echo "  Expected ticket ID: $ticket_id"
echo "  Response ticket ID: $response_ticket_id"
echo ""

if [[ "$response_ticket_id" == "$ticket_id" ]]; then
  echo "✅ PASS: Ticket ID matches!"
  echo ""
  echo "The close action is working correctly."
  exit 0
else
  echo "❌ FAIL: Ticket ID mismatch!"
  echo ""
  echo "BUG CONFIRMED:"
  echo "  - We created ticket: $ticket_id"
  echo "  - But close returned: $response_ticket_id"
  echo ""
  echo "This is the bug we need to fix."
  echo "Full close response:"
  echo "$close_response" | jq .
  exit 1
fi
