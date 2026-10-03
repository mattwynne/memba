# LiveQuery

`LiveQuery` is a small, application-independent binding for projection-backed
Phoenix LiveView assigns. A LiveView owner registers a query, reads one coherent
result, and refreshes that result when an injected notification source reports a
matching invalidation.

## Responsibilities

- `LiveQuery.Query` describes a stable query identity, one result assign, and a
  one-argument loader.
- `LiveQuery.Source` injects subscription, notification classification, and
  opaque interest matching.
- `LiveQuery.Binding` stores registrations on the owner socket, subscribes once
  per connected owner, and replaces query results and interests together.

A loader returns `{:ok, result, interests}` or `{:error, reason}`. Interests and
invalidations are deliberately opaque to this package. The application owns
their vocabulary, projection mapping, query composition, and authorization.

## Lifecycle

Disconnected mounts read current data without subscribing. A connected owner
subscribes before its first read. If source notifications arrive while a bind or
rebind is installing inputs and interests, the binding reconciles the window
with another fresh read. A new owner created by a mount or reconnect subscribes
and reads again.

Notifications are invalidation hints, not state patches or an ordered event
log. Every currently relevant notification causes a fresh read, so duplicate or
out-of-order delivery converges on the current projection state. A successful
read atomically replaces the public result and complete interest set; superseded
interests stop matching.

An access error clears that query's public result and interests and is returned
to the owner. The owner remains responsible for navigation, raising, or
rendering a private-surface transition. Other socket assigns, including route
and form state, are not replaced.

## Non-goals

The package does not create a process per query, cache shared results, infer SQL
predicates, provide durable delivery, patch view models from events, or adapt
LiveView streams. Subscription cleanup follows owner-process termination and
the injected source's own subscriber monitoring; there is no separate
unsubscribe callback.
