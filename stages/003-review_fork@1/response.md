# Iteration Plan Review

## Decision: NOT READY

## Confidence: High

## Blocking gaps

1. **Missing authorization acceptance criterion** - The plan mentions in "Out of scope" that it relies on existing browser pipeline access, but there's no acceptance criterion testing what happens when a user requests a CSV for a message they cannot access. Authorization behavior must be explicit in acceptance criteria, not just assumed.

2. **Implementation plan lacks specific file/module names** - The plan says to "add Phoenix controller coverage" and "add a focused CSV export module" but doesn't name them. Per the guidelines to "name likely files, modules, migrations, tests, interfaces, and integration points where useful," a ready-for-implementation plan should specify:
   - Which controller gets the new action
   - The action name
   - The CSV export module name and location
   - Which LiveView file gets the download link
   - Which test files get new coverage

3. **HTTP response headers not specified** - The plan doesn't specify the Content-Type or Content-Disposition headers, which determine whether the browser downloads the file and what it's named. These are user-facing technical details that must be decided before implementation.

4. **CSV filename format not specified** - The acceptance criteria don't state what the downloaded file should be named (e.g., `message-123-delivery-receipts.csv` or `delivery-receipts-2024-01-15.csv`). This is a user-facing detail that should be decided.

## Non-blocking improvements

1. Could specify exact test file paths (e.g., `test/memba_web/controllers/message_controller_test.exs`)
2. Could include example CSV output in acceptance criteria for clarity
3. Could make manual validation plan more specific (e.g., "verify header row matches exactly, verify status transitions, verify RFC 4180 escaping")
4. Could specify response status code (presumably 200) in acceptance criteria

## Smallest viable iteration

The current plan is already appropriately sized - a single-message CSV export is the smallest useful slice. Any smaller (e.g., just delivered recipients) wouldn't meet the stated goal of providing a complete delivery report.

## Required plan edits

1. **Add authorization acceptance criterion:** "Requesting `/messages/:message_id/delivery_receipts.csv` when the user cannot access message `:message_id` returns 404 or redirects per existing authorization rules."

2. **Name the controller and action:** Specify in implementation plan that the route maps to `MembaWeb.MessageController.download_delivery_receipts/2` (or similar based on existing controller structure).

3. **Name the CSV export module:** Specify creating `Memba.Messages.DeliveryReceiptExport` or adding a function to an existing messages context module. State the module location explicitly.

4. **Name the LiveView file:** Specify which LiveView file gets the download link (likely `MembaWeb.MessageLive.Show` or similar).

5. **Specify HTTP headers:** Add to acceptance criteria or implementation plan:
   - Content-Type: `text/csv; charset=utf-8`
   - Content-Disposition: `attachment; filename="message-{message_id}-delivery-receipts.csv"` (or decide on different filename format)

6. **Specify CSV filename format:** Add to acceptance criteria the exact filename format, e.g., "The downloaded file is named `message-{message_id}-delivery-receipts.csv`"

7. **Name test files:** Specify that controller tests go in `test/memba_web/controllers/message_controller_test.exs` and CSV export unit tests go in `test/memba/messages/delivery_receipt_export_test.exs` (or wherever is appropriate).

## Validation plan

**Automated:**
- New controller test coverage verifies all acceptance criteria
- CSV export unit tests verify column headers, row content, sorting, escaping, and status mapping
- Integration test verifies download link presence and route accessibility
- `dev check` passes with no new warnings

**Manual:**
1. Create a test message with recipients in all states (delivered, delayed, bounced, spam, opened, sent)
2. Access message detail page and click download link
3. Verify CSV downloads with correct filename
4. Verify CSV has exactly one header row and one row per addressed recipient
5. Verify columns match exactly: `message_id,message_subject,recipient_name,recipient_email,receipt_status,delivery_status,delivery_reason`
6. Verify rows are sorted by recipient name ascending, then email ascending
7. Verify each status maps correctly per acceptance criteria
8. Verify RFC 4180 escaping (test recipient with comma in name, quote in subject)
9. Verify non-addressed members are excluded
10. Attempt to download CSV for another club's message - verify 404 or redirect

**Success criteria:**
All automated tests pass, manual verification confirms all acceptance criteria, and `dev check` is clean.

---

```json
{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":4,"claude_review_blocking_gaps":"Missing authorization acceptance criterion; Implementation plan doesn't name specific files/modules/controllers; HTTP response headers not specified; CSV filename format not specified","claude_review_required_edits":"Add authorization AC for inaccessible messages; Name controller, action, CSV module, LiveView file, and test files; Specify Content-Type and Content-Disposition headers; Specify CSV filename format"}}
```