# 22. Use projection barriers for read-your-writes checks

Date: 2026-06-05

## Status

accepted

## Related reference guidance

- [CQRS](../reference/cqrs.md) for read-your-writes expectations across separate command and query models.
- [Event Sourcing](../reference/event-sourcing.md) for projection lag, checkpointing, and replay-aware synchronization.
- [Responsibility-Driven Design](../reference/responsibility-driven-design.md) for keeping barrier coordination separate from projector and UI responsibilities.

## Context

Memba uses Commanded with Ecto projections. Events can be committed before the read models used by browser pages have caught up.

ADR 21 introduced a committed read-model changes bus. That bus is well suited to positive synchronization: a subscriber can wait for a specific projected change after subscribing before an action.

Negative assertions need a different synchronization point. Browser acceptance tests sometimes need to prove that something did not happen, for example that a message was not addressed to a non-member or that an email was not sent to an alternate address. Today these assertions often wait for a timeout to expire. This is slow and can still be imprecise.

Event-sourced systems commonly solve this with a consistency barrier, read-your-writes barrier, or projection barrier. A write establishes an event-store checkpoint, and the caller waits until the relevant projections have processed at least that checkpoint. Once the barrier is satisfied, the read model includes all events that had been committed up to the checkpoint.

## Decision

Use projection barriers for read-your-writes synchronization, especially for negative acceptance assertions.

A projection barrier is satisfied when each selected projector has processed events up to a target event-store checkpoint.

The core mechanism should be implemented as reusable Elixir code, not as a browser-facing HTTP endpoint. Acceptance tests can call it through the existing Elixir server-command/RPC mechanism used by setup steps. LiveViews, controllers, and other Elixir code can call the same mechanism directly when product flows need read-your-writes behaviour.

Expected API shape:

```elixir
Memba.ProjectionBarrier.await(
  [Memba.Messaging.Projectors.Message],
  timeout: 1_000
)
```

or, when a caller already has a checkpoint:

```elixir
Memba.ProjectionBarrier.await(
  [Memba.Messaging.Projectors.Message],
  checkpoint: checkpoint,
  timeout: 1_000
)
```

Acceptance helper shape:

```javascript
await waitForProjectionBarrier(world, [
  "Memba.Messaging.Projectors.Message"
]);
```

The helper should call Elixir directly through server commands. It should not use a new dev/test HTTP endpoint.

## Consequences

Acceptance tests can replace timeout-based negative waits with action-then-barrier-then-immediate-assertion flows. This should reduce wasted time and make absence checks more deterministic.

The read-model changes bus and projection barriers have distinct responsibilities:

- read-model changes bus: announces committed projected changes for positive synchronization and live UI updates
- projection barrier: coordinates read-your-writes and absence checks by waiting for projector progress

The barrier is relative to a checkpoint and a projector set. It should not be published as a generic event on the read-model changes bus. If a future asynchronous delivery mechanism is needed, barrier completion can be correlated to a specific request, but the primary interface remains request/response.

LiveView and controller flows may use projection barriers after commands before navigating or rendering from projected read models. They should use short timeouts and graceful fallback states such as “Saving…” or “Sending…” rather than blocking indefinitely.

A barrier only proves that selected projectors have caught up to events committed before the checkpoint. It does not prove that no later asynchronous process will commit another event. For those cases, tests or UI flows need a domain-specific completion signal or a broader checkpoint chosen after the asynchronous work has been triggered.
