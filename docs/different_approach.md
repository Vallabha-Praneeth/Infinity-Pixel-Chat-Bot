# Better Approach: Separating Ticket Management from AI Agent

## Overview

Instead of embedding ticket management logic directly in the AI Agent's sub-workflow tool, use the existing tested webhook in the Ticket Manager workflow. This creates a cleaner separation of concerns:

- **AI Agent**: Answers questions from Pinecone vector store
- **HTTP Request Tool**: Bridges to ticket management API
- **Ticket Manager Webhook**: Handles all ticket CRUD operations

## Why This is Better

1. **Separation of concerns**: AI Agent focuses on answering questions, ticket management stays independent
2. **Already working**: Your webhook at `/webhook/tt` is tested and functional via curl
3. **Cleaner architecture**: Ticket API is reusable for other integrations (Slack, mobile apps, etc.)
4. **Easier to debug**: Test ticket operations independently from chat
5. **Simpler AI Agent**: Less complex instructions, fewer failure points
6. **Maintainable**: Update ticket logic without touching AI Agent configuration

---

## Implementation Steps

### Step 1: Remove Current Sub-workflow Tool

In **RAG Workflow For( Customer service chat-bot).json**:

**Delete or disable this node:**
- Node: `Call 'Ticket Manager (Airtable)'` (around lines 541-636)
- This is the `toolWorkflow` node that calls the Ticket Manager as a sub-workflow

**Why:** We're replacing it with an HTTP Request tool that calls the webhook instead.

---

### Step 2: Add HTTP Request Node as AI Tool

In **RAG Workflow**, add a new **HTTP Request** node with these settings:

#### Basic Configuration
- **Name**: `Ticket Manager API`
- **Method**: `POST`
- **URL**: `https://polarmedia.app.n8n.cloud/webhook/tt`
- **Authentication**: None (add Bearer token if you secure it later)

#### Body Content (JSON Format)
```json
{
  "action": "={{ $fromAI('action', 'The ticket action: create, status, update, or close', 'string') }}",
  "ticketId": "={{ $fromAI('ticketId', 'The ticket ID for status/update/close operations', 'string') }}",
  "name": "={{ $fromAI('name', 'Customer name for create action', 'string') }}",
  "email": "={{ $fromAI('email', 'Customer email for create action', 'string') }}",
  "subject": "={{ $fromAI('subject', 'Ticket subject for create action', 'string') }}",
  "description": "={{ $fromAI('description', 'Issue description or update text', 'string') }}",
  "priority": "={{ $fromAI('priority', 'Priority: low, medium, high, urgent', 'string') }}"
}
```

#### Options → Use as AI Tool
Enable this option and configure:

**Tool Name:** `ManageTickets`

**Tool Description:**
```
Manages support tickets via API (create, check status, update, close).

Required parameters by action:
- create: action="create", name, email, subject, description, priority (low/medium/high/urgent)
- status: action="status", ticketId
- update: action="update", ticketId, description (must not be empty)
- close: action="close", ticketId

The API returns JSON with a "messageForUser" field containing the response message to relay to the customer.

Examples:
- Create: Call with action="create" and all customer fields
- Status: Call with action="status" and ticketId="TCK-1764747627276-977"
- Update: Call with action="update", ticketId, and description="customer's update text"
- Close: Call with action="close" and ticketId

Always relay the messageForUser from the response back to the customer.
```

---

### Step 3: Update AI Agent System Message

In the **AI Agent** node (around line 64), replace the entire system message with:

