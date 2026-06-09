# Problems

## Club rejection email sender does not name the club

Observed: 2026-06-07

Status: Resolved by [iteration 031: Brand, email, and navigation polish](../iterations/031-brand-email-navigation-polish/plan.md). Inbound club-message rejection emails now use a club-aware sender/display name such as `<club name> via Memba` when club context is available, while preserving the configured sender address. Evidence: `web/test/memba/messaging/inbound_club_rejection_email_test.exs`.

A rejection email for a message sent to a club appears to come from Memba, rather than from the club via Memba. This makes the email feel like a generic platform notice instead of a club-specific delivery response.

Expected:

- Rejection emails for club messages should identify the club in the sender name, such as "<club name> via Memba".
- Recipients should be able to recognise which club the rejection notice is about from the email sender context.
