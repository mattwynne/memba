# Domain-Driven Design (DDD)

Domain-Driven Design is Eric Evans’s approach to building software for complex business domains. Its core claim is that the hardest part of valuable software is not the framework, database, or UI; it is the model of the domain and the shared understanding that model creates between domain experts and software builders.

Evans introduced the approach in *Domain-Driven Design: Tackling Complexity in the Heart of Software* (2003). Later DDD writing and practice often divides the subject into strategic design and tactical design.

## The central idea

DDD asks teams to make the domain model the heart of the software.

The model is not a diagram on a wall. It is a working abstraction expressed in:

- conversations with domain experts,
- names in code,
- tests and examples,
- commands and events,
- service boundaries,
- invariants and policies,
- documentation and diagrams.

The model should help the team reason about real business behavior. When the code and the business language drift apart, DDD has failed.

## Ubiquitous Language

The Ubiquitous Language is a shared language used by developers and domain experts inside a bounded context. It appears in speech, code, tests, documentation, and user-facing workflows.

Its purpose is to eliminate translation gaps. If the business says “claim,” “policy,” “premium,” “endorsement,” or “settlement,” the software should not hide those concepts behind generic names like `Record`, `Data`, `Manager`, or `Processor`.

Important points:

- The language is discovered through collaboration, not invented by developers alone.
- It evolves as the team learns.
- Ambiguity is a signal. If a term means two different things, there may be two bounded contexts.
- Code should reinforce the language rather than dilute it.

## Bounded Context

A bounded context is an explicit boundary inside which a model and language are consistent.

The same word can mean different things in different contexts. For example, “Customer” in Sales may mean a sales prospect or account. “Customer” in Billing may mean a legal entity responsible for payment. “Customer” in Support may mean someone entitled to help. Trying to force one universal `Customer` model across all contexts creates coupling and confusion.

Bounded contexts are a strategic DDD tool. They help teams decide:

- where a model applies,
- where language changes meaning,
- where services or modules should be separated,
- where integration contracts are needed,
- where teams can work independently.

A bounded context is not automatically a microservice. It may be a module, a package, a service, a subsystem, or a team boundary. Microservices work best when they align with bounded contexts, but the context is the modeling boundary, not the deployment mechanism.

## Context Mapping

Context mapping describes relationships between bounded contexts.

Common relationship patterns include:

- **Partnership**: two teams coordinate closely because their models evolve together.
- **Customer/Supplier**: one context provides capabilities consumed by another.
- **Conformist**: a downstream context adopts the upstream model because it has little influence.
- **Anti-Corruption Layer**: a context protects its model from an outside or legacy model through translation.
- **Open Host Service / Published Language**: a context exposes a stable integration contract.
- **Shared Kernel**: two contexts deliberately share a small part of a model.

Context maps are useful because integration is where model purity meets organizational reality.

## Aggregate

An aggregate is a cluster of domain objects treated as one consistency boundary. It has one aggregate root, and outside code should reference the aggregate through that root.

The aggregate root protects invariants. For example, an `Order` aggregate might enforce:

- an order cannot be shipped before payment is captured,
- cancelled orders cannot accept new line items,
- total quantity cannot exceed a contractual limit.

Aggregates are transactional boundaries. A transaction should usually modify one aggregate. Cross-aggregate workflows are coordinated through domain events, process managers, sagas, or application services.

Good aggregates are designed around invariants, not database relationships. A common mistake is to make aggregates too large because the data is related. DDD asks: what must be consistent immediately?

## Entities and Value Objects

An **entity** has identity that persists across changes. A customer remains the same customer even if their email changes.

A **value object** is defined by its attributes and has no separate identity. Money, date ranges, addresses, quantities, and coordinates are common value objects. They are often immutable.

Value objects are powerful because they move domain rules out of primitive types. `Money` is better than `decimal`; `EmailAddress` is better than `string`; `BookingPeriod` is better than two loose dates.

## Domain Services, Application Services, and Repositories

DDD distinguishes responsibilities:

