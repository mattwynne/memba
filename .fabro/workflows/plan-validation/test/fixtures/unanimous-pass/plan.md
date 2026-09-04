# Export validated member message delivery receipts as CSV

Date: 2026-05-29
Status: eval-fixture

## Goal

Club operators can download a CSV report of delivery receipts for a single club message so they can reconcile who received or had delivery problems after sending an announcement.

The beneficiary is a club operator reviewing one already-sent club message.

## Background / Context

The application already records club messages, addressed recipients, one delivery record per recipient, member-facing receipt statuses, and provider-reported delivery/open/problem events. Operators currently have to inspect this information in the application. This iteration adds a narrow export affordance for the existing read model.

## Scope

### In scope

- Add a CSV download link on the existing message detail route at `/messages/:message_id`.
- Add a browser route `GET /messages/:message_id/delivery_receipts.csv` under the existing `[:browser, :club_member_required]` pipeline.
- Before exporting, verify that the requested message belongs to the active club resolved from the request; return 404 when it does not.
- Export one row for each addressed recipient delivery record for that message.
- Include exactly these CSV columns, in this order:
  - `message_id`
  - `message_subject`
  - `recipient_name`
  - `recipient_email`
  - `receipt_status`
  - `delivery_status`
  - `delivery_reason`
- Sort rows by `recipient_name` ascending, then `recipient_email` ascending.
- Use an empty string for `delivery_reason` when no reason has been recorded.
- Return 404 for an unknown `message_id`.
- Use RFC 4180-style CSV escaping: wrap fields containing commas, quotes, or newlines in double quotes and escape internal double quotes as two double quotes.

### Out of scope

- New authentication, authorization, or permissions machinery. This fixture deliberately relies on the existing browser pipeline access model: any user who can access the message detail page may download the same message's CSV receipts.
- Exports across multiple messages or clubs.
- Background jobs, email attachments, scheduled reports, or admin dashboards.
- Changing delivery status domain behaviour.
- Styling beyond a plain download link.

## Iteration Type

Behaviour-facing. This adds one operator-observable reporting behaviour: downloading delivery receipts for an already-sent club message.

## Acceptance Scenarios / Feature Files

Add or update `acceptance-tests/features/member_message_deliverability.feature` with stakeholder-readable scenarios for downloading a one-message delivery-receipts CSV, including delivered, problem, sent, non-addressed exclusion, ordering, unknown-message, and cross-club cases. Keep scenarios at the domain level; controller/export tests may provide lower-level CSV escaping coverage.

## Allowed acceptance feature changes

- `acceptance-tests/features/member_message_deliverability.feature`: add delivery-receipts CSV scenarios for the approved reporting behaviour; coverage is intentionally expanded and must remain green under `dev check`.

## Acceptance Criteria

- Given a message addressed to Alice, Bob, and Carol, when an operator downloads the CSV, then it contains one header row and exactly one data row per addressed recipient.
- The CSV columns are exactly `message_id,message_subject,recipient_name,recipient_email,receipt_status,delivery_status,delivery_reason`.
- Rows are sorted by recipient name ascending, then recipient email ascending.
- A delivered recipient has `receipt_status` of `delivered`, `delivery_status` of `delivered`, and an empty `delivery_reason`.
- A delayed, bounced, or spam-complaint recipient has `receipt_status` of `delivery problem`, the corresponding provider `delivery_status`, and the recorded provider reason.
- A recipient with no provider confirmation has `receipt_status` of `sent`, `delivery_status` of `sent`, and an empty `delivery_reason`.
- Non-addressed club members do not appear in the CSV.
- Requesting `/messages/:message_id/delivery_receipts.csv` for an unknown message returns 404.
- Requesting the CSV for a message that belongs to another club returns 404.
- The response has `text/csv` content type and an attachment `Content-Disposition`; export tests cover commas, double quotes, and newlines in CSV fields.
- `dev check` passes.

## Open Business Decisions

None.

## Implementation Plan

1. Add Phoenix controller coverage for `GET /messages/:message_id/delivery_receipts.csv` before implementation, including 404 for unknown and cross-club message IDs.
2. Add a focused CSV export module or context function that scopes the message to the active club, reads existing message delivery receipt data, joins the existing recipient-address projection for `recipient_email`, and returns rows in the specified order.
3. Add the CSV route under the existing `[:browser, :club_member_required]` pipeline; in the action, verify the message belongs to the active club and return the existing 404 response for a mismatch.
4. Add a download link from the message detail LiveView to the CSV route.
5. Ensure the export uses existing receipt/delivery read models only; do not add new domain events or commands.
6. Add tests for delivered, delivery problem, sent, non-addressed exclusion, ordering, blank reasons, unknown and cross-club message 404s, response headers, and RFC 4180 escaping.
7. Run `dev check`.

## Open Technical Decisions

None. Implement RFC 4180-style CSV escaping locally for this small fixed-column export; do not add a dependency.

## New Capability

An operator can download a deterministic CSV delivery receipt report for one already-sent club message.

## Validation Plan

- Run the focused controller/export tests.
- Manually create a message with delivered, problem, and sent recipients, download the CSV, and verify the columns, row count, ordering, statuses, reasons, and download headers. Verify that a cross-club message ID returns 404.
- Run `dev check`.
