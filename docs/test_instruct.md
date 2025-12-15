# Testing Instructions for Ticket Manager Workflow

## 📝 Step-by-Step Testing Guide

### Prerequisites

Ensure environment variables are set (already done in `~/.zshrc`):
```bash
export N8N_WEBHOOK_BASE="https://polarmedia.app.n8n.cloud"
export N8N_TICKET_WEBHOOK_PATH="/webhook/tt"
```

If you open a new terminal, these will be loaded automatically. To verify:
```bash
echo $N8N_WEBHOOK_BASE
echo $N8N_TICKET_WEBHOOK_PATH
```

---

## Step 1: Create a New Ticket

Copy and paste this into your terminal:

```bash
curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "create",
    "name": "John Smith",
    "email": "praneethvallabha@gmail.com",
    "subject": "Login Issue",
    "description": "Cannot login to my account",
    "priority": "high"
  }' | jq .
```

**What you'll see:**
- A JSON response with `ticketId`, `status`, `priority`, etc.
- Look for the **ticketId** (something like `TCK-1764835411473-563`)

**Copy the ticket ID** - you'll need it for the next steps!

---

## Step 2: Save Your Ticket ID

After the create command, copy the ticket ID and save it:

```bash
TICKET_ID="TCK-1764835411473-563"  # Replace with YOUR ticket ID
```

Press Enter to save it.

---

## Step 3: Check Ticket Status

```bash
curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d "{
    \"action\": \"status\",
    \"ticketId\": \"$TICKET_ID\"
  }" | jq .
```

**What you'll see:**
- Current ticket status
- Subject, priority, etc.

---

## Step 4: Update the Ticket

```bash
curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d "{
    \"action\": \"update\",
    \"ticketId\": \"$TICKET_ID\",
    \"description\": \"I tried resetting my password but still can't login\"
  }" | jq .
```

**What you'll see:**
- Confirmation that the ticket was updated

---

## Step 5: Close the Ticket

```bash
curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d "{
    \"action\": \"close\",
    \"ticketId\": \"$TICKET_ID\"
  }" | jq .
```

**What you'll see:**
- Confirmation that the ticket was closed
- Status should be "closed"

---

## Step 6: Try to Update After Closing (Should Fail)

```bash
curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d "{
    \"action\": \"update\",
    \"ticketId\": \"$TICKET_ID\",
    \"description\": \"Trying to update a closed ticket\"
  }" | jq .
```

**What you'll see:**
- Error message: "Ticket is closed and cannot be updated"

---

## 🎯 Quick Reference Commands

### Create Ticket
```bash
curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "create",
    "name": "Test User",
    "email": "praneethvallabha@gmail.com",
    "subject": "Test",
    "description": "Test ticket",
    "priority": "medium"
  }' | jq .
```

### Check Status
```bash
curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d '{"action":"status","ticketId":"YOUR_TICKET_ID_HERE"}' | jq .
```

### Update Ticket
```bash
curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d '{"action":"update","ticketId":"YOUR_TICKET_ID_HERE","description":"Update text"}' | jq .
```

### Close Ticket
```bash
curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d '{"action":"close","ticketId":"YOUR_TICKET_ID_HERE"}' | jq .
```

---

## 📋 Complete Test in One Go

Run the full automated test suite:

```bash
./all_test.sh
```

This will:
1. ✅ Create a ticket
2. ✅ Check status
3. ✅ Update it
4. ✅ Try empty update (should block)
5. ✅ Close it
6. ✅ Try updating closed ticket (should block)

---

## 💡 Pro Tips

### 1. Save response to a file
```bash
curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "create",
    "name": "Test",
    "email": "praneethvallabha@gmail.com",
    "subject": "Test",
    "description": "Test",
    "priority": "medium"
  }' > response.json

cat response.json | jq .
```

### 2. Extract just the ticket ID
```bash
cat response.json | jq -r '.ticketId'
```

### 3. Create and save ticket ID in one command
```bash
TICKET_ID=$(curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "create",
    "name": "Test",
    "email": "praneethvallabha@gmail.com",
    "subject": "Test",
    "description": "Test",
    "priority": "medium"
  }' | jq -r '.ticketId')

echo "Created ticket: $TICKET_ID"
```

### 4. Test with different emails
```bash
curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "create",
    "name": "Another User",
    "email": "anotheremail@example.com",
    "subject": "Different Issue",
    "description": "Different problem",
    "priority": "low"
  }' | jq .
```

### 5. View request/response headers for debugging
```bash
curl -v -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d '{"action":"status","ticketId":"YOUR_TICKET_ID"}' | jq .
```

---

## 🔍 What to Look For in Responses

### ✅ Successful Create
```json
{
  "action": "create",
  "ticketId": "TCK-1764835411473-563",
  "status": "open",
  "priority": "high",
  "subject": "Login Issue",
  "customerName": "John Smith",
  "customerEmail": "praneethvallabha@gmail.com",
  "messageForUser": "I've created ticket TCK-... for your issue..."
}
```

