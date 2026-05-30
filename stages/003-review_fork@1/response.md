# Iteration Plan Review: Download message delivery receipt report as CSV

## Decision: NOT READY

## Confidence: High

The plan is well-structured and nearly ready, but has two blocking gaps in the acceptance criteria that must be resolved before implementation.

---

## Blocking Gaps

1. **Missing acceptance criteria for CSV escaping edge cases**
   
   The scope explicitly requires "RFC 4180-style CSV escaping: wrap fields containing commas, quotes, or newlines in double quotes and escape internal double quotes as two double quotes." The technical decision states this will be implemented locally, yet the acceptance criteria contain no test cases for fields requiring escaping.
   
   Critical missing test cases:
   - Message subject containing a comma
   - Message subject containing a double quote  
   - Recipient name containing special characters
   - Delivery reason containing a newline
   
   Without these tests, the core CSV escaping requirement cannot be verified.

2. **Ambiguous or missing authorization acceptance criterion**
   
   The acceptance criterion "Requesting `/messages/:message_id/delivery_receipts.csv` for an unknown message returns 404" is ambiguous. Does "unknown message" mean:
   - Message ID doesn't exist in the database?
   - Message exists but current user lacks access permission?
   - Both cases?
   
   The scope states "any user who can access the message detail page may download the same message's CSV receipts," but there's no acceptance criterion verifying this authorization behavior for the new endpoint.

---

## Non-Blocking Improvements

1. **Manual validation plan should explicitly test CSV escaping**: The validation plan says to "verify the columns, row count, ordering, statuses, and reasons" but doesn't mention testing special characters in field values.

2. **Implementation plan could be more specific about module placement**: Step 2 says "Add a focused CSV export module or context function" but doesn't specify whether this goes in the Messages context, a dedicated CSVExport module, or as a private function in the controller.

3. **Missing edge case: empty recipient list**: What happens if a message has no addressed recipients? Does the CSV contain just a header row, or does it return an error? This scenario isn't covered.

4. **Missing edge case: NULL message subject**: The acceptance criteria don't specify how NULL or empty message subjects should be rendered in the CSV.

5. **Character encoding not specified**: While likely UTF-8 by default, the plan could explicitly state the CSV encoding.

6. **Link presentation not specified**: Acceptance criteria don't state what the download link should say or exactly where it appears on the message detail page.

---

## Smallest Viable Iteration

The current scope is appropriately sized and focused. The iteration cannot be meaningfully reduced while remaining useful - operators need to export all delivery statuses (delivered, problem, opened, sent) to make the report valuable.

No reduction recommended.

---

## Required Plan Edits

### 1. Add CSV escaping acceptance criteria

Insert after the existing acceptance criteria:

- "A message subject containing a comma (e.g., 'Hello, World') is properly quoted in the CSV output."
- "A message subject containing a double quote (e.g., 'The \"Big\" Game') has the quote escaped as two double quotes in the CSV output."  
- "A delivery reason containing a newline character is properly quoted in the CSV output."
- "A recipient name containing special characters is properly escaped according to RFC 4180."

### 2. Clarify authorization acceptance criterion

Replace:
- "Requesting `/messages/:message_id/delivery_receipts.csv` for an unknown message returns 404."

With two separate criteria:
- "Requesting `/messages/:message_id/delivery_receipts.csv` for a nonexistent message ID returns 404."
- "Requesting `/messages/:message_id/delivery_receipts.csv` for a message the current user cannot access returns 404 (respects the same authorization as the message detail page)."

Or if authorization is truly considered covered by existing infrastructure, at minimum add:
- "The CSV download endpoint requires the same permissions as viewing the message detail page."

### 3. Update manual validation plan

Change:
- "Manually create a message with delivered, problem, opened, and sent recipients, download the CSV, and verify the columns, row count, ordering, statuses, and reasons."

To:
- "Manually create a message with delivered, problem, opened, and sent recipients, **where the subject contains a comma and a double quote**, download the CSV, and verify the columns, row count, ordering, statuses, reasons, **and proper CSV escaping of special characters**."

### 4. Optional: Specify CSV export module location

In implementation plan step 2, change:
- "Add a focused CSV export module or context function that reads existing message delivery receipt data and returns rows in the specified order."

To:
- "Add a CSV export function in the Messages context (e.g., `Messages.export_delivery_receipts_csv/1`) that reads existing message delivery receipt data and returns rows in the specified order."

---

## Validation Plan

### Automated tests must verify:
- All current acceptance criteria (delivered, problem, opened, sent statuses; ordering; non-addressed exclusion; 404 on nonexistent message)
- **NEW**: CSV escaping for commas, quotes, and newlines in field values
- **NEW**: Authorization behavior (unauthorized access returns 404)
- `dev check` passes

### Manual verification must include:
1. Create a test message with:
   - Subject containing comma, double quote, and newline: `"Test, \"Message\"\nLine 2"`
   - Recipients with all status types (delivered, problem, opened, sent)
   - At least one non-addressed club member
2. Download the CSV as an authorized user
3. Verify:
   - Subject is properly escaped in CSV
   - All columns present and correctly ordered  
   - Row count matches addressed recipients only
   - Sorting is correct (name asc, then email asc)
   - All status mappings are correct
4. Attempt to download the CSV as an unauthorized user (if applicable) and verify access is denied
5. Run `dev check` and verify it passes

### Success criteria:
- All automated tests pass
- Manual verification confirms correct CSV escaping, content, and authorization
- No regressions detected by `dev check`
- One message's delivery receipts can be downloaded as a valid RFC 4180 CSV file

---

```json
{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":2,"claude_review_blocking_gaps":"No acceptance criteria for CSV escaping edge cases (commas, quotes, newlines); Authorization acceptance criterion is ambiguous (does not clearly test unauthorized access)","claude_review_required_edits":"Add acceptance criteria for CSV escaping with commas, quotes, and newlines; Clarify or add acceptance criterion for unauthorized access returning 404; Update manual validation to test CSV escaping"}}
```