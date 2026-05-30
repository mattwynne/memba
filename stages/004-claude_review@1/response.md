# Plan Review Report

## Decision: NOT READY

## Confidence: High

## Blocking gaps

1. **Authentication and access control undefined**: The plan explicitly excludes "Authentication, authorization, and permissions" from scope, but does not state how the CSV endpoint will be protected. Delivery receipt data is likely sensitive (contains email addresses and delivery statuses). The plan should clarify:
   - Will the route rely on existing browser pipeline authentication?
   - Are there additional authorization checks needed (e.g., can any authenticated user download receipts for any message)?
   - If intentionally public, explain why and acknowledge security implications.

## Non-blocking improvements

1. **CSV escaping specification unclear**: The plan references "Elixir's standard CSV escaping rules" but Elixir's standard library doesn't include CSV functionality. Should specify RFC 4180 or the specific escaping algorithm to implement (escaping internal quotes, wrapping fields containing commas/newlines in double quotes).

2. **Status precedence logic implicit**: Acceptance criteria state "exactly one data row per addressed recipient" but don't explicitly define how the single status is determined when multiple delivery events exist for one recipient (e.g., delivered, then opened). This is probably based on latest event or priority, but could be stated explicitly.

3. **Module and file names not specified**: Implementation plan could name the specific controller (new or existing), CSV export module path/name, and which LiveView file to modify for the download link.

4. **Empty recipient edge case**: Not clear what happens if a message has zero addressed recipients (likely: CSV with header row only, but could be stated).

## Smallest viable iteration

The current scope is already minimal and well-focused:
- Single message CSV export (not batch)
- Fixed columns, deterministic ordering
- Simple download link from existing detail view
- No new domain events or persistence
- Explicit exclusions are appropriate

This is the right size.

## Required plan edits

1. **Add authentication statement** to implementation plan or out-of-scope section. Either:
   - "Route will use existing browser pipeline authentication; authenticated users can download any message's receipts" (if that's the intent), OR
   - "Route will use browser pipeline authentication; add authorization check to ensure user can access the specific message" (if authorization is needed), OR
   - State explicitly if endpoint is intentionally public and why

2. **Clarify CSV escaping approach** in the technical decisions or implementation plan: "Implement RFC 4180 CSV escaping: escape internal double quotes as double-double-quotes, wrap fields containing commas/newlines/quotes in double quotes."

## Validation plan

The existing validation plan is sound:
- Run focused controller/export tests covering delivered, delivery problem, opened, sent states, ordering, non-addressed exclusion, and 404 for unknown message
- Manual verification: create test message with diverse recipient states, download CSV, verify columns, row count, ordering, statuses, and reasons match specification
- Run `dev check`

After blocking gap is resolved, this plan will be ready for implementation.

{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":1,"claude_review_blocking_gaps":"Authentication and access control undefined for CSV endpoint","claude_review_required_edits":"Add explicit authentication/authorization statement; Clarify CSV escaping specification (RFC 4180)"}}