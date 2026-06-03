Result: IMPLEMENTED_AND_PUBLISHED

Plan path: `docs/iterations/019-inbound-club-messages-by-email/plan.md`

## Summary of delivered capability

Implemented iteration 019: inbound club messages by email.

The published implementation adds support for members to discover a club inbound email address, send club messages via email, and have those inbound provider payloads routed through a Resend webhook into the provider-neutral messaging flow. The implementation includes destination and sender resolution, active-membership authorization, idempotency for provider message IDs, conservative plain-text normalization, attachment/HTML rejection paths, rejection emails, webhook parsing/signature handling, projection/audit read model support, and tests covering the new behaviour.

## Plan conformance summary

The implementation todo list for `docs/iterations/019-inbound-club-messages-by-email/todo.md` shows all 24 tasks completed, including the final `dev check`.

Plan conformance gate reported:

- `plan_conformant: true`
- `plan_rework_available: false`

The final validation task was marked valid, with evidence that:

- `dev check` passed.
- ExUnit passed with `470 tests, 0 failures`.
- Acceptance passed with `31 scenarios (31 passed)`, `205 steps (205 passed)`.
- The working tree remained clean after validation.

## Key files changed

The final artifact gate did **not** find working-tree or immediate base-head evidence:

- Working tree was clean.
- `HEAD@{1}` to `HEAD` had no differences.
- It reported: `ERROR: Implementation workflow reached finalization with no artifact evidence.`

However, the subsequent publish-to-main step created and pushed the implementation commit, and its output is the authoritative artifact evidence for changed files. The publish output reported `57 files changed, 5488 insertions(+), 9 deletions(-)`.

Grouped changed files from publish output:

### Iteration documentation

- `docs/iterations/019-inbound-club-messages-by-email/implementation-notes.md`
- `docs/iterations/019-inbound-club-messages-by-email/todo.md`

### Inbound address helper

- `web/lib/memba/club_inbound_email_address.ex`
- `web/test/memba/club_inbound_email_address_test.exs`

### Messaging commands, events, models, and services

- `web/lib/memba/messaging/commands/accept_inbound_club_email.ex`
- `web/lib/memba/messaging/commands/receive_inbound_email.ex`
- `web/lib/memba/messaging/commands/reject_inbound_club_email.ex`
- `web/lib/memba/messaging/events/inbound_club_email_accepted.ex`
- `web/lib/memba/messaging/events/inbound_club_email_rejected.ex`
- `web/lib/memba/messaging/events/inbound_email_received.ex`
- `web/lib/memba/messaging/inbound_club_authorization.ex`
- `web/lib/memba/messaging/inbound_club_destination.ex`
- `web/lib/memba/messaging/inbound_club_rejection_email.ex`
- `web/lib/memba/messaging/inbound_club_sender.ex`
- `web/lib/memba/messaging/inbound_email.ex`
- `web/lib/memba/messaging/inbound_email_attachment.ex`
- `web/lib/memba/messaging/inbound_email_body.ex`
- `web/lib/memba/messaging/inbound_email_receipt.ex`

### Projection and migration

- `web/lib/memba/messaging/projections/inbound_email_source.ex`
- `web/lib/memba/messaging/projectors/inbound_email_source.ex`
- `web/priv/repo/migrations/20260603034844_create_messaging_inbound_email_sources_projection.exs`

### Resend inbound webhook

- `web/lib/memba_web/controllers/resend_inbound_webhook_controller.ex`
- `web/lib/memba_web/resend_inbound_email_parser.ex`

### Messaging and inbound email tests

- `web/test/memba/messaging/inbound_club_authorization_test.exs`
- `web/test/memba/messaging/inbound_club_destination_test.exs`
- `web/test/memba/messaging/inbound_club_message_acceptance_test.exs`
- `web/test/memba/messaging/inbound_club_sender_test.exs`
- `web/test/memba/messaging/inbound_email_api_test.exs`
- `web/test/memba/messaging/inbound_email_body_test.exs`
- `web/test/memba/messaging/inbound_email_dispatch_test.exs`
- `web/test/memba/messaging/inbound_email_events_test.exs`
- `web/test/memba/messaging/inbound_email_receipt_test.exs`
- `web/test/memba/messaging/inbound_email_source_projection_test.exs`

### Webhook and signature tests

- `web/test/memba_web/controllers/resend_inbound_webhook_controller_test.exs`
- `web/test/memba_web/resend_inbound_email_parser_test.exs`
- `web/test/memba_web/resend_webhook_signature_test.exs`

## Published commit on main

Publish-to-main output reported:

- Commit created: `71e224c`
- Commit subject: `iteration 019: Inbound club messages by email`
- Published implementation to main: `71e224c2e48e551a488d31b209774c19d14605e7`

Published commit on main:

`71e224c2e48e551a488d31b209774c19d14605e7`

## Commit trailer metadata present

The publish output confirms the implementation was squashed/published as:

`iteration 019: Inbound club messages by email`

No explicit commit trailers were shown in the provided publish output, so trailer names/values cannot be confirmed from the evidence provided.

## Tests and validation run

Final `dev ci` / `dev check` validation passed.

Evidence from the validation output:

- ExUnit:
  - `470 tests, 0 failures`
- Acceptance tests:
  - `31 scenarios (31 passed)`
  - `205 steps (205 passed)`
- Acceptance runtime:
  - `3m02.234s`

The publish step also reported:

- `No acceptance .feature changes detected.`
- Current branch was up to date before push.
- Push to main succeeded:
  - `30050d1..71e224c  HEAD -> main`

## Manual demo/checks still recommended

The plan’s manual demo remains recommended against a local/test mailer setup:

1. Start the app locally with the local/test mailer.
2. Ensure Kootenay Mountaineering Club has slug `kmc` and Alice is an active member with primary and alternate email addresses.
3. Submit a realistic Resend inbound webhook payload for Alice emailing `kmc@clubs.memba.io`.
4. Confirm the message appears in KMC member views as a normal club message from Alice.
5. Confirm KMC active members receive outbound club-message email and Nelson Paddling Club members do not.
6. Submit the same example from Alice’s alternate email address and confirm it is posted as Alice.
7. Submit unknown sender and non-member examples and confirm no message appears and rejection emails are sent.
8. Submit an example with an attachment and confirm it is rejected.
9. Submit an HTML-only example and confirm it is rejected.
10. Submit an example with quoted content/signature and confirm only the new message text appears.

## Non-blocking follow-ups

Non-blocking follow-ups from the plan still apply:

- Verify real Resend inbound payload details against production webhook examples and adjust the isolated parser if needed.
- Continue monitoring idempotency across event streams, projections, database constraints, and outbound side effects.
- Refine quote/signature stripping only with additional examples to avoid over-aggressive body trimming.
- Revisit rejection-email backscatter risk and provider guidance before high-volume production use.
- Consider future support for safe HTML preservation/rendering.
- Decide future attachment storage/scanning/visibility/delivery semantics.
- Revisit addressing for future channel/sub-group routing and custom club-owned inbound domains.