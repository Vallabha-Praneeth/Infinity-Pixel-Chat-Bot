# Comprehensive Testing Plan - Ticket Manager Workflows

## Overview

This testing plan covers:
1. Pre-fix validation (document current state)
2. Post-fix validation (verify fixes work)
3. Regression testing (ensure nothing breaks)
4. Edge case testing (handle errors gracefully)

## Prerequisites

### Environment Setup
```bash
export N8N_WEBHOOK_BASE="https://polarmedia.app.n8n.cloud"
export N8N_TICKET_WEBHOOK_PATH="/webhook/tt"
# AUTH_HEADER not needed if webhook is public
```

### Tools Required
- `curl` - HTTP client
- `jq` - JSON processor
- `bash` 4.0+ - Shell scripting

### Test Data Repository
Create a test data file to track ticket IDs across tests:
```bash
# test_data.txt format:
# ticket_id,action,timestamp,expected_status
```

---

## Phase 1: Pre-Fix Validation (Document Current Broken State)

### Objective
Document exactly what's broken before making changes.

### Test 1.1: Close Action - Stale Ticket ID Bug
**Purpose**: Reproduce the reported bug

```bash
#!/bin/bash
# test_close_bug_reproduction.sh

# Step 1: Create a fresh ticket
echo "Creating ticket..."
create_response=$(curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "create",
    "name": "Test User",
    "email": "test@example.com",
    "subject": "Close Bug Test",
    "description": "Testing close action bug",
    "priority": "medium"
  }')

echo "Create response: $create_response"

# Extract ticket ID
ticket_id=$(echo "$create_response" | jq -r '.ticketId // .messageForUser' | grep -o 'TCK-[0-9]*-[0-9]*' | head -1)
echo "Created ticket: $ticket_id"

# Step 2: Close the ticket
echo -e "\nClosing ticket $ticket_id..."
close_response=$(curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d "{\"action\": \"close\", \"ticketId\": \"$ticket_id\"}")

echo "Close response: $close_response"

# Step 3: Validate response
response_ticket_id=$(echo "$close_response" | jq -r '.ticketId // empty')

if [[ "$response_ticket_id" == "$ticket_id" ]]; then
  echo "✅ PASS: Ticket ID matches ($ticket_id)"
else
  echo "❌ FAIL: Ticket ID mismatch!"
  echo "   Expected: $ticket_id"
  echo "   Got: $response_ticket_id"
  echo "   Full response: $close_response"
fi
```

**Expected Result (Pre-Fix)**: ❌ FAIL - Returns stale ID `TCK-1764663980054-324`

### Test 1.2: All Actions Response Validation
**Purpose**: Check if all actions return proper webhook responses

```bash
#!/bin/bash
# test_all_actions_responses.sh

test_action_response() {
  local action=$1
  local payload=$2
  local action_name=$3

  echo "Testing $action_name..."
  response=$(curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
    -H "Content-Type: application/json" \
    -d "$payload")

  # Check if response is empty
  if [[ -z "$response" ]]; then
    echo "❌ FAIL: Empty response for $action_name"
    return 1
  fi

  # Check if response is valid JSON
  if ! echo "$response" | jq empty 2>/dev/null; then
    echo "❌ FAIL: Invalid JSON response for $action_name"
    echo "   Response: $response"
    return 1
  fi

  # Check if messageForUser exists
  if ! echo "$response" | jq -e '.messageForUser' >/dev/null 2>&1; then
    echo "⚠️  WARN: No messageForUser in $action_name response"
  fi

  echo "✅ PASS: $action_name returns valid response"
  echo "   Response: $response"
  return 0
}

# Create a ticket for other tests
create_payload='{
  "action": "create",
  "name": "Test User",
  "email": "test@example.com",
  "subject": "Response Test Ticket",
  "description": "Testing all action responses",
  "priority": "high"
}'

test_action_response "create" "$create_payload" "CREATE"

# Extract ticket ID from create response
ticket_id=$(curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d "$create_payload" | jq -r '.ticketId // .messageForUser' | grep -o 'TCK-[0-9]*-[0-9]*' | head -1)

# Test status
status_payload=$(jq -nc --arg t "$ticket_id" '{action: "status", ticketId: $t}')
test_action_response "status" "$status_payload" "STATUS"

# Test update
update_payload=$(jq -nc --arg t "$ticket_id" '{action: "update", ticketId: $t, description: "Adding update"}')
test_action_response "update" "$update_payload" "UPDATE"

# Test close
close_payload=$(jq -nc --arg t "$ticket_id" '{action: "close", ticketId: $t}')
test_action_response "close" "$close_payload" "CLOSE"
```

