# 25. Use current group participation for access and delivery eligibility

Date: 2026-09-23

## Status

accepted

This text supersedes the earlier accepted revision of ADR 0025. That architecture was implemented only on the unreleased iteration branch and abandoned before release; Git history preserves it without leaving two conflicting accepted decisions in the documentation.

## Context

Iteration 064 lets a custom-group member leave or be removed. Departure must end current group activity without affecting club membership or roles.

Each conversation currently belongs to exactly one group. A person's follow preference and their current permission to participate are different concerns: the preference may survive an absence, but it cannot grant access or delivery while the person is outside the group.

Email recipients must also be predictable. Once a root message or reply is posted, later membership changes must not alter the recipients selected for that message or cancel its already-created or queued deliveries.

The earlier revision of this ADR proposed admission-lifecycle group-membership identities, person-owned subscription authorization records, revocation receipts, authorization unions, and provider-handoff recovery. The agreed behaviour does not require that machinery.

## Decision

Use the existing current group-participation relationship as the authority for a custom group's activity. A current participant may read, post, reply on the web, reply by email, and change follow preferences, subject to the existing rules. A former participant may do none of those things. Stale screens and actions receive the existing generic authorization error.

Keep conversation follow preferences when participation ends. A follow preference does not grant group access and does not make an absent person eligible for delivery. Rejoining creates no delivery backlog; future messages in conversations the person still follows use the preference normally again.

Fix each message's email recipients when the message is posted, using current group participation and the applicable root-message or followed-reply rules at that time. Removal after posting does not cancel deliveries already created or queued for that message. Messages posted while a person is absent create no delivery for that person.

Group removal changes only participation in that group. It never ends club membership or changes club roles.

A conversation has exactly one group in current product scope. Keep the model open to a later multi-group design, but do not implement combined authorization or delivery rules now.

Do not introduce first-class admission-lifecycle group-membership identities, person-owned subscription authorization ledgers, revocation receipts, authorization unions, generations, cutoffs, or conversation cleanup fan-out for this behaviour. Provider crash recovery and duplicate-handoff handling are separate concerns and remain out of scope.

## Relationship to earlier decisions

This preserves [ADR 0024](0024-use-club-as-membership-admin-consistency-boundary.md): club membership and role invariants remain at the Club boundary, while custom-group removal does not alter them.

This supersedes only the prior contents of ADR 0025. It does not change existing provider or projection decisions beyond rejecting their expansion into a new removal protocol for iteration 064.

## Consequences

The implementation remains small: authorize from current group participation, preserve follows, and determine deliveries at message-posting time. It avoids migration and coordination machinery that the agreed product rules do not need.

A delivery fixed before removal can still be sent afterward. A person receives nothing for messages posted during an absence and receives no backlog after rejoining. Preserved follows can resume delivery for later messages.

Future conversations associated with multiple groups will need an explicit product and architecture decision. This ADR neither forbids that support nor pre-decides its authorization semantics.
