Packet `task-007b-7137b1a-consumer-adoption-1` is complete with result `ready_for_review`.

Implemented:

- Added the local `../packages/live_query` dependency in [web/mix.exs](/workspace/memba/web/mix.exs:58).
- Migrated dashboard and conversation-detail consumers to `LiveQuery.Binding`.
- Migrated application-owned queries to `LiveQuery.Query`.
- Kept the Memba notification adapter application-owned while switching it to `LiveQuery.Source`.
- Removed the superseded `MembaWeb.LiveQuery.Binding`, `Query`, and `Source` modules.
- Removed the duplicate web binding test and fixture.
- Updated [extraction-contract.md](/workspace/memba/docs/iterations/067-live-projection-queries/extraction-contract.md:25) to reference the package implementation and tests.
- Left `todo.md` unchecked and acceptance features untouched.

Validation passed:

- Package warnings-as-errors compilation.
- Package tests: 15 tests, 0 failures.
- Query/source-adapter tests: 23 tests, 0 failures.
- Dashboard LiveView tests: 57 tests, 0 failures.
- Conversation-detail tests: 25 tests, 0 failures.
- Dependency tree confirms `live_query (../packages/live_query)`.
- Web and package formatting checks.
- Stale namespace scan and `git diff --check`.
- Worker-result JSON parse validation.

The required result is recorded in [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json). There are no unresolved items. Per the packet’s explicit exclusion, I did not run `dev check`; the deterministic workflow’s later `dev_check` node owns that full gate.