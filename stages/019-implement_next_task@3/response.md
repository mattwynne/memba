Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 003 Implement `list_active_members_of_club/1` and supporting queries on the`

2. **Changes made**
   - Added Membership public query API in `web/lib/memba/membership.ex`:
     - `list_active_members_of_club/1`
       - Returns `%{id, name, email}` maps for active members.
       - Excludes members of other clubs.
       - Excludes inactive memberships.
       - Returns `[]` for missing/invalid club IDs.
     - `active_member_of_club?/2`
       - Supporting boundary query for checking active `{club_id, person_id}` membership.
       - Returns `false` for invalid IDs.
   - Added query API coverage in `web/test/memba/membership/query_test.exs`.
   - Updated the existing no-CRUD guard test to allow the explicitly planned `list_active_members_of_club/1` query while continuing to reject generic CRUD helpers.

3. **Validation**
   - `PATH="$PWD/bin:$PATH" dev test web/test/memba/membership/query_test.exs`
     - Failed because `dev` has no `test` subcommand; not a code failure.
   - `cd web && mix format --check-formatted`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Initially failed due the stale no-CRUD guard rejecting any `list_*` query.
   - After updating that guard:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `53 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Implement `list_active_members_of_club/1` and supporting queries on the`
   - To:
     - `- [x] 003 Implement `list_active_members_of_club/1` and supporting queries on the`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007: Membership exposes recipient-resolution data through the public `Memba.Membership` query API; no Messaging code or direct cross-context schema access was added.
   - ADR 0011: Queries use caller-generated UUID fields (`club_id`, `person_id`) and validate/cast IDs at the boundary. `active_member_of_club?/2` provides the public query needed to support duplicate-active-membership prevention without using natural keys as aggregate identities.