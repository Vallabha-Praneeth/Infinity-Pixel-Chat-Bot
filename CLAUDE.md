# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains n8n workflow definitions and test harnesses for a RAG-powered customer service chatbot integrated with an Airtable-based ticket management system. The main components are:

- **RAG Workflow** (`RAG Workflow For( Customer service chat-bot).json`): An AI agent workflow that uses Pinecone vector store, Google Drive document loaders, and an AI agent to handle customer service conversations. The agent can trigger ticket operations (create/status/update/close) via a tool call to the Ticket Manager workflow.

- **Ticket Manager Workflow** (`Ticket Manager (Airtable).json`): A subworkflow that handles all ticket CRUD operations via Airtable. Routes requests based on `action` parameter (create/status/update/close) and enforces business rules like blocking updates to closed tickets or rejecting empty update text.

## Workflow Architecture

### RAG Workflow
- Triggered by chat messages (`When chat message received`)
- Downloads and processes documents from Google Drive
- Uses Pinecone for vector embeddings and retrieval
- AI Agent can invoke the Ticket Manager via a tool call with parameters: `action`, `ticketId`, `name`, `email`, `subject`, `description`, `priority`

### Ticket Manager Workflow (Action-Based Routing)
1. **Normalize Inputs**: Pulls parameters from body/webhook/query; sets defaults
2. **Action Switch**: Routes to create/status/update/close branches based on `action` field
3. **Create Branch**:
   - Generates unique Ticket ID (format: `TCK-{timestamp}-{random}`)
   - Calculates SLA due dates based on priority
   - Writes record to Airtable
4. **Status Branch**:
   - Finds ticket by Ticket ID in Airtable
   - Returns current status, subject, internal notes
5. **Update Branch**:
   - **Blocks** if `description` is empty (prompts user for details)
   - **Blocks** if ticket status is closed/resolved (prompts user to reopen or create new ticket)
   - Otherwise appends to Conversation Log, updates Updated At timestamp
   - Uses conditional IF node (`IF - Should Update`) to bypass Airtable write when blocked
6. **Close Branch**:
   - Finds ticket by Ticket ID
   - Sets status to "closed"
   - Updates record in Airtable

### Airtable Schema
- Primary table: Tickets
- Key fields: Ticket ID (unique), Status, Priority, Subject, Description, Conversation Log, Created At, Updated At, SLA Due, Internal Notes
- Status values: open, in-progress, closed, resolved

## Testing Commands

Set environment variables before running tests:
```bash
export N8N_WEBHOOK_BASE="https://your-n8n-instance"
export N8N_TICKET_WEBHOOK_PATH="/webhook/tt"  # or your webhook path
export AUTH_HEADER="Authorization: Bearer XXX"  # optional if auth required
```

### Individual Test Scripts
- `./test_create.sh` - Creates a sample ticket and extracts the ticket ID
- `./test_status.sh <ticketId>` - Checks status of an existing ticket

### Comprehensive Test Suite
- `./all_test.sh` - Runs full scenario test:
  1. Create ticket
  2. Check status
  3. Update ticket with text
  4. Try update without text (should block with prompt)
  5. Close ticket
  6. Try update after close (should block with error message)

All tests use `curl` and `jq` to make webhook calls and parse JSON responses.

## Known Issues and Current Work

From `summary_till_now.md`:
- **Close operation bug**: The close endpoint sometimes returns a stale ticket ID instead of the current one. This suggests pinned/sample data may be enabled on the close branch nodes in n8n, or the close response is reading from the wrong execution item.
- **Fix approach**: Clear pinned data from `Airtable - Find Ticket (Close)` and `Code - Prepare Close` nodes; ensure `Build Close Response` uses the current item from the find-close step.

## File Naming and Organization

- Workflow JSON files: descriptive names with spaces (existing convention)
- Test scripts: `test_*.sh` (executable, POSIX shell)
- Documentation: kebab-case markdown (e.g., `summary_till_now.md`)
- Data exports: snake_case CSV (e.g., `airtable_tickets_template.csv`)

## Development Notes

- **n8n workflows**: Edit workflows in the n8n UI at the webhook base URL, then export as JSON to this repo.
- **Testing changes**: After modifying workflows, re-export JSON and run `./all_test.sh` to validate all actions still work correctly.
- **Airtable find operations**: Always use `operation: search` with `filterByFormula: {Ticket ID}='{{$json.ticketId}}'` and `maxRecords: 1` to ensure exact ticket matching.
- **Update branch validation**: The IF node checks for empty text and closed status BEFORE writing to Airtable to prevent data integrity issues.
- **No build system**: This is a workflow/documentation repository. New scripts should be portable POSIX shell with clear usage comments.

## Reference Materials

- `Overview of Ticket Workflow Integration.pdf` - High-level process overview
- `Ticket Manager Workflow Review and Recommendations.pdf` - Detailed review with multi-table schema recommendations
- `ticket_manager_research_full.pdf` - Research notes
- `updates.md` / `summary_till_now.md` - Session logs tracking changes and test results
- `AGENTS.md` - General repository guidelines (superseded by this file for workflow-specific guidance)
