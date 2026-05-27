# 4. Model message deliverability as a message aggregate

Date: 2026-05-26

## Status

accepted

## Context

Memba is introducing an event-sourced domain skeleton for clubs, people, memberships, and member-to-member club messages.

A message sent to a club creates per-recipient delivery state. The domain needs to record and project statuses such as sent, delivered, delayed, bounced, spam complaint, and opened. We need an aggregate boundary for this first slice.

The main options considered were:

1. One aggregate per message, containing that message and its recipient delivery states.
2. One message aggregate plus one delivery aggregate per recipient delivery.
3. One messaging aggregate per club, owning all messages and delivery states for that club.

## Decision

Use **one message aggregate per message** for the first message deliverability slice.

The message aggregate is identified by `message_id`. Its stream contains the message-sent event and the per-recipient delivery events/status changes for that message.

This aggregate owns the delivery state machine for each recipient delivery within the message. It can reject invalid delivery status transitions and support the projections needed for member-facing receipt status and operator deliverability status.

## Consequences

This keeps the first implementation small and cohesive. A message and its delivery statuses are easy to reason about in one stream, and the acceptance scenarios can run against a single aggregate boundary.

The trade-off is that all delivery status updates for a message go through the same aggregate stream. For large clubs or high-volume delivery-status events, this could create a hot or long-lived stream.

If that becomes a real problem, a future ADR may split recipient deliveries into their own delivery aggregates while keeping the message aggregate as the coordination point.

A club-wide messaging aggregate is rejected for now because it would make every message and delivery update for a club contend on one long-lived stream.
