# Iteration Plan Review

## Decision: NOT READY

## Confidence: Medium

## Blocking Gaps

1. **No specification for null/empty recipient data handling** - The acceptance criteria specify how to populate `receipt_status`, `delivery_status`, and `delivery_reason` fields, but do not specify what happens when `recipient_name` or `recipient_email` values are null or empty in the source data. This affects the data contract and test cases. Should null names render as empty string, "Unknown", or something else?

## Non-blocking Improvements

1. **CSV file download name not specified** - For consistency and user experience, specify the filename (e.g., `delivery_receipts_{message_id}_{timestamp}.csv` or `message_{message_id}_receipts.csv`)

2. **Character encoding not explicit** - While UTF-8 is standard, state it explicitly in acceptance criteria

3. **HTTP headers not specified** - Content-Type (`text/csv; charset=utf-8`) and Content-Disposition headers should be in acceptance criteria for the download to work correctly

4. **Implementation step 1 phrasing unclear** - "Add Phoenix controller coverage for GET route before implementation" should clarify whether this means "write test first" or "add tests alongside implementation"

5. **Module organization vague** - "focused CSV export module or context function" leaves the implementer to choose. Specify whether this lives in the Messages context, a dedicated export module, or as a controller helper

6. **Missing edge case: message with zero addressed recipients** - While implied by "one data row per addressed recipient," explicitly state the expected behavior (header row only, no data rows)

## Smallest Viable Iteration

This iteration is already minimal - it's focused on a single CSV export endpoint for one message. It could not be meaningfully smaller while remaining useful. The only reduction would be to omit the LiveView download link and only expose the HTTP endpoint, but that would reduce discoverability.

## Required Plan Edits

Add to acceptance criteria:

- "When `recipient_name` is null or empty, the CSV contains an empty string in the `recipient_name` column"
- "When a message has zero addressed recipients, the CSV contains only the header row"
- "The CSV file downloads with filename `message_{message_id}_delivery_receipts.csv`"
- "The response has Content-Type `text/csv; charset=utf-8` and appropriate Content-Disposition header"

Clarify implementation step 2:

- Change "Add a focused CSV export module or context function" to specify either "Add `Memba.Messages.export_delivery_receipts_csv/1` function" or "Add `Memba.Messages.DeliveryReceipts.to_csv/1` module and function" (whichever matches project conventions)

## Validation Plan

The existing validation plan is adequate:
- Run focused controller and export tests covering all specified scenarios
- Manual verification with realistic test data including null/empty names
- Run `dev check`

Add to manual verification:
- Verify filename and download headers in browser
- Verify character encoding with non-ASCII characters in names/subjects

{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"Medium","claude_review_blocking_gap_count":1,"claude_review_blocking_gaps":"No specification for null/empty recipient_name or recipient_email CSV representation","claude_review_required_edits":"Add AC for null/empty recipient data handling; Add AC for zero-recipient case; Add AC for filename and headers; Specify exact module/function location"}}