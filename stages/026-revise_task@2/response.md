Implemented packet `task-008a-59e50fa-contract-lifecycle-revision-3` with result `ready_for_review`.

Changes:

- Added the application-owned [`ReadModelContractViolationError`](/workspace/memba/web/lib/memba_web/live_query/read_model_contract_violation_error.ex:1), exposing projector, source-event module, and reason without retaining event payloads.
- Updated [`MembaReadModelSource`](/workspace/memba/web/lib/memba_web/live_query/memba_read_model_source.ex:103) to require complete, correctly typed publisher envelopes and raise the stable exception for recognized malformed or unsupported events.
- Expanded [`memba_read_model_source_test.exs`](/workspace/memba/web/test/memba_web/live_query/memba_read_model_source_test.exs:107) with ordinary `Binding.handle_notification/2`, bind-window reconciliation, malformed-envelope, and exception field/message coverage.
- Wrote the required result artifact, including the eleven-projector-family evidence table, to [`latest-worker-result.json`](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json:1).

Validation passed:

- Focused adapter suite: 28 tests, 0 failures.
- Dashboard and conversation-detail query regressions: 8 tests, 0 failures.
- Formatting check passed.
- `git diff --check` passed.
- Generic package boundary check passed.
- No unresolved items or publisher-envelope conflicts found.

Task 008A remains unchecked as required. I did not run `dev check` or rerun the acceptance scenario because this packet explicitly reserves the full gate for the deterministic workflow node.