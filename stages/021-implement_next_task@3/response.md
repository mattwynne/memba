Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 003 Implement `list_active_members_of_club/1` and supporting queries on the`

2. **Changes made**
   - Added public Membership boundary read model:
     - `Memba.Membership.ActiveMember` with `id`, `name`, and `email`.
   - Added query API in `Memba.Membership`:
     - `list_active_members_of_club/1`
       - Returns active members for the requested club only.
       - Excludes other clubs.
       - Excludes inactive membership projections.
       - Returns `[]` for missing/invalid club IDs.
     - `active_member_of_club?/2`
       - Public supporting query for active `{club_id, person_id}` membership checks.
       - Returns `false` for invalid IDs.
   - Added ExUnit coverage:
     - `web/test/memba/membership/active_members_query_test.exs`
   - Updated the no-CRUD boundary test to allow the planned public query while continuing to reject CRUD helper functions.
   - No acceptance `*.feature` files were changed.

3. **Focused validation**
   - TDD red check:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Failed as expected because `Memba.Membership.ActiveMember` was undefined.
   - Focused passing check:
     - `PATH="$PWD/bin:$PATH" devenv shell -- mix test test/memba/membership/active_members_query_test.exs test/memba/membership/no_crud_spike_test.exs`
     - Result: `8 tests, 0 failures`
   - Format check:
     - `PATH="$PWD/bin:$PATH" devenv shell -- mix format --check-formatted lib/memba/membership.ex lib/memba/membership/active_member.ex test/memba/membership/active_members_query_test.exs test/memba/membership/no_crud_spike_test.exs`
     - Result: exit 0
   - Required final gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `53 tests, 0 failures`, exit 0

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Implement `list_active_members_of_club/1` and supporting queries on the`
   - To:
     - `- [x] 003 Implement `list_active_members_of_club/1` and supporting queries on the`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0007: Messaging remains untouched; Membership exposes a public query API instead of requiring callers to know projection schemas/tables.
   - ADR 0011: The supporting `active_member_of_club?/2` query supports duplicate active membership checks for caller-generated `membership_id` workflows without changing aggregate identity rules.
   - ADR 0009: Queries read from Ecto projection tables created by Commanded projectors; no custom event handling or CRUD source-of-truth model was introduced.