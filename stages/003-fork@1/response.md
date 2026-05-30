# Plan Validation Review - Claude

## Decision: NOT READY

## Confidence: High

## Blocking gaps

1. **Authentication and authorization undefined**: The out-of-scope section lists "Authentication, authorization, and permissions" but this creates a security gap. Who can download delivery receipts? This is personal data (email addresses, names). Is the endpoint public, operator-only, club-admin-only, or message-sender-only? This must be decided and acceptance criteria must cover unauthorized access attempts.

2. **Status precedence not specified**: If a recipient's delivery status progresses from `sent` → `delivered` → `opened`, which status appears in the CSV? The acceptance criteria describe four separate status mappings but don't define which takes precedence when multiple events exist for one recipient.

3. **CSV escaping specification missing**: The plan says "use Elixir's standard CSV escaping rules" but Elixir has no standard library CSV module. The escaping/quoting rules must be specified (RFC 4180 compliant? Custom escaping for commas, quotes, newlines?). Without this, implementations will vary and tests will be ambiguous.

4. **Content-Type and filename not specified**: Acceptance criteria omit the HTTP headers required for a download (Content-Type: text/csv, Content-Disposition with filename). Without these, browsers may display CSV as text rather than prompting download, and the filename will be generic.

## Non-blocking improvements

1. Empty recipient list edge case: What CSV is returned if a message has zero addressed recipients? Empty file? Header-only file?

2. Implementation step 1 contradicts test-first: Step 1 says "Add Phoenix controller coverage...before implementation" but step 3 says "Add the CSV route" without tests. Clarify: write controller test first, then implement controller, or vice versa?

3. Data source vague: "existing receipt/delivery read models" is undefined. Name the Ecto schema(s) or context function(s) that hold this data.

4. Missing file/module names: Which controller module (e.g., `MembaWeb.MessageController`)? Which export module (e.g., `Memba.Messages.DeliveryReceiptExport`)? Which router file section?

5. Multiple events per recipient: If a recipient has bounced after being delivered, or has a spam complaint after opening, which status and reason appear? The "delivery problem" criteria says "delayed, bounced, or spam-complaint" but doesn't address progression.

## Smallest viable iteration

The current scope is already small and coherent. Do not reduce further. Instead, resolve the blocking gaps before starting implementation.

## Required plan edits

1. **Add authentication/authorization decision**: Under "Open Business Decisions" or in acceptance criteria, specify who can download delivery receipts and add acceptance criterion: "Requesting the CSV without [operator/admin/sender] authorization returns 403 Forbidden."

2. **Define status precedence**: Add a business decision or acceptance criterion stating: "If a recipient has multiple delivery events, the CSV shows the most recent/advanced status in order: opened > delivery problem > delivered > sent" (or whichever precedence rule applies).

3. **Specify CSV escaping**: Replace "Elixir's standard CSV escaping rules" with "RFC 4180 CSV escaping: fields containing comma, quote, or newline are quoted; quotes within fields are escaped as double-quotes" or the actual escaping rule to be implemented.

4. **Add HTTP header criteria**: Add acceptance criterion: "The response has Content-Type: text/csv and Content-Disposition: attachment; filename=message-{message_id}-delivery-receipts.csv."

5. **Clarify test-first ordering**: Rewrite step 1 as "Write controller tests for GET /messages/:message_id/delivery_receipts.csv covering success, 404, and authorization" and move route/controller implementation to step 3.

6. **Name implementation targets**: In step 2, specify the module (e.g., "Add `Memba.Messages.DeliveryReceiptExport`"). In step 3, specify the controller action (e.g., "Add `MembaWeb.MessageController.delivery_receipts_csv/2`"). In step 4, specify the LiveView file and template change.

7. **Add empty recipient case**: Add acceptance criterion: "A message with zero addressed recipients returns a CSV with only the header row."

## Validation plan

After the required edits are made and implementation is complete:

1. **Run focused automated tests**: Execute controller tests covering successful CSV download, column headers and values, row ordering, status mappings (delivered, opened, sent, delivery problem with all three types), empty delivery_reason, non-addressed exclusion, empty recipient list, unknown message 404, and unauthorized access 403.

2. **Manual CSV verification**: Create a test message with at least one recipient in each status category (delivered, opened, sent, delayed, bounced, spam complaint) plus one non-addressed club member. Download the CSV and verify:
   - Correct filename in browser
   - Correct column headers
   - Correct row count (addressed recipients only)
   - Correct sort order (name asc, email asc)
   - Correct status/reason for each recipient category
   - CSV opens correctly in spreadsheet software

3. **Manual authorization test**: Attempt to download delivery receipts as an unauthorized user and verify 403 response.

4. **Run `dev check`**: Ensure all tests, linters, formatters, and type checks pass.

---

**Artifact written to:** `.fabro/workflows/plan-validation/review-output/claude.md`

```json
{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":4,"claude_review_blocking_gaps":"Authentication/authorization undefined; Status precedence not specified; CSV escaping specification missing; Content-Type and filename not specified","claude_review_required_edits":"Add authentication/authorization decision and criteria; Define status precedence rule; Specify CSV escaping format (RFC 4180 or custom); Add HTTP header acceptance criteria; Clarify test-first step ordering; Name implementation modules/files; Add empty recipient edge case"}}
```