**Expected Result (Pre-Fix)**:
- CREATE: ✅ or ⚠️
- STATUS: ⚠️ or ❌ (possibly empty)
- UPDATE: ❌ (known to return empty from updates.md)
- CLOSE: ❌ (returns stale data or empty)

### Test 1.3: Trace Data Flow Through Close Branch
**Purpose**: Understand what data each node receives/outputs

**Manual Steps**:
1. Open n8n workflow editor for "Ticket Manager (Airtable)"
2. Create a test ticket in Airtable (note the Ticket ID)
3. Execute workflow manually with input:
   ```json
   {
     "action": "close",
     "ticketId": "TCK-YOUR-TEST-ID"
   }
   ```
4. For each node in close branch, click to view output:
   - `Action Switch` → Check close output
   - `Airtable - Find Ticket (Close)` → Check if it found the right ticket
   - `Code - Prepare Close` → Check if ticketId is present in output
   - `Airtable - Close Ticket` → Check what fields are in the response
   - `Code - Build Close Response` → Check if ticketId is correct

5. Document findings:
   ```
   Node: Airtable - Find Ticket (Close)
   Output: { id: "recXXX", fields: { "Ticket ID": "TCK-...", ... } }

   Node: Code - Prepare Close
   Output: { ticketId: "TCK-...", status: "closed", ... }

   Node: Airtable - Close Ticket
   Output: { id: "recXXX", fields: { ??? } } ← Document actual structure

   Node: Code - Build Close Response
   Output: { ticketId: "???", ... } ← Is this correct or stale?
   ```

---

## Phase 2: Post-Fix Validation

### Test 2.1: Close Action - Fixed Ticket ID
**Purpose**: Verify close action returns correct ticket ID

**Reuse**: `test_close_bug_reproduction.sh` from Test 1.1

**Expected Result (Post-Fix)**: ✅ PASS - Returns matching ticket ID

### Test 2.2: Webhook Response on All Actions
**Purpose**: Verify all actions return HTTP responses

**Reuse**: `test_all_actions_responses.sh` from Test 1.2

**Expected Result (Post-Fix)**:
- CREATE: ✅ PASS
- STATUS: ✅ PASS
- UPDATE: ✅ PASS
- CLOSE: ✅ PASS

### Test 2.3: Complete Workflow - End to End
**Purpose**: Run the full test suite

```bash
# Reuse existing all_test.sh
./all_test.sh
```

**Expected Result (Post-Fix)**:
```
✅ create ok -> TCK-...
✅ status ok
✅ update ok
✅ update without text blocked
✅ close ok
✅ closed update blocked
🎉 All tests passed
```

---

## Phase 3: Regression Testing

### Test 3.1: Existing Functionality Still Works
**Purpose**: Ensure fixes didn't break anything

#### Test 3.1.1: Create with All Fields
```bash
curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "create",
    "name": "John Doe",
    "email": "john@example.com",
    "subject": "Urgent billing issue",
    "description": "Cannot access billing dashboard",
    "priority": "high"
  }' | jq
```

**Validate**:
- ✅ Returns ticket ID in expected format `TCK-{timestamp}-{random}`
- ✅ Status is "open"
- ✅ SLA due date is set (1 day for high priority)
- ✅ messageForUser is friendly and informative

#### Test 3.1.2: Create with Minimal Fields
```bash
curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "create",
    "description": "Just a description"
  }' | jq
```

**Validate**:
- ✅ Creates ticket with default values
- ✅ Subject = "No subject provided"
- ✅ Priority = "medium"
- ✅ SLA = 3 days

#### Test 3.1.3: Status - Existing Ticket
```bash
# Use ticket ID from create test
curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d "{\"action\": \"status\", \"ticketId\": \"$TICKET_ID\"}" | jq
```

**Validate**:
- ✅ Returns current status, subject, priority
- ✅ Includes internal notes if any

#### Test 3.1.4: Status - Non-existent Ticket
```bash
curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d '{"action": "status", "ticketId": "TCK-FAKE-999"}' | jq
```

**Validate**:
- ✅ Returns "not found" message
- ✅ Helpful error message

