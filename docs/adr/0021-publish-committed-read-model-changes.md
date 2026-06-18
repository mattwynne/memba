# 21. Publish committed read-model changes

Date: 2026-06-05

## Status

accepted

## Related reference guidance

- [CQRS](../reference/cqrs.md) for read-model/projection responsibilities and eventual-consistency boundaries.
- [Event Sourcing](../reference/event-sourcing.md) for projection handlers, committed read-model changes, idempotency, and replay.
- [Responsibility-Driven Design](../reference/responsibility-driven-design.md) for keeping publisher, projector, and subscriber responsibilities explicit.

## Context

Memba uses Commanded with Ecto projections to maintain read models for membership, messaging, email deliveries, inbound email, and staff/member views.

Some product behaviour needs to react when read-model state changes, not merely when an event is appended. For example, delivery status should update live when webhook events arrive, and clients should not need to refresh pages to see the latest projected status.

Acceptance tests had also been waiting for projected state by repeatedly reloading pages and polling browser-visible text. That is slow and imprecise because an event can be written before the relevant read model has committed the change.

Commanded Ecto projectors support an `after_update/3` callback. This callback runs after the projector transaction succeeds, making it the right boundary for announcing committed read-model changes.

## Decision

Publish committed read-model changes on the application PubSub bus.

Add `Memba.ReadModelChanges` as the shared publisher. It broadcasts on `Memba.ReadModelChanges.topic()` with this message shape:

```elixir
{:read_model_changed,
 %{
   projector: ProjectorModule,
   source_event: event,
   metadata: metadata,
   changes: changes
 }}
```

Each Ecto projector calls `Memba.ReadModelChanges.publish/4` from `after_update/3`, passing its module, the source event, event metadata, and committed Ecto.Multi changes.

Start `Phoenix.PubSub` before the projectors in the supervision tree so projectors can publish as soon as they start processing events.

## Consequences

Subscribers can react to committed read-model changes without polling the database or relying on event-append notifications that may arrive too early.

LiveView pages can subscribe to the shared read-model change topic and refresh affected assigns or streams when relevant projections change. This supports live delivery-status updates and similar state-change-driven UI.

Acceptance tests can be improved to wait for the specific projected change signal, then assert the browser UI with a short rendering timeout.

The published message includes the projector and committed changes, so subscribers can filter by projection and affected IDs. This keeps the initial mechanism general while allowing specialized listeners to derive narrower behaviour.

Projectors now depend on `Memba.ReadModelChanges` and `Memba.PubSub` being available. The supervision order protects that dependency.