- **Entity / aggregate behavior**: rules that belong to domain objects.
- **Value objects**: immutable domain concepts and validation.
- **Domain services**: domain operations that do not naturally belong to one entity or value object.
- **Application services**: orchestration of use cases, transactions, authorization, and calls into the domain model.
- **Repositories**: collection-like abstractions for loading and saving aggregates.
- **Infrastructure**: persistence, messaging, web frameworks, external APIs.

The goal is to keep domain behavior from being swallowed by controllers, database models, or transaction scripts when the domain is complex enough to deserve a model.

## Domain Events

A domain event records something significant that happened in the domain, such as `OrderPlaced`, `PaymentFailed`, or `PolicyRenewed`.

Domain events are useful for:

- decoupling side effects from the aggregate decision,
- notifying other bounded contexts,
- building read models,
- triggering processes,
- creating an audit trail,
- supporting Event Sourcing.

In DDD, event names should come from the Ubiquitous Language. They are facts the business recognizes.

## Strategic vs tactical DDD

**Strategic DDD** is about where models live and how they relate:

- subdomains,
- core domain vs supporting/generic domains,
- bounded contexts,
- context maps,
- team and system boundaries.

**Tactical DDD** is about modeling inside a bounded context:

- entities,
- value objects,
- aggregates,
- repositories,
- factories,
- domain services,
- domain events.

Strategic design usually matters more. A beautifully modeled aggregate inside the wrong boundary still causes trouble.

## Relationship to CQRS and Event Sourcing

DDD, CQRS, and Event Sourcing often appear together, but they are not the same thing.

DDD provides the language and boundaries. CQRS provides a way to separate write behavior from read views. Event Sourcing provides a way to persist domain history as events.

They combine well when:

- commands express business intent,
- aggregates enforce invariants,
- aggregates emit domain events,
- events are persisted or published,
- projections build query models,
- bounded contexts communicate through explicit contracts.

But DDD can be practiced without CQRS or Event Sourcing, and many DDD systems use ordinary relational persistence.

## Benefits

- **Shared understanding** between experts and developers.
- **Code that reflects the business** rather than technical storage structures.
- **Clearer boundaries** for teams, modules, and services.
- **Better handling of complexity** in core domains.
- **More expressive behavior** than generic CRUD models.
- **Safer change** because invariants and concepts are localized.

## Costs and risks

- **Requires domain access**: DDD fails without collaboration with experts.
- **Can be over-engineered**: tactical patterns add ceremony in simple domains.
- **Hard boundary decisions**: bounded contexts are discovered over time.
- **Language drift**: the model must be continuously maintained.
- **Misapplied aggregates**: oversized aggregates hurt performance and concurrency; undersized aggregates leak invariants.
- **Framework distortion**: ORMs and web frameworks can pull the model toward database tables and CRUD controllers.

## When to use DDD

Use DDD most heavily in the core domain: the part of the system that gives the business advantage and contains complex rules or workflows.

Use lighter patterns for supporting or generic domains. Not every admin screen, lookup table, or integration adapter deserves rich tactical DDD.

Good signs that DDD will help:

- domain experts use nuanced language,
- rules are conditional and business-specific,
- workflows matter more than data entry,
- different departments use the same words differently,
- mistakes in the model are expensive,
- the system is expected to evolve for years.

## Practical heuristics

- Start with conversations, examples, and event storming before code.
- Name commands and events in business language.
- Draw bounded contexts before drawing microservices.
- Design aggregates around invariants, not table relationships.
- Prefer value objects over primitive obsession.
- Keep application orchestration separate from domain decisions.
- Use an anti-corruption layer when integrating with legacy or external models.
- Apply DDD depth selectively: core domain first.

## Primary references

- Eric Evans, *Domain-Driven Design: Tackling Complexity in the Heart of Software*.
- Domain Language / Eric Evans resources: https://www.domainlanguage.com/ddd/
- Martin Fowler, “Domain-Driven Design”: https://martinfowler.com/bliki/DomainDrivenDesign.html
- Martin Fowler, “Bounded Context”: https://martinfowler.com/bliki/BoundedContext.html
- Martin Fowler, “Ubiquitous Language”: https://martinfowler.com/bliki/UbiquitousLanguage.html
- Martin Fowler, “DDD Aggregate”: https://martinfowler.com/bliki/DDD_Aggregate.html
