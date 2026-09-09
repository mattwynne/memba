Implemented task 007. The unused membership-ID aggregate is gone, leaving Club as the only write boundary for membership activation and removal.

1. Selected todo line

   `007 Remove the legacy Membership aggregate if unused; otherwise mark it unregistered legacy replay code and create a named deletion follow-up. Never expose a second write path.`

2. Changes made

   - Deleted the unused `Memba.Membership.Membership` aggregate and its obsolete aggregate tests.
   - Confirmed no runtime or replay-only caller referenced the aggregate. Historic events remain replayable through their existing projectors and Club compatibility handling.
   - Added a regression assertion in [add_member_dispatch_test.exs](/workspace/memba/web/test/memba/membership/add_member_dispatch_test.exs:13) proving the legacy aggregate module is unavailable. Existing assertions continue proving both commands use the Club aggregate UUID.
   - Clarified Club-only routing in [router.ex](/workspace/memba/web/lib/memba/membership/router.ex:2).
   - Removed stale “membership aggregate identity” terminology from [membership.ex](/workspace/memba/web/lib/memba/membership.ex:253).

3. Validation

   - TDD red state: focused test failed as expected before deletion — 3 tests, 1 failure.
   - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/add_member_dispatch_test.exs`
     - 3 tests, 0 failures.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - 1,179 tests, 0 failures.
   - `git diff --check`
     - Passed.
   - Runtime-source search confirmed no remaining aggregate definition or membership-ID router registration.

4. Todo check-off

   Changed only task 007 from `- [ ]` to `- [x]` in [todo.md](/workspace/memba/docs/iterations/059-populated-clubs-always-have-an-admin/todo.md:9). Task 008 remains first unchecked.

5. Todo structure

   No tasks were split, added, removed, or reordered. No deletion follow-up was needed because the aggregate had no remaining caller.

6. ADR conformance

   - ADR 0002: membership lifecycle decisions remain event-sourced through the invariant-owning Club aggregate.
   - ADR 0007: all changes remain within the Membership bounded context.
   - ADR 0008: historic membership streams and existing event facts were left immutable.
   - ADR 0009: existing `MemberAdded` and `MemberRemoved` projectors were retained unchanged.
   - ADR 0011: caller-generated typed membership IDs remain part of commands and events; only the aggregate routing identity is now the Club ID, as required by the validated iteration plan.