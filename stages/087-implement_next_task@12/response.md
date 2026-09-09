Implemented task 012: “Thin `Memba.Membership` write APIs around Club decisions.”

1. Selected task

   Checked off [todo.md](/workspace/memba/docs/iterations/059-populated-clubs-always-have-an-admin/todo.md:14):

   `- [x] 012 Thin Memba.Membership write APIs around Club decisions...`

2. Changes

   - [membership.ex](/workspace/memba/web/lib/memba/membership.ex:253) now dispatches membership activation without consulting the membership projection for duplicate or first-member decisions.
   - Invitation activation no longer performs the same projection-backed duplicate preflight.
   - Role-assignment APIs retain projected actor authorization but delegate target activity checks to the Club aggregate.
   - Role-removal APIs delegate role-assignment validity and the Admin floor to the Club aggregate.
   - `remove_member/2` may still enrich omitted club/person routing fields from the membership projection, but the Club aggregate decides identity validity and membership/Admin floors.
   - Removed the obsolete projection-backed duplicate, active-membership, and Admin-count helper functions.
   - Added [write_api_test.exs](/workspace/memba/web/test/memba/membership/write_api_test.exs:1), with deliberately stale or absent projections proving that Club stream state decides:
     - first membership and duplicate activation;
     - exact activation idempotency;
     - role-assignment target activity;
     - the active-Admin floor;
     - the final-member floor.

3. Validation

   - Red TDD run: `dev test test/memba/membership/write_api_test.exs`
     - 4 tests, 3 expected failures from the old projection preflights.
   - Green focused run: same command
     - 4 tests, 0 failures.
   - Aggregate regression run:
     - `dev test test/memba/membership/write_api_test.exs test/memba/membership/club_test.exs test/memba/membership/club_replay_test.exs`
     - 59 tests, 0 failures.
   - `mix format` completed for both touched Elixir files.
   - `git diff --check` passed.
   - `dev check --quick` reached 1,194 tests and remains red with 74 downstream failures—the same failure count present before task 012, with four new passing tests. Those failures concern onboarding, invitation result expectations, projection/system-group fixtures, and first-member ordering assigned to tasks 013–023.

4. Todo check-off

   Only task 012 changed from unchecked to checked.

5. Todo structure

   No tasks were split, added, removed, or reordered.

6. ADR conformance

   - ADR 0002: write invariants are now decided from the event-sourced Club aggregate.
   - ADR 0007: all changes remain inside the Membership bounded context.
   - ADRs 0008 and 0009: existing EventStore persistence and Ecto projections are retained; projections remain usable for queries, authorization, and routing enrichment.
   - ADR 0011: caller-generated typed identities remain unchanged.
   - ADR 0022: no projection synchronization is used to turn read models into write-authority checks.