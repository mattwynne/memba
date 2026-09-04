Implemented and checked off task 001.

1. Selected task

   `001 Verify iteration 056's group membership, system-group IDs, conversation access grant, public Membership queries, release backfill, and group-aware reply authorisation are implemented and passing before starting this plan.`

2. Changes made

   - Verified the iteration 056 implementation and its checkpoint/review evidence.
   - Increased the test SQL Sandbox pool in [test.exs](/workspace/memba/web/config/test.exs:18). The expanded iteration 056 projector set exhausted the previous pool during the event-sourced reset regression, causing reproducible consistency timeouts.
   - No domain behavior was recreated or changed.
   - Checked off task 001 in [todo.md](/workspace/memba/docs/iterations/057-admin-group-email-conversations/todo.md:3).

3. Validation

   - Focused Membership/Messaging/release foundation suite: `155 tests, 0 failures`.
   - Reproduced the reset regression before the configuration fix: consistency timeout caused by SQL Sandbox connection exhaustion.
   - Focused reset regression after the fix: `1 selected test, 0 failures`.
   - Final `PATH="$PWD/bin:$PATH" dev check --quick` on the exact staged diff: `1089 tests, 0 failures`.
   - `git diff --cached --check`: passed.

4. Exact todo check-off

   `- [x] 001 Verify iteration 056's group membership, system-group IDs, conversation access grant, public Membership queries, release backfill, and group-aware reply authorisation are implemented and passing before starting this plan.`

5. Todo changes

   No tasks were split, added, removed, or reordered. Only task 001 was checked off.

6. ADR conformance

   - ADR 0007: Messaging continues to use public Membership APIs such as `list_active_members_of_group/1` and `active_member_of_group?/2`; it does not query Membership projection schemas directly.
   - ADRs 0002, 0004, and 0009: group membership and conversation access remain event-sourced, with access represented by `ConversationAccessGrantedToGroup` and Ecto projections.
   - ADR 0011: Everyone and Admin retain deterministic, typed, club-scoped group IDs.
   - ADR 0022: strong projectors and projection barriers remain the consistency mechanism for read-after-write and replay verification.
   - Historic events remain untouched; the release backfill appends idempotent compensating facts through commands.