### ✅ Successful Status Check
```json
{
  "action": "status",
  "ticketId": "TCK-1764835411473-563",
  "status": "open",
  "priority": "high",
  "messageForUser": "Ticket TCK-... is currently open..."
}
```

### ✅ Successful Update
```json
{
  "action": "update",
  "ticketId": "TCK-1764835411473-563",
  "status": "open",
  "priority": "high",
  "messageForUser": "I've updated your ticket TCK-... with your latest message."
}
```

### ✅ Successful Close
```json
{
  "action": "close",
  "ticketId": "TCK-1764835411473-563",
  "status": "closed",
  "messageForUser": "I've closed ticket TCK-..."
}
```

### ⚠️ Blocked - Empty Update
```json
{
  "action": "update",
  "ticketId": "TCK-1764835411473-563",
  "status": "open",
  "messageForUser": "Please provide the update details so I can add them to your ticket."
}
```

### ⚠️ Blocked - Update Closed Ticket
```json
{
  "action": "update",
  "ticketId": "TCK-1764835411473-563",
  "status": "closed",
  "messageForUser": "Ticket TCK-... is closed and cannot be updated. Please open a new ticket or ask to reopen."
}
```

---

## 🧪 Test Scenarios

### Scenario 1: Basic Flow
```bash
# 1. Create
TICKET_ID=$(curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d '{"action":"create","name":"User","email":"praneethvallabha@gmail.com","subject":"Issue","description":"Problem","priority":"medium"}' \
  | jq -r '.ticketId')

echo "Created: $TICKET_ID"

# 2. Status
curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d "{\"action\":\"status\",\"ticketId\":\"$TICKET_ID\"}" | jq .

# 3. Update
curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d "{\"action\":\"update\",\"ticketId\":\"$TICKET_ID\",\"description\":\"More details\"}" | jq .

# 4. Close
curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d "{\"action\":\"close\",\"ticketId\":\"$TICKET_ID\"}" | jq .
```

### Scenario 2: Priority Levels
```bash
# High priority
curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d '{"action":"create","name":"User","email":"praneethvallabha@gmail.com","subject":"Urgent","description":"Critical issue","priority":"high"}' | jq .

# Low priority
curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d '{"action":"create","name":"User","email":"praneethvallabha@gmail.com","subject":"Question","description":"Minor inquiry","priority":"low"}' | jq .
```

### Scenario 3: Edge Cases
```bash
# Empty description on update (should block)
curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d "{\"action\":\"update\",\"ticketId\":\"$TICKET_ID\",\"description\":\"\"}" | jq .

# Non-existent ticket
curl -sS -X POST "${N8N_WEBHOOK_BASE}${N8N_TICKET_WEBHOOK_PATH}" \
  -H "Content-Type: application/json" \
  -d '{"action":"status","ticketId":"TCK-FAKE-123"}' | jq .
```

---

## 📧 Email Notifications

After running tests, check `praneethvallabha@gmail.com` for:
- ✉️ Ticket creation notification
- ✉️ Ticket update notification
- ✉️ Ticket close notification

*(Check spam folder if not in inbox)*

---

## 🐛 Troubleshooting

### Issue: `command not found: jq`
**Solution:**
```bash
brew install jq
```

### Issue: Empty response
**Solution:**
- Check if workflow is active in n8n
- Verify webhook URL: `https://polarmedia.app.n8n.cloud/webhook/tt`
- Check n8n execution logs

### Issue: `401 Unauthorized`
**Solution:**
- Add authentication header if required:
```bash
export AUTH_HEADER="Authorization: Bearer YOUR_TOKEN"
```

### Issue: No email received
**Solution:**
- Check spam folder
- Verify email configuration in n8n workflow
- Check n8n execution logs for email node errors

---

## 📚 Additional Resources

- **Test Scripts:**
  - `./all_test.sh` - Full automated test suite
  - `./test_create.sh` - Create ticket only
  - `./test_status.sh <ticketId>` - Check status only
  - `./test_close_bug_reproduction.sh` - Test close operation

- **Documentation:**
  - `CLAUDE.md` - Project overview and workflow architecture
  - `summary_till_now.md` - Session logs and changes

- **Workflows:**
  - `Ticket Manager (Airtable).json` - Main workflow
  - `customer_notifications_workflow.json` - Email notification workflow

---

## 🎓 Learning the API

### Action Types
- `create` - Create a new ticket
- `status` - Check ticket status
- `update` - Update existing ticket
- `close` - Close a ticket

### Required Fields by Action

**Create:**
- `action`: "create"
- `name`: Customer name
- `email`: Customer email
- `subject`: Ticket subject
- `description`: Issue description
- `priority`: "low", "medium", or "high"

**Status:**
- `action`: "status"
- `ticketId`: Ticket ID

**Update:**
- `action`: "update"
- `ticketId`: Ticket ID
- `description`: Update text (required, cannot be empty)

**Close:**
- `action`: "close"
- `ticketId`: Ticket ID

---

Happy Testing! 🚀
