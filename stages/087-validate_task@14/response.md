### Decision

**VALID**

### Evidence

- Completed todo/check-off evidence found.
  - Read `/tmp/fabro-pre-validate-snapshot.md`: tracked working tree was clean at snapshot time, with only untracked `.fabro/tmp/`.
  - Live `git status --short` shows only `?? .fabro/tmp/`.
  - Recent commits show `da3ff5e fabro(...): implement_next_task (succeeded)` followed by `4cf39e1 pre_validate_snapshot`.
  - `git diff da3ff5e^ da3ff5e -- docs/iterations/020-migrate-production-email-to-postmark/todo.md` shows exactly one ordinary task line changed:
    - task `014` from `- [ ]` to `- [x]`.
  - Parent todo state confirms tasks `001`–`013` were already checked and task `014` was the first unchecked task.

- Implementation artifacts found.
  - Commit `da3ff5e` changed:
    - `docs/adr/0016-use-resend-as-switchable-email-provider.md`
    - `docs/iterations/020-migrate-production-email-to-postmark/todo.md`
  - ADR 0016 now records:
    - Postmark as the intended primary production provider after approval/setup.
    - Resend as a first-class fallback, not deprecated.
    - Distinct Postmark inbound route: `POST /webhooks/postmark/inbound`.
    - Continued test/documentation coverage for both providers unless a later ADR/iteration replaces the rollback strategy.
  - No acceptance feature files were changed.

- Tests run/results found.
  - Live `git diff --check da3ff5e^ da3ff5e` passed.
  - This was a docs/ADR-only task; no automated app tests were required for this checkpoint. The explicit targeted-test and `dev check` tasks remain unchecked as tasks `015` and `016`.

- ADR/plan conformance notes.
  - The implementation matches plan task `014`.
  - Scope stays within the approved plan and does not delete, weaken, split, or reorder remaining work.
  - ADR 0016 remains respected while updating the provider posture for iteration 020.
  - ADR 0014/0017 constraints are preserved: production cutover remains documented/manual, not performed by code changes.
  - The checkpoint is small, focused, and independently useful.

{"context_updates":{"task_valid":true,"task_retry_available":false}}