#### Test 3.1.5: Update - Valid Update
```bash
curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d "{
    \"action\": \"update\",
    \"ticketId\": \"$TICKET_ID\",
    \"description\": \"Additional info: tried clearing cache\"
  }" | jq
```

**Validate**:
- ✅ Confirmation message
- ✅ Ticket remains open
- ✅ Updated At timestamp refreshed

#### Test 3.1.6: Update - Empty Description (Should Block)
```bash
curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d "{
    \"action\": \"update\",
    \"ticketId\": \"$TICKET_ID\",
    \"description\": \"\"
  }" | jq
```

**Validate**:
- ✅ Blocked with message: "Please provide the update details..."
- ✅ Ticket NOT updated in Airtable

#### Test 3.1.7: Update - Closed Ticket (Should Block)
```bash
# First close a ticket
curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d "{\"action\": \"close\", \"ticketId\": \"$TICKET_ID\"}"

# Then try to update it
curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d "{
    \"action\": \"update\",
    \"ticketId\": \"$TICKET_ID\",
    \"description\": \"Trying to update closed ticket\"
  }" | jq
```

**Validate**:
- ✅ Blocked with message about ticket being closed
- ✅ Suggests opening new ticket or reopening

#### Test 3.1.8: Close - Already Closed
```bash
# Close the same ticket twice
curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d "{\"action\": \"close\", \"ticketId\": \"$TICKET_ID\"}" | jq

curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d "{\"action\": \"close\", \"ticketId\": \"$TICKET_ID\"}" | jq
```

**Validate**:
- ✅ Second close returns "already closed" message
- ✅ Idempotent operation (safe to call multiple times)

---

## Phase 4: Edge Case Testing

### Test 4.1: Invalid/Malformed Inputs

#### Test 4.1.1: Missing Action
```bash
curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d '{"ticketId": "TCK-123"}' | jq
```

**Expected**: Default to "create" OR return error

#### Test 4.1.2: Invalid Action
```bash
curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d '{"action": "delete", "ticketId": "TCK-123"}' | jq
```

**Expected**: Error message or fallback behavior

#### Test 4.1.3: Malformed JSON
```bash
curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d '{action: create, invalid json}'
```

**Expected**: HTTP 400 or error response

#### Test 4.1.4: Missing Ticket ID on Status/Update/Close
```bash
# Status without ticket ID
curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d '{"action": "status"}' | jq
```

**Expected**: "Ticket not found" or "Please provide ticket ID"

#### Test 4.1.5: Special Characters in Fields
```bash
curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "create",
    "subject": "Test with \"quotes\" and \u0027apostrophes\u0027",
    "description": "Testing special chars: <script>alert(\"xss\")</script>",
    "priority": "high"
  }' | jq
```

**Expected**: Properly escaped/handled, no XSS or injection

#### Test 4.1.6: Very Long Description
```bash
long_desc=$(python3 -c "print('A' * 10000)")
curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d "{
    \"action\": \"create\",
    \"subject\": \"Long description test\",
    \"description\": \"$long_desc\"
  }" | jq
```

**Expected**: Handles without error (or truncates gracefully)

### Test 4.2: Concurrency & Race Conditions

#### Test 4.2.1: Simultaneous Creates
```bash
# Create 5 tickets simultaneously
for i in {1..5}; do
  curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
    -H "Content-Type: application/json" \
    -d "{
      \"action\": \"create\",
      \"subject\": \"Concurrent test $i\",
      \"description\": \"Testing concurrency\"
    }" &
done
wait
```

**Expected**: All 5 tickets created with unique IDs

#### Test 4.2.2: Update Same Ticket Concurrently
```bash
# Multiple updates to same ticket
for i in {1..3}; do
  curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
    -H "Content-Type: application/json" \
    -d "{
      \"action\": \"update\",
      \"ticketId\": \"$TICKET_ID\",
      \"description\": \"Concurrent update $i\"
    }" &
done
wait
```

**Expected**: All updates recorded (check Conversation Log)

### Test 4.3: Airtable Integration Errors

#### Test 4.3.1: Simulate Airtable Down (Manual)
**Steps**:
1. In n8n, temporarily disable Airtable credentials
2. Try to create a ticket
3. Observe error handling

**Expected**: Graceful error message to user (not crash)

#### Test 4.3.2: Invalid Airtable Record ID
**Requires**: Direct workflow execution with bad data
```json
{
  "action": "update",
  "ticketId": "TCK-123",
  "airtableRecordId": "recINVALID"
}
```

