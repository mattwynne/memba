# 2. Use Commanded and event sourcing by default

Date: 2026-05-25

## Status

accepted

## Context

Memba will need workflows where user intent, business rules, side effects, and read-optimized projections should be kept explicit. Membership lifecycle changes, renewal/payment flows, role changes, email workflows, and integrations are likely to benefit from a command/event model as the domain grows.

Phoenix and Ecto remain a good fit for web delivery and current relational read models, but putting every domain workflow directly behind CRUD changesets would make it harder to audit decisions, replay derived state, and keep write-side behavior separate from UI concerns.

## Decision

Add the `commanded` Elixir dependency and use Commanded as the CQRS and event-sourcing foundation for domain models.

Model domain behavior with commands, aggregates, and events by default. Use event sourcing for new domain models unless there is a clear reason not to, such as a purely static reference table, a simple technical configuration record, or another case where event history would add more complexity than value.

Use PostgreSQL/Ecto read models and projections where appropriate for queries, screens, and reports. Ecto schemas may also remain the source of truth for explicitly chosen non-event-sourced models.

Do not introduce a production event-store adapter in this change. Choose and configure the persistent event store in a follow-up ADR before storing business-critical event streams in production.

## Consequences

Commanded gives Memba a standard structure for command dispatch, aggregate business rules, event publication, process managers, and projection handlers. Defaulting to event sourcing should make domain history explicit, improve auditability, and make it easier to rebuild read models as membership workflows evolve.

The dependency adds CQRS/event-sourcing concepts that contributors must learn. Simple CRUD may still be appropriate, but it should be an explicit exception rather than the default for domain models.

Because this ADR adds Commanded before selecting a persistent event store, initial work must avoid assuming production event persistence is complete. A later decision is required before storing business-critical event streams in production.
