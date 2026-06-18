### Decision

**VALID**

### Evidence

- Completed todo/check-off evidence found:
  - Read `/tmp/fabro-pre-validate-snapshot.md`; it records clean worktree at implementation checkpoint `6bdcc58`.
  - Live `git status --short` and `git diff` are clean.
  - Recent log shows `b35bb4e` pre-validation checkpoint on top of `6bdcc58` implementation checkpoint.
  - `git diff 6bdcc58^ 6bdcc58 -- docs/iterations/035-obliterate-opened-delivery-status/todo.md` shows exactly one ordinary task changed:
    - `007 Add the historic-event replay-safety regression test.`
    - from `- [ ]` to `- [x]`.
  - Parent todo state confirms `007` was the first unchecked task when implementation started.

- Implementation artifacts found:
  - Added `web/test/memba/messaging/email_delivery_opened_replay_test.exs`.
  - The regression persists a historic `EmailDeliveryOpened` event directly into the message aggregate stream, waits for member/staff delivery projectors, asserts read models remain `sent`, forces aggregate replay, rebuilds projections from retained EventStore history, and asserts projections/read models remain unaffected.
  - Updated `web/test/support/event_sourced_case.ex` with replay/rebuild helpers for stopping cached aggregates, resetting projection state without deleting EventStore history, clearing Commanded subscription acknowledgements, and deleting EventStore subscription checkpoints.
  - No acceptance `.feature` files were edited.

- Tests run/results found:
  - Live validation run: `PATH="$PWD/bin:$PATH" dev check --quick`
    - Passed: `799 tests, 0 failures`.
  - `git diff --check 6bdcc58^..6bdcc58` passed.
  - Worktree remained clean after validation.

- ADR/plan conformance notes:
  - Work matches plan item `007` and the acceptance criterion requiring a regression test for historic `EmailDeliveryOpened` replay/rebuild safety.
  - Scope is plan-preserving: it adds test coverage and narrowly reusable test helpers; it does not reintroduce opened as live product behaviour.
  - Relevant ADR constraints are respected:
    - ADR 0004: event appended to the message aggregate stream.
    - ADR 0007: uses the Messaging Commanded app.
    - ADR 0008: exercises persistent PostgreSQL EventStore test path.
    - ADR 0009: exercises Commanded Ecto projection replay/checkpoint behaviour.
  - ADRs 0006/0012 are historical context for opened status; this task only verifies tombstone replay compatibility required by the current accepted iteration plan.

{"context_updates":{"task_valid":true,"task_retry_available":false}}