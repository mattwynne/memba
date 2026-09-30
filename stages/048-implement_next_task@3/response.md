Implemented packet `task-004-ba89b32-provisional-binding-1` with result `ready_for_review`. The todo line remains unchecked and there are no unresolved issues.

Changes:

- [binding.ex](/workspace/memba/web/lib/memba_web/live_query/binding.ex) — LiveView-owned registration state, connected subscribe-before-read, relevant refresh, atomic result/interest replacement, route rebind, bind-window reconciliation, and owner-facing access errors.
- [query.ex](/workspace/memba/web/lib/memba_web/live_query/query.ex) — provisional query contract returning `{:ok, result, interests}` or `{:error, reason}` for one public assign.
- [source.ex](/workspace/memba/web/lib/memba_web/live_query/source.ex) — provisional injected subscription, notification classification, and opaque interest matching contract.
- [binding_test.exs](/workspace/memba/web/test/memba_web/live_query/binding_test.exs) — seven focused tests covering disconnected reads, subscription ordering, multiple registrations, scoped refresh, interest replacement, rebind, access errors, bind-window reconciliation, and reconnect/remount.
- [live_query_fixture_live.ex](/workspace/memba/web/test/support/live_query_fixture_live.ex) — minimal LiveView fixture proving fresh connected processes subscribe again and reread current state.
- [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json) — validated workflow result artifact.

The deterministic bind-window trace is:

`subscribe → initial read → notification delivered during read → result/interests installed → notification classified → conservative follow-up read`

Successful refreshes preserve unrelated query results and transient assigns. Initial-read, rebind, and refresh access errors clear the affected successful result/interests and return `{query_id, reason}` to the owning LiveView without imposing navigation policy.

Validation passed:

- `PATH="$PWD/bin:$PATH" dev test test/memba_web/live_query` — 7 tests, 0 failures
- `bin/mix format --check-formatted` — exit 0
- `git diff --check` — exit 0

No dashboard wiring, Memba projector mapping, Commanded dependency, package extraction, generic navigation policy, or per-query process was introduced. Per the packet instructions, the full `dev check` was left to the workflow’s deterministic validation node.