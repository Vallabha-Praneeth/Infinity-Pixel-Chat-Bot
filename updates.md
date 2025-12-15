# Updates Log

## Session: RAG + Ticket Manager robustness (2024-12-01)
1) Initial state
- Repo contained RAG workflow (`RAG Workflow For( Customer service chat-bot).json`), ticket subworkflow (`Ticket Manager (Airtable).json`), and research PDFs (ticket_manager_research_full.pdf, overview/review PDFs).
- Tool node in RAG workflow only exposed create fields (name/email/subject/description/priority) and its description said “only create”. Ticket Manager defaulted action to `create`, and Airtable find nodes used broad `list/search` without ticket filtering.

2) Findings/gaps
- Agent prompt expected status/update/close, but tool couldn’t pass `action`/`ticketId`, so non-create intents were unreachable.
- Airtable find nodes didn’t filter by Ticket ID; updates/close could hit wrong or first records.
- Update path reopened closed tickets and allowed empty updates; single-table model lacked history separation; SLA follow-ups absent.

3) Changes applied
- RAG workflow tool node: description now covers create/status/update/close; added `action` and `ticketId` to schema and value mapping so the agent can call any action.
- Ticket Manager workflow:
  - Normalize Inputs now includes `action`/`ticketId`; Action Switch routes on provided action.
  - Airtable find nodes now use `operation: search` with `filterByFormula {Ticket ID}='{{$json.ticketId}}'` and `maxRecords: 1`.
  - Update branch rewritten to:
    - Block when no update text: returns prompt asking for details.
    - Block when status is closed/resolved: returns “cannot update, please reopen/new ticket”.
    - Preserve record ID/fields; avoid implicit reopen.
  - Added IF - Should Update node: blocked updates bypass Airtable writes and go straight to response; valid updates proceed to Airtable update then build response.
  - Airtable Update mapping constrained to record ID, Conversation Log, Status, Priority, Updated At, Internal Notes with `ignoreEmpty: true`.

4) Validation guidance
- Test in n8n manual runs (or webhook harness):
  - create: action=create with full fields → record created, SLA due set.
  - status: action=status + ticketId → found/not_found messaging.
  - update: action=update + ticketId + text → log append and Updated At; missing text → prompt; closed/resolved → cannot-update message (no write).
  - close: action=close + ticketId → status closed; already-closed message.
  - Priority edges: low/high SLA offsets; long descriptions formatting in Conversation Log.

5) Open follow-ups (not yet implemented)
- Optional: add reopen flow instead of blocking closed/resolved updates; add SLA monitoring/escalation; consider multi-table schema (Tickets, Customers, Agents, Ticket Updates) per research doc.***

## Tests (2024-12-01)
- Webhook used: https://polarmedia.app.n8n.cloud/webhook/tt
- `test_create.sh`: PASS — ticket `TCK-1764655293180-701` created; response returned with status open and subject/description.
- `test_status.sh TCK-1764655293180-701`: PASS — response included ticketId/status/subject/internalNotes.
- `all_test.sh`: update step FAILED — webhook returned empty body; update branch lacks Respond-to-Webhook connection (only Slack). Status/close may also lack explicit response wiring.

## Outstanding gaps after tests
- Connect Respond to Webhook for update/close (and ensure status/create also fan out) from each Build * Response node so HTTP callers get JSON while Slack remains in parallel.
- SLA monitoring/escalation still not implemented; still single-table design (no Customers/Agents/Ticket Updates tables) per review doc.
