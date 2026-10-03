Implemented packet `task-007a-1b40c6b-package-extraction-1` with result `ready_for_review`.

Created the standalone [LiveQuery package](/workspace/memba/packages/live_query/README.md), including:

- Public `LiveQuery.Query`, `LiveQuery.Source`, and `LiveQuery.Binding` modules preserving the frozen contract.
- Documentation for lifecycle ordering, opaque invalidations, access-error ownership, duplicate/out-of-order delivery, and non-goals.
- Self-contained package tests covering constructors, one-owner subscription, interest replacement, relevant refresh, access-error clearing, bind/rebind races, reconnect/remount behavior, and monitored subscriber cleanup.
- No Memba, Commanded, or Ecto references or dependencies.
- No changes to existing web consumers, provisional modules, `todo.md`, Docker, release, or quality-gate configuration.

Focused validation passed:

- Formatting check: exit 0.
- Forced compilation with warnings as errors: exit 0.
- Package tests: 15 tests, 0 failures.
- Dependency/reference isolation scan: exit 0.

The required result is recorded in [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json). There are no unresolved items. Per packet scope, `dev check` was not run; the deterministic workflow stage owns that full gate.