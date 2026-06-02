# 5. Message send commands include resolved recipients

Date: 2026-05-26

## Status

accepted

## Context

Memba needs to model a member sending a message to the members of a club. The message aggregate must know which email email deliveries exist so it can project member-facing status and Memba staff email delivery status.

Recipient resolution depends on club membership projections: for the first slice, recipients are all active members of the message's club at send time, including the sending member, and excluding members of other clubs.

We considered several ways to create per-email email deliveries:

1. Resolve recipients before dispatch and include them in `SendMessage`; the message aggregate emits `MessageSent` and one delivery-created event per recipient.
2. Have `SendMessage` emit only `MessageSent`; a process manager or event handler later creates deliveries.
3. Have the aggregate query memberships itself.
4. Have an application service create deliveries outside the aggregate.

## Decision

For this slice, resolve recipients before dispatch and include them in the `SendMessage` command.

The application service queries the membership projection, builds a list of recipients, and dispatches `SendMessage` with those recipients. The message aggregate emits `MessageSent` plus one email delivery event per recipient in the same stream.

Use channel-neutral language where practical. A email delivery should not be named as if email is the only future channel. Email-specific details may exist on the email delivery for this iteration, but the domain shape should leave room for future notification channels such as SMS, push, or other delivery methods.

## Consequences

This keeps the first implementation simple and testable. One command establishes the message and its email delivery state, and the shared Cucumber scenarios can exercise the behaviour without adding a process manager.

The trade-off is that recipient resolution depends on the membership projection being current before command dispatch. That is acceptable for this slice and can be revisited if stronger consistency is needed.

A future iteration may introduce a process manager if delivery creation becomes asynchronous, retryable, multi-channel, or dependent on provider-specific workflows.
