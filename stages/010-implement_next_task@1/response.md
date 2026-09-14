Implemented task 012 and closed the concurrent rapid re-add race.

1. Selected task

   `- [ ] 012 Ensure removal completion/rapid re-add cannot reactivate stale follows.`

2. Changes made

   - Updated [membership.ex](/workspace/memba/web/lib/memba/membership.ex:272) so both member removal and member addition use the same lifecycle consistency barrier.
   - A concurrent `add_member/2` now waits for `ClearRemovedGroupMemberFollows` to process all earlier events on the Club stream before reporting the re-add complete.
   - Preserved the existing removal-side guarantee that system-group changes and custom-group follow cleanup complete before `remove_member/2` returns.
   - Strengthened [clear_removed_group_member_follows_policy_test.exs](/workspace/memba/web/test/memba/membership/clear_removed_group_member_follows_policy_test.exs:79) to suspend follow cleanup, begin removal, attempt a concurrent re-add, and prove the re-add cannot complete until cleanup resumes. The test then confirms the stale follow is gone, the former custom membership stays inactive, and only the new Everyone membership becomes active.

3. Validation

   - Red test before implementation: concurrent re-add returned `{:ok, :ok}` while follow cleanup was paused.
   - Focused rapid-re-add test after implementation: 4 tests, 0 failures.
   - Focused Membership regression set: 38 tests, 0 failures.
   - Wider lifecycle/invitation regression set: 55 tests, 0 failures.
   - `mix format --check-formatted` for both touched files: passed.
   - `dev check --quick`: exited 0 with 1,319 tests and 0 failures. The exact final diff was subsequently rechecked with the focused 38-test run and formatting check.
   - Full browser-inclusive `dev check` was not run in this ordinary per-task node; the workflow’s final deterministic gate owns that run.

4. Todo state

   The exact selected line remains unchanged and unchecked in [todo.md](/workspace/memba/docs/iterations/062-create-custom-groups/todo.md:14):

   `- [ ] 012 Ensure removal completion/rapid re-add cannot reactivate stale follows.`

5. Todo changes

   None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

   - ADR 0002: uses Commanded event-handler consistency and persisted lifecycle events.
   - ADR 0007: preserves the Membership/Messaging context boundary; no direct Messaging persistence access or projector side effects were introduced.
   - ADR 0022: uses the domain-specific strongly consistent handler completion signal required for this cross-context consequence.
   - ADR 0024: relies on ordered events from the existing Club consistency boundary, including concurrent removal and re-add commands; no competing aggregate or projection-backed write invariant was added.
   - ADR 0011: rejoining continues to use a new caller-generated membership identity.