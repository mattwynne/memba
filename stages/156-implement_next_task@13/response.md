Implemented packet `task-011a-91505d3-bind-error-reconcile-1` with result `ready_for_review`.

Changes:

- [binding.ex](/workspace/memba/packages/live_query/lib/live_query/binding.ex:38) now reconciles classified bind-window notifications after either a successful or failed initial bind/rebind read.
- Reconciliation consumes the crossing notification and performs exactly one forced reread.
- A successful reread installs only the current result and interests.
- A repeated access error returns the final error with the public assign cleared and interests empty.
- [binding_test.exs](/workspace/memba/packages/live_query/test/live_query/binding_test.exs:270) adds focused coverage for initial-bind recovery, route-rebind recovery, repeated-error clearing/bounded retry, notification consumption, and no-classified-notification one-read behavior.
- Recorded the required result in [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json:1).

TDD evidence: the initial test-only run produced 12 tests with 3 expected failures, all returning the stale first `:forbidden` result instead of reconciling.

Final validation:

- Binding tests: 12 tests, 0 failures
- Complete standalone package: 19 tests, 0 failures
- Package formatting: passed
- `git diff --check`: passed

Task 011A remains unchecked. No Memba application, LiveView, acceptance, plan, ADR, matrix, todo, or task 011B files changed. Per the packet, `dev check` was not run; final exact-state `dev check` belongs to task 011B and the deterministic workflow.