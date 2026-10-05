# Frozen live-query extraction contract

Task 006 freezes the generic contract proved by the dashboard and conversation
detail verticals. Task 007 may move and rename modules as part of package
extraction, but it must preserve these semantics:

- A query has a stable identity, owns exactly one public result assign, and has
  a one-argument loader. The loader returns `{:ok, result, interests}` or
  `{:error, reason}`. Every success atomically replaces both the coherent result
  and its complete opaque interest set.
- A source has zero-argument `subscribe`, one-argument `classify`, and
  two-argument `matches?` callbacks. Classification returns `:ignore` or
  `{:ok, invalidations}`. Interest and invalidation values remain opaque to the
  generic package; Memba projector names and tuple vocabulary stay in the app.
- One LiveView owner holds registrations and one shared source subscription.
  No process is created per query. A connected bind subscribes before its first
  read and reconciles relevant notifications delivered across the bind window.
- Notifications refresh only matching registrations. Rebind replaces inputs,
  result, and interests. A failed initial read, rebind, or refresh clears that
  query's public result and interests before returning the error to the owner.
- The LiveView owner decides whether an access error raises, renders a cleared
  surface, or navigates. Query replacement does not overwrite route, form,
  flash, disclosure, command, or other transient owner state.

The contract is represented by the types and moduledocs in
`LiveQuery.Query`, `LiveQuery.Source`, and `LiveQuery.Binding` under
`packages/live_query`. The package's binding and lifecycle tests lock
subscription ordering, one-subscription ownership, relevant-only refresh,
atomic interest replacement, route rebind, result clearing, bind-window
reconciliation, fresh connected mount behavior, reconnect behavior, and
subscriber cleanup. The dashboard and conversation-detail tests prove the same
contract against two materially different application consumers.
