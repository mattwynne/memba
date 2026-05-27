# 11. Use caller-generated UUID aggregate identities

Date: 2026-05-26

## Status

accepted

## Context

Commanded routes commands to aggregates by identity. Memba needs aggregate identities for clubs, people, memberships, and messages.

Some domain concepts have tempting natural keys. For example, a membership could be identified by `{club_id, person_id}`, and a person could be identified by email. However, natural keys are not always stable: email addresses can change, and memberships may later need history, lapsed/reactivated states, transfers, or multiple periods.

Commands also need an identity before dispatch so Commanded can route them to the correct aggregate stream.

## Decision

Use caller-generated UUIDs as aggregate identities.

The application service or test creates the UUID before dispatching the command. Aggregates do not generate their own identities.

Apply this to the first slice as follows:

- Club aggregate identity: `club_id`.
- Person aggregate identity: `person_id`.
- Membership aggregate identity: `membership_id`, with `club_id` and `person_id` stored as event fields.
- Message aggregate identity: `message_id`.

Use Commanded's aggregate identity/routing conventions rather than hand-coding brittle stream names in domain code. The plan may describe this as one stream per aggregate identity, but implementation should let Commanded manage the exact stream naming convention.

A membership must not have a second active membership for the same `{club_id, person_id}` pair. Enforce this in the application service using Membership's public query API/projections before dispatching `AddMember`.

## Consequences

UUID identities are stable, simple to route, and avoid coupling aggregate identity to mutable business attributes such as email.

Using a generated `membership_id` keeps membership lifecycle flexible. The cost is that duplicate prevention for active `{club_id, person_id}` memberships is an application/domain rule rather than the aggregate stream identity itself.

Tests and application services must generate IDs explicitly before dispatching commands.