```
You are the Quantum-Ops AI Service Assistant.

Your responsibilities:
1. Answer questions about Quantum-Ops services using the vector store tool
2. Manage customer support tickets using the ManageTickets tool

Quantum-Ops Services (reference only):
- Application Development
- Cloud Application Development
- Cloud Management
- Custom Software Development
- SaaS Development
- Ads Management

Do not invent services outside this list. If unclear, ask clarifying questions.

---

Ticket Management Rules:

CREATE TICKET:
- Required fields: name, email, subject, description, priority
- If any field is missing, ask for it before calling the tool
- Priority options: low, medium, high, urgent
- Example prompt: "I need your name, email, a subject line, description of the issue, and priority level"

CHECK STATUS:
- Required: ticketId only
- Ask: "Could you share the ticket ID so I can look it up?"
- Do NOT ask for name/email/subject/description/priority

UPDATE TICKET:
- Required: ticketId, description (update text)
- Ask: "What's the ticket ID and what update should I add?"
- Do NOT ask for name/email/subject/priority

CLOSE TICKET:
- Required: ticketId only
- Ask: "Which ticket ID should I close?"
- Do NOT ask for name/email/subject/description/priority

---

CRITICAL RESPONSE RULE:
After calling the ManageTickets tool, YOU MUST read the "messageForUser" field from the JSON response and include it in your reply to the customer. Never leave the user without a response after tool execution.

Example:
- Tool returns: {"messageForUser": "I've created ticket TCK-123 for your issue"}
- You say: "I've created ticket TCK-123 for your issue. Our team will get back to you soon."

---

General Guidelines:
- Be concise, professional, and solution-oriented
- Do not ask for internal fields (timestamps, assignee, SLA, Airtable IDs)
- If user goes off-topic, gently redirect to supported services
- Confirm understanding before calling tools
- Always validate required fields before tool execution
```

---

### Step 4: Connect HTTP Request Tool to AI Agent

In the n8n workflow canvas:

1. Open the **RAG Workflow For( Customer service chat-bot)** workflow
2. Add the new **HTTP Request** node (from Step 2)
3. **Connect it to the AI Agent** node:
   - Connection type: `ai_tool`
   - It should be positioned alongside the vector store tool
4. Ensure both tools (HTTP Request + Vector Store) are connected to the AI Agent

**Your AI Agent should now have 2 tool connections:**
- Vector Store Tool (for answering questions)
- HTTP Request Tool (for ticket management)

---

### Step 5: Position the Node

**Recommended position** in canvas:
- Place the HTTP Request node near coordinates `[128, 1328]` (where the old sub-workflow tool was)
- This keeps it visually grouped with the AI Agent node

---

### Step 6: Test the Setup

Run these test scenarios in the chat interface:

#### Test 1: Create Ticket (Missing Fields)
**User:** "Create a ticket for login issue"

**Expected:** AI asks for missing fields (name, email, priority, detailed description)

#### Test 2: Create Ticket (Complete)
**User:** "Create ticket - Name: John Doe, Email: john@test.com, Subject: Login issue, Description: Cannot access dashboard after password reset, Priority: high"

**Expected:** AI calls tool, returns ticket ID like "I've created ticket TCK-1234567890-123 for your issue. Our team will get back to you soon."

#### Test 3: Check Status
**User:** "Check status of ticket TCK-1764747627276-977"

**Expected:** AI returns status like "Ticket TCK-1764747627276-977 is currently open. Subject: Login issue."

#### Test 4: Update Ticket
**User:** "Update ticket TCK-1764747627276-977 with 'tried clearing cache, still not working'"

**Expected:** AI returns "I've updated your ticket TCK-1764747627276-977 with your latest message."

#### Test 5: Close Ticket
**User:** "Close ticket TCK-1764747627276-977"

**Expected:** AI returns "I've closed ticket TCK-1764747627276-977. If you run into the issue again, you can create a new ticket anytime."

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│         RAG Workflow (Chatbot)                  │
│                                                 │
│  ┌──────────────┐                               │
│  │ Chat Trigger │                               │
│  └──────┬───────┘                               │
│         │                                       │
│         ▼                                       │
│  ┌──────────────┐      ┌──────────────────┐    │
│  │  AI Agent    │◄─────┤ Vector Store     │    │
│  │              │      │ Tool (Pinecone)  │    │
│  │              │      └──────────────────┘    │
│  │              │                               │
│  │              │      ┌──────────────────┐    │
│  │              │◄─────┤ HTTP Request     │    │
│  │              │      │ Tool (API call)  │    │
│  └──────────────┘      └────────┬─────────┘    │
│                                 │               │
└─────────────────────────────────┼───────────────┘
                                  │
                                  │ POST /webhook/tt
                                  │
                                  ▼
