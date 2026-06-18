# Event Sourcing

Event Sourcing stores the history of a system as an append-only sequence of immutable events. Instead of persisting only the current state of an entity, the system persists the facts that caused that state. Current state is derived by replaying those facts.

Martin Fowler described the pattern in his 2005 essay on Event Sourcing. Greg Young later became one of its most influential teachers, especially through his work connecting Event Sourcing with CQRS, aggregates, temporal modeling, and production concerns such as event versioning.

## Core idea

Traditional persistence answers: “What is the state now?”

Event Sourcing answers: “What happened?”

For example, instead of storing only:

```text
Order status = Shipped
```

an event-sourced system might store:

```text
OrderPlaced
PaymentAuthorized
OrderPacked
OrderShipped
```

The current order state is a fold over the event stream.

## Event characteristics

Good events are:

- **Past tense**: `InvoiceApproved`, not `ApproveInvoice`.
- **Business meaningful**: they describe domain facts, not low-level database mutations.
- **Immutable**: once written, events are not updated in place.
- **Ordered within a stream**: replay depends on deterministic order for a given aggregate or entity.
- **Durable**: the event log is the source of truth.
- **Versioned over time**: schemas evolve, but old events remain readable.

An event is not merely a notification. In Event Sourcing, the event is the record of the state transition itself.

## Aggregate streams

In DDD-influenced Event Sourcing, events are often stored in streams per aggregate instance:

```text
Order-123:
  1. OrderPlaced
  2. ShippingAddressChanged
  3. PaymentCaptured
  4. OrderShipped
```

The command handler loads the stream, rehydrates the aggregate by replaying events, asks the aggregate to perform behavior, and appends new events if the command succeeds.

This makes the aggregate both:

- a decision-making consistency boundary, and
- a function from past events plus a command to new events.

## Relationship to CQRS

Event Sourcing and CQRS are separate patterns, but they complement one another.

The event store is optimized for writes, audit, and reconstruction. It is not usually convenient for arbitrary queries like “show the dashboard for all active customers sorted by risk.” CQRS solves this by projecting events into read models.

A common pairing is:

1. Command arrives.
2. Aggregate is loaded from its event stream.
3. Aggregate emits new events.
4. Events are appended transactionally.
5. Projection handlers build query models.
6. Queries read from projections, not from the event store directly.

Greg Young’s teaching often frames CQRS as the read-model answer to Event Sourcing’s write-model strengths.

## Benefits

- **Complete audit trail**: the system records why state changed, not just the final value.
- **Temporal queries**: you can ask what the system believed at a point in time.
- **Debuggability**: production bugs can be investigated by replaying real event histories.
- **Rebuildable read models**: projections can be recreated from the event log.
- **New projections from old facts**: you can add reports and integrations after the fact.
- **Append-only writes**: avoids many update-in-place contention patterns.
- **Domain insight**: events expose the business process explicitly.
- **Integration**: other systems can react to meaningful domain events.

## Costs and risks

- **Event design is hard**: poor events become permanent liabilities.
- **Schema evolution**: event versioning must be planned from the beginning.
- **Eventual consistency**: projections may lag behind the event store.
- **Replay cost**: long streams may require snapshots or stream compaction strategies.
- **Operational complexity**: event stores, subscriptions, projections, poison messages, idempotency, and monitoring all matter.
- **Privacy and deletion**: immutable logs complicate legal requirements such as erasure.
- **External side effects**: replaying events must not resend emails, charge cards, or call external APIs accidentally.
- **Learning curve**: teams must think in facts and behavior rather than table updates.

## Event versioning

Greg Young’s “Versioning in an Event Sourced System” is a key resource. The central rule is that old events are historical facts; you do not rewrite history casually. Instead, systems evolve through techniques such as:

- tolerant readers that ignore unknown fields,
- adding optional fields,
- upcasters that transform old event shapes at read time,
- new event types that supersede old ones,
- migration streams for rare major changes,
- keeping event semantics stable even as code changes.

The hard problem is not JSON shape. It is semantic compatibility: does an old `CustomerRegistered` event still mean the same thing to today’s model?

## Snapshots

A snapshot stores derived aggregate state at a point in the stream so the system does not need to replay every event from the beginning.

Snapshots are an optimization, not the source of truth. The event stream remains authoritative. If a snapshot is lost or obsolete, it should be possible to rebuild it from events.

Use snapshots when:

- streams grow very long,
- aggregate rehydration is too slow,
- replay performs expensive calculations,
- cold-start latency matters.

Do not introduce snapshots before measuring the need.

## Projections

A projection is a read model built from events. It can be a SQL table, document, cache, search index, graph, data warehouse table, or in-memory view.

Projection handlers should usually be:

- **idempotent**: safe to process the same event more than once,
- **ordered where required**: especially per aggregate stream,
- **restartable**: able to resume from a checkpoint,
- **rebuildable**: able to recreate the view from scratch,
- **observable**: lag and failures should be visible.

## When to use Event Sourcing

Use it when the history is business-critical:

- finance, ledgers, payments, insurance, audit-heavy workflows,
- collaborative or temporal systems,
- domains where “how did we get here?” matters,
- systems needing multiple evolving projections,
- complex state machines and business processes,
- high-value core domains where modeling effort pays back.

Avoid it when:

- the domain is simple CRUD,
- only current state matters,
- event history has no business value,
- the team cannot support the operational model,
- privacy/deletion requirements conflict with immutable history and cannot be designed around.

## Misconceptions

- **Event Sourcing is not the same as event-driven architecture.** Event-driven systems communicate with events; event-sourced systems persist state as events.
- **Events are not commands.** Commands request something; events record that something happened.
- **Events are not database diffs.** Useful events encode domain facts.
- **The event log is not automatically a query model.** Projections are normally needed.
- **Immutability does not remove the need for correction.** Mistakes are corrected by new compensating events, not by editing old facts.

## Primary references

- Martin Fowler, “Event Sourcing”: https://martinfowler.com/eaaDev/EventSourcing.html
- Microsoft Azure Architecture Center, “Event Sourcing pattern”: https://learn.microsoft.com/en-us/azure/architecture/patterns/event-sourcing
- Greg Young, “Versioning in an Event Sourced System”: https://leanpub.com/eventsourcing
- Greg Young talks on Event Sourcing and CQRS, including GOTO and Code on the Beach recordings.
- Kurrent/Event Store resources on Event Sourcing: https://www.kurrent.io/blog/event-sourcing-and-cqrs/
