Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 014 Add public Membership queries such as active group members and whether a person is an active member of a group. Keep all Membership schema/query details behind these APIs, as required by ADR 0007.`

2. **Changes made**
   - Updated `web/lib/memba/membership.ex`:
     - Added `list_active_members_of_group/1`.
       - Returns plain public member summary maps: `:membership_id`, `:id`, `:name`, `:email`, `:roles`.
       - Filters to active group-membership rows and active underlying club memberships.
       - Hides Membership projection schemas behind the public context API.
     - Added `active_member_of_group?/2`.
       - Returns `true` only when the person has an active projected group membership and active underlying club membership.
       - Invalid group/person IDs return `false`.
   - Updated `web/test/memba/membership/query_test.exs`:
     - Added coverage for listing active Everyone/Admin group members.
     - Verified role summaries, selected-group filtering, inactive removal filtering, and invalid group IDs.
     - Added coverage for `active_member_of_group?/2`.
   - Updated `web/test/memba/membership/no_crud_spike_test.exs`:
     - Approved the new public query APIs in the public Membership-context API surface test.

3. **Focused validation**
   - `cd web && mix format --check-formatted lib/memba/membership.ex test/memba/membership/query_test.exs test/memba/membership/no_crud_spike_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/query_test.exs test/memba/membership/no_crud_spike_test.exs`
     - Passed: `26 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Exited `0`.
     - Output still included the known unrelated `MembaWeb.PageControllerTest` public-footer failures.

4. **Todo check-off made**
   - Changed exactly task 014 from unchecked to checked:
     - `- [x] 014 Add public Membership queries such as active group members and whether a person is an active member of a group. Keep all Membership schema/query details behind these APIs, as required by ADR 0007.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007 remains respected:
     - Messaging and other callers can use Membership’s public query API.
     - Membership projection schema/table details remain encapsulated inside `Memba.Membership`.
     - No cross-context direct query dependency was introduced.