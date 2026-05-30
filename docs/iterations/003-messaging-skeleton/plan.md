# Messaging skeleton (send and per-recipient deliveries)

Date: 2026-05-28
Status: merged

## Goal

Implement the Messaging context skeleton: a Message aggregate per message,
SendMessage with resolved recipients, per-recipient delivery events, and a
fake delivery provider port. After this iteration, a member can send a club
message and recipient addressing and provider fan-out are correct.

## Background / Context

Iterations 001–002 set up the event-sourced toolchain and the Membership
model. Messaging is its own Commanded context (ADR 0007). It depends on
Membership only through Membership's public query API (no direct access to
Membership's Ecto schemas or projections).

Relevant ADRs:

- ADR 0004: model deliverability as one Message aggregate per message.
- ADR 0005: resolve recipients in the application service and include them
  in the `SendMessage` command.
- ADR 0007: separate Messaging Commanded context.
- ADR 0011: caller-supplied UUID identities.

This slice only handles `sent` semantics. Delivery status transitions,
receipt mapping, and operator views land in iteration 004.

## Scope

### In scope

- `Memba.Messaging.App` and `Memba.Messaging.Router`.
- `Message` aggregate (one per message, ADR 0004), caller-supplied UUID
  identity.
- `SendMessage` command carrying the resolved recipient list (ADR 0005).
- Application service that resolves recipients via Membership's query API
  and dispatches the command.
- Events: `MessageSent`, plus one `RecipientDeliveryCreated` (or equivalent)
  per resolved recipient, emitted on the message stream.
- Fake delivery provider port called once per recipient delivery; success
  means Memba has handed the delivery to the provider.
- Projections + read queries sufficient to assert:
  - the message exists with subject and sender;
  - each recipient has its own delivery record;
  - the fake provider was called once per recipient.
- Cucumber step definitions for the scenario "A member sends a club
  message", including the assertions about who is and is not addressed and
  the per-recipient provider calls.
- ExUnit coverage for the Message aggregate rules and the fake provider
  port.

### Out of scope

- Delivery status transitions beyond `sent`.
- Member-facing receipt status mapping (ADR 0006).
- Operator deliverability view.
- Open tracking and idempotency (ADR 0012).

## Acceptance Criteria

- Sending a message to a club addresses exactly the active members of that
  club, and does not address members of other clubs.
- One recipient delivery record exists per resolved recipient.
- The fake provider port is called exactly once per recipient delivery.
- The Cucumber scenario "A member sends a club message" passes.
- ExUnit covers Message aggregate decisions, the application service's
  recipient resolution, and the fake provider port.
- `devenv shell mix precommit` passes.

## Implementation Plan

1. Add `Memba.Messaging.App` and `Memba.Messaging.Router`.
2. Add the `Message` aggregate, `SendMessage` command, and `MessageSent` +
   per-recipient delivery events.
3. Add the application service that resolves recipients via Membership and
   dispatches `SendMessage`.
4. Define the fake delivery provider port and wire it into the message
   sending flow so it is called once per recipient.
5. Add projections and queries for messages and recipient deliveries.
6. Add Cucumber step definitions for "A member sends a club message".
7. Run `devenv shell mix precommit` and fix any issues.

## Validation Plan

- Cucumber scenario for sending a club message passes.
- ExUnit covers aggregate rules, application service, and fake provider.
- `devenv shell mix precommit` passes.

## Risks / Follow-ups

- The fake provider shape needs to be channel-neutral enough that ADR 0005
  remains satisfied when a real provider (likely Postmark) lands in a later
  iteration.
- Iteration 004 adds the delivery status state machine, receipt mapping, and
  operator views.