┌─────────────────────────────────────────────────┐
│      Ticket Manager (Airtable)                  │
│                                                 │
│  ┌──────────────┐                               │
│  │   Webhook    │                               │
│  └──────┬───────┘                               │
│         │                                       │
│         ▼                                       │
│  ┌──────────────┐                               │
│  │ Normalize &  │                               │
│  │ Validate     │                               │
│  └──────┬───────┘                               │
│         │                                       │
│         ▼                                       │
│  ┌──────────────┐                               │
│  │ Action Switch│                               │
│  └──┬───┬───┬───┘                               │
│     │   │   │                                   │
│  ┌──▼┐ ┌▼─┐ ┌▼──┐ ┌──────┐                     │
│  │C│ │U│ │S│ │Cl│                              │
│  │R│ │P│ │T│ │OS│                              │
│  │E│ │D│ │A│ │SE│                              │
│  │A│ │A│ │T│ │  │                              │
│  │T│ │T│ │U│ │  │                              │
│  │E│ │E│ │S│ │  │                              │
│  └──┬┘ └┬─┘ └┬──┘ └──┬───┘                     │
│     │   │    │       │                         │
│     └───┴────┴───────┘                         │
│              │                                  │
│              ▼                                  │
│  ┌──────────────────┐                          │
│  │ Airtable CRUD    │                          │
│  └──────────────────┘                          │
│              │                                  │
│              ▼                                  │
│  ┌──────────────────┐                          │
│  │ Return Response  │                          │
│  │ (messageForUser) │                          │
│  └──────────────────┘                          │
└─────────────────────────────────────────────────┘
```

---

## Benefits Summary

### Before (Sub-workflow Tool)
- ❌ Complex AI Agent instructions (200+ lines)
- ❌ Tightly coupled to AI Agent
- ❌ Hard to test independently
- ❌ Schema validation issues
- ❌ Difficult to reuse for other integrations

### After (HTTP Request Tool + Webhook)
- ✅ Clean AI Agent instructions (50-80 lines)
- ✅ Loosely coupled, independent components
- ✅ Easy to test via curl/Postman
- ✅ Standard JSON request/response
- ✅ Reusable API for Slack, mobile apps, etc.
- ✅ Add authentication/rate limiting easily
- ✅ Version control friendly
- ✅ Scale independently

---

## Troubleshooting

### Issue: AI Agent not calling the tool
**Solution:** Check that:
1. HTTP Request node is connected to AI Agent as `ai_tool`
2. "Use as AI Tool" is enabled in HTTP Request options
3. Tool description is clear about when to use it

### Issue: Tool called but no response to user
**Solution:** Check that:
1. System message tells AI to relay `messageForUser` field
2. HTTP Request returns JSON with `messageForUser`
3. Ticket Manager webhook is responding correctly (test with curl)

### Issue: Schema validation errors
**Solution:**
- Remove any schema validation from HTTP Request node
- The Ticket Manager webhook handles all validation internally
- AI Agent just sends raw JSON with `$fromAI()` expressions

### Issue: Missing ticketId for status checks
**Solution:**
- Ensure `ticketId` is in the body JSON of HTTP Request node
- System message should tell AI to ask for ticketId when needed
- Test with: "check status for ticket TCK-123"

---

## Next Steps

Once this is working:

1. **Add authentication** to the webhook (Bearer token)
2. **Add rate limiting** to prevent abuse
3. **Log all ticket operations** for audit trail
4. **Add Slack notifications** when tickets are created/updated
5. **Create additional integrations** (mobile app, email, etc.) using the same webhook
6. **Version the API** (`/webhook/v1/tickets`) for future changes

---

## Maintenance

### Updating Ticket Logic
- Edit the Ticket Manager workflow
- No need to touch AI Agent or RAG workflow
- Test via curl first, then through chat

### Updating AI Agent Behavior
- Edit AI Agent system message only
- No need to touch Ticket Manager
- Test in chat interface

### Adding New Actions
1. Add new action to Ticket Manager switch node
2. Update HTTP Request tool description
3. Update AI Agent system message with new rules

---

## Conclusion

This approach follows the **separation of concerns** principle and creates a maintainable, scalable architecture. The AI Agent focuses on conversation, the HTTP Request tool bridges to the API, and the Ticket Manager handles all business logic independently.
