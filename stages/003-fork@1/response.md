# Iteration Plan Review

## Decision: NOT READY

## Confidence: Medium

The plan has a clear goal, focused scope, and well-structured acceptance criteria. The implementation approach is sound. However, critical details about the HTTP response format and unvalidated data model assumptions create blocking gaps that would force the implementer to make significant decisions during implementation.

---

## Blocking Gaps

1. **HTTP response format not specified**: The plan doesn't define the CSV filename, Content-Type header, Content-Disposition header, or character encoding (should be UTF-8). An implementer cannot complete this feature without making these decisions.

2. **Data model assumptions not validated**: The plan assumes existing schemas contain `message_id`, `message.subject`, recipient details, and various delivery statuses (`delivered`, `delayed`, `bounced`, `spam-complaint`, `opened`, `sent`) with reasons. If these don't exist or are structured differently, the entire iteration is blocked.

3. **Empty recipients edge case not covered**: Acceptance criteria don't specify what happens when a message has zero addressed recipients (likely: header row only, but should be explicit).

---

## Non-Blocking Improvements

1. **CSV escaping edge cases**: While RFC 4180 is mentioned in the description, acceptance criteria could explicitly test recipient names containing commas, double quotes, and newlines.

2. **Module names not specified**: Implementation plan could name the controller (`MembaWeb.MessageController`?), export module (`Memba.Messages.DeliveryReceiptExport`?), and LiveView (`MembaWeb.MessageLive.Show`?).

3. **Multi-event behavior unclear**: If a recipient has multiple delivery events (e.g., sent then opened), which status wins? (Probably last/most recent, but should state it.)

4. **Stop condition implicit**: Validation plan is clear but could explicitly state "Iteration complete when all ACs pass and `dev check` succeeds."

---

## Smallest Viable Iteration

This plan is already minimal. Any reduction (e.g., supporting only `sent`/`delivered` statuses initially) would make it incomplete and not useful. The current scope is appropriate.

---

## Required Plan Edits

### 1. Add HTTP Response Acceptance Criteria

Insert after the existing ACs:

```markdown
- The HTTP response has Content-Type: text/csv; charset=utf-8
- The HTTP response has Content-Disposition: attachment; filename="message-{message_id}-delivery-receipts.csv"
- The CSV file is UTF-8 encoded
```

### 2. Add Empty Recipients Acceptance Criterion

Insert after the existing ACs:

```markdown
- A message with zero addressed recipients returns a CSV containing only the header row
```

### 3. Validate Data Model Assumptions

Insert at the start of the Implementation Plan:

```markdown
0. Confirm existing schemas support required fields:
   - Message has id and subject accessible
   - Recipients have name and email accessible  
   - Delivery events/receipts have status and reason fields
   - Statuses include: sent, delivered, delayed, bounced, spam-complaint, opened
   - If any field is missing or structured differently, stop and revise the plan
```

### 4. Clarify CSV Escaping in Acceptance Criteria

Add to the AC section:

```markdown
- Recipient names containing commas, double quotes, or newlines are correctly escaped per RFC 4180
```

---

## Validation Plan

After making the required edits:

1. **Confirm data model support**: Review relevant Ecto schemas to verify all required fields are accessible via existing associations/queries. If not, plan must be revised.

2. **Implement with tests**: Follow the test-first approach in the implementation plan.

3. **Manual verification**: Create a test message with:
   - Recipients with names containing commas and quotes
   - Mix of delivered, problem, opened, and sent statuses
   - At least one recipient with a non-empty delivery_reason
   - Download CSV and verify:
     - Filename format matches specification
     - Content-Type and Content-Disposition headers are correct
     - UTF-8 encoding is preserved for non-ASCII characters
     - All rows and columns match expectations

4. **Edge cases**: Test message with zero recipients returns header-only CSV.

5. **Quality gate**: `dev check` passes.

---

## Summary

This is a well-structured plan that's close to ready. The primary blocking issue is that critical HTTP response details are missing, and the data model assumptions need validation before implementation can proceed confidently. Making the four required edits will resolve all blocking gaps.

---

```json
{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"Medium","claude_review_blocking_gap_count":3,"claude_review_blocking_gaps":"HTTP response format (headers, filename, encoding) not specified; Data model assumptions not validated; Empty recipients edge case not in acceptance criteria","claude_review_required_edits":"Add HTTP response AC (Content-Type, Content-Disposition, UTF-8 encoding); Add empty recipients AC; Validate data model has required fields before implementation; Add CSV escaping edge case to AC"}}
```