# Export validated member message delivery receipts as CSV

Date: 2026-05-29
Status: eval-fixture

## Goal

Club operators can download a CSV report of delivery receipts for a single club message so they can reconcile who received, opened, or had delivery problems after sending an announcement.

The beneficiary is a club operator reviewing one already-sent club message.

## Background / Context

The application already records club messages, addressed recipients, one delivery record per recipient, member-facing receipt statuses, and provider-reported delivery/open/problem events. Operators currently have to inspect this information in the application. This iteration adds a narrow export affordance for the existing read model.

## Scope

### In scope

- Add a CSV download link on the existing message detail route at `/messages/:message_id`.
- Add a browser route `GET /messages/:message_id/delivery_receipts.csv` under the existing browser pipeline.
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

## Acceptance Criteria

- Given a message addressed to Alice, Bob, and Carol, when an operator downloads the CSV, then it contains one header row and exactly one data row per addressed recipient.
- The CSV columns are exactly `message_id,message_subject,recipient_name,recipient_email,receipt_status,delivery_status,delivery_reason`.
- Rows are sorted by recipient name ascending, then recipient email ascending.
- A delivered recipient has `receipt_status` of `delivered`, `delivery_status` of `delivered`, and an empty `delivery_reason`.
- A delayed, bounced, or spam-complaint recipient has `receipt_status` of `delivery problem`, the corresponding provider `delivery_status`, and the recorded provider reason.
- An opened recipient has `receipt_status` of `opened`, `delivery_status` of `opened`, and an empty `delivery_reason`.
- A recipient with no provider confirmation has `receipt_status` of `sent`, `delivery_status` of `sent`, and an empty `delivery_reason`.
- Non-addressed club members do not appear in the CSV.
- Requesting `/messages/:message_id/delivery_receipts.csv` for an unknown message returns 404.
- `dev check` passes.

## Open Business Decisions

None.

## Implementation Plan

1. Add Phoenix controller coverage for `GET /messages/:message_id/delivery_receipts.csv` before implementation.
2. Add a focused CSV export module or context function that reads existing message delivery receipt data and returns rows in the specified order.
3. Add the CSV route under the browser pipeline.
4. Add a download link from the message detail LiveView to the CSV route.
5. Ensure the export uses existing receipt/delivery read models only; do not add new domain events or commands.
6. Add tests for delivered, delivery problem, opened, sent, non-addressed exclusion, ordering, blank reasons, and unknown message 404.
7. Run `dev check`.

## Open Technical Decisions

None. Implement RFC 4180-style CSV escaping locally for this small fixed-column export; do not add a dependency.

## New Capability

An operator can download a deterministic CSV delivery receipt report for one already-sent club message.

## Validation Plan

- Run the focused controller/export tests.
- Manually create a message with delivered, problem, opened, and sent recipients, download the CSV, and verify the columns, row count, ordering, statuses, and reasons.
- Run `dev check`.
