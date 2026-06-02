# 7. Use separate Membership and Messaging Commanded contexts

Date: 2026-05-26

## Status

accepted

## Context

The first message deliverability slice introduces several domain concepts:

- Clubs.
- People.
- Memberships linking people to clubs.
- Messages sent by members to a club.
- Per-recipient message delivery state.

These concepts could all be handled by one global Commanded application/router, by one messaging-specific application/router, or by separate bounded contexts from the start.

Messaging needs to know which people are active members of a club when a message is sent. That creates a dependency from messaging to membership information.

## Decision

Use two Commanded contexts from the start:

1. **Membership context**
   - Commanded application: `Memba.Membership.App`.
   - Router: `Memba.Membership.Router`.
   - Owns the Club, Person, and Membership aggregates.
   - Owns projections/read models for current clubs, people, and memberships.

2. **Messaging context**
   - Commanded application: `Memba.Messaging.App`.
   - Router: `Memba.Messaging.Router`.
   - Owns the Message aggregate and email delivery state for each message.
   - Owns projections/read models for messages, email deliveries, member-facing email deliveries, and Memba staff email delivery details.

The messaging application service resolves recipients by calling a Membership context query API. For the first slice, recipients are all active members of the message's club at send time, including the sending member.

Messaging must not mutate membership state, query membership aggregates directly, or know about Membership's read-model storage details. It depends on Membership's public query interface, not on Ecto schemas or projection tables directly.

## Consequences

This gives Memba a clearer bounded-context shape from the beginning. Membership and messaging can evolve separately, and messaging does not own club/member lifecycle rules.

The trade-off is extra setup: two Commanded applications, two routers, and an explicit query dependency from Messaging to Membership.

This dependency is acceptable because recipient resolution is naturally a query over current membership state. Keeping the dependency at the Membership query API boundary preserves encapsulation: Membership can change its projections/read models without forcing Messaging to change. If stronger consistency is needed later, a process manager or cached membership projection inside Messaging can be introduced in a future ADR.
