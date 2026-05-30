# Iteration Plan Review

## Decision: NOT READY

## Confidence: High

The plan is well-structured, focused, and nearly ready, but has specific gaps in the acceptance criteria that would lead to implementation variance or incomplete testing.

## Blocking Gaps

1. **Missing CSV escaping acceptance criterion**: The context explicitly requires "RFC 4180-style CSV escaping: wrap fields containing commas, quotes, or newlines in double quotes and escape internal double quotes as two double quotes," but no acceptance criterion tests this behavior. Without this, the implementer might forget to verify escaping works correctly.

2. **HTTP response headers unspecified**: The acceptance criteria verify CSV content but not download behavior. Missing specification for Content-Type (text/csv), Content-Disposition (attachment with filename), and filename format. Different implementers could produce different download experiences.

3. **Null/empty field handling unclear**: The acceptance criteria don't specify what happens when `recipient_name` or `message_subject` is NULL or empty. Should these be empty strings, "N/A", or something else?

4. **Zero recipients edge case unspecified**: What should the CSV contain if a message has zero addressed recipients? Just the header row? Empty file? 404? This should be explicit.

## Non-Blocking Improvements

1. Implementation step 2 says "Add a focused CSV export module or context function" but doesn't specify the module name, context, or function signature. Suggest: `Memba.Messages.export_delivery_receipts/1` or `Memba.Messages.DeliveryReceiptExporter.generate/1`.

2. Controller name not specified. Suggest: `MembaWeb.MessageDeliveryReceiptController` or clarify if this is a function in an existing controller.

3. Character encoding not specified (UTF-8 assumed but should be explicit).

4. LiveView file to modify not named (should specify which message detail LiveView).

5. Add test file names to implementation plan for clarity.

## Smallest Viable Iteration

The current iteration is already minimal and appropriately scoped. All components (route, controller, export logic, download link, tests) are necessary for the feature to be useful. Do not reduce further.

## Required Plan Edits

### Add to Acceptance Criteria (after existing criteria):

1. **CSV escaping**: "A message subject or recipient name containing a comma, double quote, or newline is correctly escaped in the downloaded CSV per RFC 4180 (wrapped in quotes, internal quotes doubled)."

2. **HTTP headers**: "The HTTP response has Content-Type header 'text/csv; charset=utf-8' and Content-Disposition header 'attachment; filename=\"message-{message_id}-delivery-receipts.csv\"' where {message_id} is the message ID."

3. **Null handling**: "When recipient_name or message_subject is NULL or empty, the corresponding CSV field is an empty string (two adjacent commas or comma-quote-quote-comma)."

4. **Zero recipients**: "A message with zero addressed recipients returns a CSV containing only the header row."

### Modify Implementation Plan Step 2:

Change from:
> "Add a focused CSV export module or context function that reads existing message delivery receipt data and returns rows in the specified order."

To:
> "Add `Memba.Messages.export_delivery_receipts/1` function (or create `Memba.Messages.DeliveryReceiptExporter` module with `generate/1`) that reads message recipients via existing Ecto queries, maps delivery statuses to receipt statuses, sorts by name then email, and returns RFC 4180-compliant CSV rows."

### Modify Implementation Plan Step 4:

Change from:
> "Add a download link from the message detail LiveView to the CSV route."

To:
> "Add a download link from the message detail LiveView (specify file: e.g., `lib/memba_web/live/message_live/show.ex`) to the CSV route using `<.link href={~p"/messages/#{@message}/delivery_receipts.csv"}>Download CSV</.link>`."

## Validation Plan

The existing validation plan is good but should be enhanced:

1. **Run controller/export tests** covering:
   - All specified statuses (delivered, delivery problem, opened, sent)
   - CSV escaping (comma, quote, newline in subject and names)
   - HTTP headers (Content-Type, Content-Disposition, filename format)
   - Null/empty field handling
   - Zero recipients
   - Non-addressed exclusion
   - Sorting order
   - Unknown message 404

2. **Manual verification**:
   - Create message with recipients having: delivered, bounced, opened, sent statuses
   - Include recipient with comma in name (e.g., "Smith, John")
   - Include message subject with quotes (e.g., He said "hello")
   - Download CSV and verify:
     - File downloads with correct filename
     - Opens correctly in Excel/Google Sheets
     - All columns present and correctly ordered
     - Rows sorted correctly
     - Special characters properly escaped
     - Status mappings accurate

3. **Run `dev check`** and ensure all linter, formatter, and test suite checks pass.

4. **Verify the download link appears** on the message detail page and produces the expected CSV when clicked.

---

```json
{
  "context_updates": {
    "claude_review_decision": "NOT READY",
    "claude_review_confidence": "High",
    "claude_review_blocking_gap_count": 4,
    "claude_review_blocking_gaps": "Missing CSV escaping acceptance criterion; HTTP headers unspecified (Content-Type, Content-Disposition, filename); Null/empty field handling unclear; Zero recipients edge case unspecified",
    "claude_review_required_edits": "Add acceptance criteria for CSV escaping with special chars; Add acceptance criteria for HTTP response headers and filename format; Add acceptance criteria for null/empty field handling; Add acceptance criteria for zero recipients case; Specify module/function name in implementation step 2"
  }
}
```