**Expected**: Error handled gracefully

---

## Phase 5: Performance Testing

### Test 5.1: Response Time Benchmarks
```bash
#!/bin/bash
# benchmark_response_times.sh

for action in create status update close; do
  echo "Benchmarking $action..."

  # Prepare payload based on action
  if [[ "$action" == "create" ]]; then
    payload='{"action":"create","subject":"Benchmark test","description":"Testing"}'
  else
    payload="{\"action\":\"$action\",\"ticketId\":\"$TICKET_ID\"}"
    [[ "$action" == "update" ]] && payload="{\"action\":\"update\",\"ticketId\":\"$TICKET_ID\",\"description\":\"Update\"}"
  fi

  # Measure 10 requests
  total=0
  for i in {1..10}; do
    start=$(date +%s%N)
    curl -sS -X POST "$N8N_WEBHOOK_BASE$N8N_TICKET_WEBHOOK_PATH" \
      -H "Content-Type: application/json" \
      -d "$payload" > /dev/null
    end=$(date +%s%N)
    duration=$(( (end - start) / 1000000 ))  # Convert to ms
    total=$((total + duration))
    echo "  Request $i: ${duration}ms"
  done

  avg=$((total / 10))
  echo "  Average: ${avg}ms"
  echo ""
done
```

**Baseline**: Document current response times
**Target**: All actions < 2000ms

---

## Test Results Template

### Pre-Fix Results
```
Date: YYYY-MM-DD
Tester: [Name]

Phase 1 Results:
- Test 1.1 (Close Bug): ❌ FAIL - Returns TCK-1764663980054-324
- Test 1.2 (All Responses):
  - Create: ✅
  - Status: ❌ Empty response
  - Update: ❌ Empty response
  - Close: ❌ Stale ticket ID

Notes: [Observations]
```

### Post-Fix Results
```
Date: YYYY-MM-DD
Tester: [Name]
Fix Applied: [Description of fix]

Phase 2 Results:
- Test 2.1 (Close Fixed): ✅ PASS
- Test 2.2 (Webhook Responses): ✅ PASS (all actions)
- Test 2.3 (Full Suite): ✅ PASS

Phase 3 Results:
- All regression tests: ✅ PASS

Phase 4 Results:
- Edge cases: [X/Y passed]
- Failed cases: [List]

Phase 5 Results:
- Create: XXXms avg
- Status: XXXms avg
- Update: XXXms avg
- Close: XXXms avg

Overall: ✅ PASS / ❌ FAIL
```

---

## Automated Test Suite

### Master Test Runner
```bash
#!/bin/bash
# run_all_tests.sh

echo "============================================"
echo "  Ticket Manager - Comprehensive Test Suite"
echo "============================================"
echo ""

# Check prerequisites
command -v curl >/dev/null 2>&1 || { echo "Error: curl required"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: jq required"; exit 1; }

[[ -z "$N8N_WEBHOOK_BASE" ]] && { echo "Error: Set N8N_WEBHOOK_BASE"; exit 1; }
[[ -z "$N8N_TICKET_WEBHOOK_PATH" ]] && { echo "Error: Set N8N_TICKET_WEBHOOK_PATH"; exit 1; }

# Run test phases
echo "Phase 1: Pre-Fix Validation"
echo "----------------------------"
./test_close_bug_reproduction.sh
./test_all_actions_responses.sh
echo ""

echo "Phase 2: Full Workflow Test"
echo "----------------------------"
./all_test.sh
echo ""

echo "Phase 3: Regression Tests"
echo "----------------------------"
# Run individual regression tests...
echo ""

echo "Phase 4: Edge Cases"
echo "----------------------------"
# Run edge case tests...
echo ""

echo "============================================"
echo "  Test Suite Complete"
echo "============================================"
```

---

## Success Criteria

### Minimum Viable (Must Pass)
- ✅ Close action returns correct ticket ID
- ✅ All actions return HTTP responses
- ✅ `all_test.sh` passes 100%

### Production Ready (Should Pass)
- ✅ All regression tests pass
- ✅ No empty responses on any action
- ✅ Error cases handled gracefully
- ✅ Response times < 2s

### Excellent (Nice to Have)
- ✅ All edge cases handled
- ✅ Comprehensive error messages
- ✅ Performance benchmarks documented
- ✅ Concurrency tests pass
