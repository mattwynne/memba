Implemented the next unchecked task.

1. **Selected todo line**
   - `007 Add a public Membership query/API for permission checks, for example “does this person have `club.manage_members` in this club?”. Exact function names are implementation details.`

2. **Changes made**
   - Added backend-only internal authorization helper:
     - `web/lib/memba/membership/authorization.ex`
     - Reads `membership_member_permissions` via `Memba.Membership.Projections.MemberPermission`.
     - Validates club ID, person ID, and app-defined permission before querying.
   - Added backend Elixir context API:
     - `Memba.Membership.person_has_club_permission?/3`
     - Delegates to `Memba.Membership.Authorization.has_permission?/3`.
   - Added tests:
     - `web/test/memba/membership/authorization_test.exs`
     - Extended `web/test/memba/membership/public_api_test.exs`
   - No HTTP routes, controllers, endpoints, or web API surfaces were added.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format lib/memba/membership.ex lib/memba/membership/authorization.ex test/memba/membership/public_api_test.exs test/memba/membership/authorization_test.exs`
     - Passed.
   - Direct focused test attempt with `PATH="$PWD/bin:$PATH" bin/mix test ...`
     - Blocked by sandbox PGHOST readiness mismatch.
   - Reran focused tests inside devenv shell:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/authorization_test.exs test/memba/membership/public_api_test.exs'`
     - Passed: `13 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `648 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 007 Add a public Membership query/API for permission checks, for example “does this person have `club.manage_members` in this club?”. Exact function names are implementation details.`
   - To:
     - `- [x] 007 Add a public Membership query/API for permission checks, for example “does this person have `club.manage_members` in this club?”. Exact function names are implementation details.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002: permission checks read from CQRS projection state, not ad hoc mutable domain state.
   - ADR 0007: exposes the check through the Membership bounded-context Elixir API; no other context or web layer reaches into projection tables directly.
   - ADR 0008: validation used persistent EventStore-backed tests.
   - ADR 0009: relies on the Commanded/Ecto-projected `membership_member_permissions` read model.
   - ADR 0022: tests use strong consistency around role assignment/removal before reading projected permissions.