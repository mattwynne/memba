Implemented the revision for task 012 and closed the observable rapid re-add race.

1. Selected task

   `- [ ] 012 Ensure removal completion/rapid re-add cannot reactivate stale follows.`

2. Changes made

   - Updated the [Membership projector](/workspace/memba/web/lib/memba/membership/projectors/membership.ex:27) so modern and legacy member-add events are not projected as active until `ClearRemovedGroupMemberFollows` has processed that Club-stream event.
   - The barrier verifies that the same cleanup-handler process remains registered, preventing handler absence or restart from producing a false-positive completion.
   - Started the cleanup policy before the dependent Membership projector in [application.ex](/workspace/memba/web/lib/memba/application.ex:28).
   - Preserved the previous caller-completion barrier in `Membership.add_member/2`.
   - Strengthened the [rapid re-add race test](/workspace/memba/web/test/memba/membership/clear_removed_group_member_follows_policy_test.exs:82). While cleanup is suspended, it now proves:
     - the committed re-add is not exposed as active;
     - a concurrent private-group reply creates no delivery for the departed member;
     - the re-add call remains pending;
     - after cleanup resumes, membership becomes active while the old custom membership and stale follow remain inactive.

3. Validation

   - TDD red run: focused policy test failed because the re-added member was prematurely visible as active.
   - Focused lifecycle test: 4 tests, 0 failures.
   - Membership regression suite: 316 tests, 0 failures.
   - Focused projection/replay/reply set on the final implementation: 14 tests, 0 failures.
   - Formatting check for all affected files: passed.
   - `dev check --quick`: 1,319 tests, 0 failures.
   - The successfully checked diff is staged exactly, with no unstaged changes. Full browser-inclusive `dev check` remains with the workflow’s final deterministic gate.

4. Todo state

   The selected line remains unchanged and unchecked in [todo.md](/workspace/memba/docs/iterations/062-create-custom-groups/todo.md:14):

   `- [ ] 012 Ensure removal completion/rapid re-add cannot reactivate stale follows.`

5. Todo changes

   None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

   - ADR 0002: uses persisted lifecycle events and Commanded’s ordered subscription acknowledgements.
   - ADR 0007: cross-context unfollowing remains in the Membership-to-Messaging policy; the projector performs no Messaging calls or side effects.
   - ADR 0011: rapid rejoining continues to use a new caller-generated membership identity.
   - ADR 0022: uses a domain-specific handler-completion barrier rather than treating a projection checkpoint as proof that asynchronous cleanup finished.
   - ADR 0024: Club-stream ordering remains the lifecycle consistency boundary; no projection-backed write invariant or competing aggregate was introduced.