Implemented task 015: rejection-email delivery for unsupported inbound club emails.

Summary:
- Added `Memba.Messaging.InboundClubRejectionEmail` to build/deliver concise rejection emails through `Memba.Mailer`, using configured messaging sender/reply-to where available.
- Updated inbound receive flow to record unsupported destination/sender/authorization/body/attachment outcomes as `InboundClubEmailRejected` events and then deliver one rejection email.
- Added rejection delivery references to rejected inbound source projections.
- Preserved idempotency: duplicate rejected provider message IDs do not send duplicate rejection emails.
- Added/updated focused tests for:
  - plain-text-required rejection email
  - attachment-not-supported rejection email
  - unknown sender rejection email
  - duplicate rejected inbound email not re-sending a rejection
- Checked off only todo item `015`.

Validation:
- `mix format --check-formatted` passed.
- Focused inbound tests passed: `20 tests, 0 failures`.
- Related mail/provider tests passed: `18 tests, 0 failures`.
- Full `dev check` passed:
  - `447 tests, 0 failures`
  - `31 scenarios (31 passed)`