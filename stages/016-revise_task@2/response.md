Implemented the revision for task 012 and addressed the replay-safety verdict.

1. Selected task

   `- [ ] 012 Ensure removal completion/rapid re-add cannot reactivate stale follows.`

2. Changes made

   - Updated the [Membership projector](/workspace/memba/web/lib/memba/membership/projectors/membership.ex:42) to gate activation on the cleanup policy’s durable global EventStore checkpoint.
   - Removed reliance on Commanded’s volatile acknowledgement cache and Club-stream versions.
   - Legacy `MemberAdded` events now use their global event number, avoiding the invalid combination of a membership-stream version with a Club stream identity.
   - An independently rebuilt Membership projection can reuse the cleanup policy’s persisted progress without replaying that policy.
   - Strengthened the [lifecycle policy tests](/workspace/memba/web/test/memba/membership/clear_removed_group_member_follows_policy_test.exs:53) to cover:
     - volatile acknowledgement loss with legacy membership-ID stream metadata;
     - an isolated Membership projector rebuild;
     - synchronization on the exact persisted re-add event;
     - proof that aggregate re-addition has committed while projected membership remains inactive;
     - no private reply delivery while cleanup is suspended;
     - activation only after cleanup completes, without restoring the old custom membership or follow.

3. Validation

   - TDD red run against the previous implementation: 5 tests, 1 failure with `:removed_group_member_follow_cleanup_restarted`.
   - Race suite repeated consecutively: 6 runs, all passing.
   - Focused lifecycle/replay/projection set: 21 tests, 0 failures.
   - Full Membership test directory: 318 tests, 0 failures.
   - Final focused policy suite: 6 tests, 0 failures.
   - `mix format --check-formatted` for both changed files: passed.
   - `git diff --check`: passed.
   - `dev check --quick`: exited 0 with 1,321 tests and 0 failures.

4. Todo state

   The selected line remains unchanged and unchecked in [todo.md](/workspace/memba/docs/iterations/062-create-custom-groups/todo.md:14):

   `- [ ] 012 Ensure removal completion/rapid re-add cannot reactivate stale follows.`

5. Todo changes

   None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

   - ADR 0002/0009: retains Commanded event sourcing and the standard Ecto projector, using persisted subscription progress for replay.
   - ADR 0007: follow clearing remains in the Membership-to-Messaging policy through public Messaging APIs; the projector performs no cross-context side effects.
   - ADR 0011: rapid rejoining continues to use a new caller-generated membership identity.
   - ADR 0022: uses a durable checkpoint barrier and waits for a committed read-model notification in the race test.
   - ADR 0024: preserves Club as the lifecycle consistency boundary and correctly handles historical events originating on membership-ID streams.