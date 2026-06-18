# Command Query Responsibility Segregation (CQRS)

CQRS separates the model used to change a system from the model used to read from it. The idea was popularised and named by Greg Young, building on Bertrand Meyer’s command-query separation principle: a command changes state and does not return domain data; a query returns data and has no side effects.

Martin Fowler’s concise formulation is still the best starting point: CQRS uses separate objects, often separate data models, for reads and writes. It is not automatically a whole-system architecture; it is a pattern to apply where the pressure on reads and writes differs enough to justify the extra moving parts.

## Core idea

In a traditional CRUD model, one representation is often stretched to serve every use case: validation, transactions, screens, reports, APIs, and persistence. CQRS says that this coupling is optional.

A typical CQRS system has:

- **Commands**: imperative requests such as `PlaceOrder`, `CancelBooking`, or `ApproveInvoice`.
- **Command handlers**: application-layer code that loads domain state, invokes domain behavior, and persists the result.
- **Write model**: the consistency-focused model that protects invariants. In DDD this is often aggregate-centric.
- **Events or state changes**: the facts emitted or persisted after successful commands.
- **Read model / projection / materialized view**: query-optimized data shaped for screens, reports, APIs, or integrations.
- **Queries**: side-effect-free reads against the read model.

The write side optimizes correctness and business rules. The read side optimizes convenience, latency, indexing, denormalization, and scale.

## Why Greg Young argued for it

Greg Young’s CQRS writing and talks repeatedly emphasize that most enterprise systems have asymmetric pressures:

- Reads are usually much more frequent than writes.
- Read screens rarely need the same shape as the transactional model.
- Business workflows are better represented as tasks than as generic CRUD edits.
- A single model often becomes an anemic compromise: too relational for behavior, too behavioral for reporting, and too generic for user intent.

CQRS lets the model diverge where the domain demands it. The command side can speak in business verbs. The query side can be a denormalized projection tailored to the user’s question.

## Relationship to DDD

CQRS fits naturally with Domain-Driven Design, but does not require it.

DDD contributes:

- **Ubiquitous language** for command names, events, aggregates, policies, and invariants.
- **Aggregates** as write-side consistency boundaries.
- **Bounded contexts** to decide where a CQRS split is useful and where ordinary CRUD is enough.
- **Domain events** as meaningful business facts that can feed projections.

CQRS is especially useful inside complex bounded contexts where commands represent real business decisions rather than simple data edits.

## Relationship to Event Sourcing

CQRS and Event Sourcing are independent but often paired.

- **CQRS without Event Sourcing**: the write side stores current state in a relational/document database and updates read models directly or through messages.
- **Event Sourcing without full CQRS**: possible in small systems, but querying an event log directly is awkward, so projections usually appear quickly.
- **Together**: commands produce events; events are appended to an event store; projections consume events to build read models.

Greg Young has often described CQRS as a stepping stone or natural companion to Event Sourcing, because an event store is an excellent write/audit model but a poor general query model.

## Benefits

- **Fit-for-purpose models**: command objects and read DTOs no longer need to share one shape.
- **Stronger domain behavior**: writes can be modeled as explicit business actions.
- **Independent scaling**: read and write workloads can be scaled, cached, indexed, and deployed differently.
- **Simpler queries**: read models can be denormalized and precomputed.
- **Security and permissions**: command authorization can differ from query authorization.
- **Integration**: events from the write side can feed other systems and projections.
- **Easier UI design for workflows**: task-based UIs map well to commands.

## Costs and risks

- **More components**: handlers, projections, messages, retries, read stores, and operational monitoring.
- **Eventual consistency**: if projections update asynchronously, reads may lag behind writes.
- **Duplication**: the same concept may appear in write and read models in different forms.
- **Harder debugging**: failures may cross process boundaries.
- **Overuse**: applying CQRS everywhere can create ceremony without value.
- **Projection rebuilds**: read models may need replay/rebuild processes.

## Design guidance

Use CQRS when at least one of these is true:

- The write model has real business invariants and behavior.
- Read and write shapes are substantially different.
- Read volume, latency, or indexing needs differ from write needs.
- You need multiple specialized views over the same facts.
- You are using Event Sourcing.
- The UI is task/workflow-oriented rather than record-editing-oriented.

Avoid CQRS, or keep it very lightweight, when:

- The feature is simple CRUD.
- Reads and writes use the same shape comfortably.
- Eventual consistency would confuse users or violate requirements.
- The team does not have the operational capacity for projections and messaging.

## Common implementation pattern

1. A user submits a command: `ApproveExpenseClaim`.
2. The application validates authorization and basic request shape.
3. The handler loads the relevant aggregate.
4. The aggregate enforces domain invariants.
5. The system commits state changes or appends domain events.
6. Events are published to projection handlers.
7. Projection handlers update read tables/documents/search indexes.
8. Queries read from those optimized projections.

## Misconceptions

- **CQRS does not require two databases.** Separate models can live in the same database or even the same process.
- **CQRS does not require Event Sourcing.** It pairs well with it, but can be implemented with ordinary persistence.
- **CQRS is not always asynchronous.** Read models may be updated synchronously when consistency requirements demand it.
- **CQRS is not an enterprise-wide mandate.** Apply it selectively, usually inside specific bounded contexts.
- **CQRS is not just “use DTOs.”** The important split is semantic: commands embody intent; queries return information without changing state.

## Primary references

- Greg Young, “CQRS Documents” PDF: https://cqrs.files.wordpress.com/2010/11/cqrs_documents.pdf
- Greg Young, “CQRS, Task Based UIs, Event Sourcing agh!”: https://gregfyoung.wordpress.com/
- Martin Fowler, “CQRS”: https://martinfowler.com/bliki/CQRS.html
- Microsoft Azure Architecture Center, “CQRS pattern”: https://learn.microsoft.com/en-us/azure/architecture/patterns/cqrs
- Kurrent/Event Store material on Greg Young, CQRS, and Event Sourcing: https://www.kurrent.io/blog/event-sourcing-and-cqrs/
