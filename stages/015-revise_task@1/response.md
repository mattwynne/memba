Implemented packet `task-008a-0c2dbfb-noop-identity-revision-4` with result `ready_for_review`.

Changes:

- Updated [memba_read_model_source.ex](/workspace/memba/web/lib/memba_web/live_query/memba_read_model_source.ex) so required identities are validated before:
  - ignoring false-auto-follow `MessageSent` notifications;
  - ignoring replay-only `EmailDeliveryOpened` notifications for either delivery projector.
- Added focused coverage in [memba_read_model_source_test.exs](/workspace/memba/web/test/memba_web/live_query/memba_read_model_source_test.exs) for every required identity, both delivery projectors, and resistance to projection-row or committed-changes recovery.
- Wrote [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json).
- Left `todo.md` unchecked and untouched.

Validation:

- Initial TDD run: expected failure, 30 tests with 2 failures. Both reported `Expected exception MembaWeb.LiveQuery.ReadModelContractViolationError but nothing was raised`.
- Focused adapter suite: 30 tests, 0 failures.
- `bin/mix format --check-formatted`: passed.
- `git diff --check`: passed.
- Worker result JSON parsing: passed.

No unresolved issues were found. Per the packet’s binding instructions, I did not run the unscoped `dev check`; the deterministic workflow node owns that final gate.