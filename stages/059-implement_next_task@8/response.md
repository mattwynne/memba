Implemented and checked off task 008. Club activation now owns identity idempotency and reuse protection based entirely on rehydrated aggregate state.

1. Selected task

   `008 Make activation idempotent for an exact active identity and reject another active membership for the same person. Reject removed IDs known to Club without importing absent pre-cutover tombstones.`

2. Changes

   - Updated [club.ex](/workspace/memba/web/lib/memba/membership/club.ex:106) so:
     - An exact active `club_id` / `membership_id` / `person_id` activation returns an idempotent no-op.
     - Reusing an active membership ID for another person returns `:membership_id_already_used`.
     - Creating another active membership for the same person returns `:already_active_member`.
     - Membership IDs found in native lifecycle history or historic Everyone compatibility facts cannot be reused after removal.
     - A returning person can use a fresh membership ID; no external tombstones or projection lookups were introduced.
   - Added focused aggregate coverage in [club_test.exs](/workspace/memba/web/test/memba/membership/club_test.exs:231) for exact retries, identity mismatch, duplicate active membership, native removal history, compatibility removal history, and fresh returning-member identities.
   - No acceptance features, projections, public APIs, or later iteration behavior were changed.

3. Validation

   - TDD red run: focused Club test produced the expected 4 failures before implementation.
   - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/club_test.exs`
     - 41 tests, 0 failures.
   - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/club_test.exs test/memba/membership/club_replay_test.exs test/memba/membership/add_member_dispatch_test.exs`
     - 51 tests, 0 failures.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - 1,183 tests, 0 failures on the exact final worktree.
   - `git diff --check`
     - Passed.

4. Todo check-off

   Changed only task 008 from `- [ ]` to `- [x]` in [todo.md](/workspace/memba/docs/iterations/059-populated-clubs-always-have-an-admin/todo.md:10). Task 009 remains the first unchecked task.

5. Todo structure

   No tasks were split, added, removed, or reordered.

6. ADR conformance

   - ADR 0002: decisions remain event-sourced and enforced by the Club aggregate.
   - ADR 0007: all behavior remains inside the Membership bounded context.
   - ADR 0008: no existing event streams or historical facts were rewritten.
   - ADR 0009: existing projections remain unchanged.
   - ADR 0011: callers still provide typed UUID identities; Club now validates their aggregate-wide lifecycle uniqueness as required by the validated iteration plan.