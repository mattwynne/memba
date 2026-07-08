1. **Selected todo line**
   - `002 Extend Membership.list_active_members_of_club/1 to include roles: [...] for each active member. Use active role assignments only and sort each member's role names alphabetically.`

2. **Changes made**
   - Updated `web/lib/memba/membership.ex`
     - `list_active_members_of_club/1` now returns each active member map with `roles: [...]`.
     - Role names are fetched from active `RoleAssignment` rows joined to `RoleProjection`.
     - Role names are sorted alphabetically per member.
     - Members with no active roles receive `roles: []`.
     - Invalid club IDs still return `[]`.
   - Updated `web/test/memba/membership/query_test.exs`
     - Added a focused test proving active role names are included and sorted alphabetically.
     - Test also proves a member with no roles receives `roles: []`.
     - Added small role-definition/assignment helpers for that test.
   - Updated `docs/iterations/049-member-role-badges/todo.md`
     - Checked off only task `002`.

3. **Focused validation**
   - Added the test first and ran:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/query_test.exs`
     - Result before implementation: failed as expected because member maps lacked `roles`.
   - After implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/query_test.exs`
     - Result: passed — `17 tests, 0 failures`.
   - Broader per-task check:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: failed with 5 unrelated existing web-test failures:
       - `MembaWeb.MemberPageDesignSystemAlignmentTest`
       - `MembaWeb.ClubSiteShellSurfacesTest` x2
       - `MembaWeb.Admin.ClubMemberInvitationsLive.NewTest`
       - `MembaWeb.MemberInvitationLive.SendTest`
     - These failures are unrelated to the Membership query change; I did not modify unrelated web/design/redirect behaviour.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 002 Extend Membership.list_active_members_of_club/1 ...`
   - To:
     - `- [x] 002 Extend Membership.list_active_members_of_club/1 ...`

5. **Todo splits/additions/reordering**
   - None.
   - Task `003` remains unchecked for the broader required query-test coverage, including removed-member cases.

6. **ADR conformance**
   - ADR 0002: Kept this as a query/read-model change over existing projections; no write-side shortcut introduced.
   - ADR 0007: Stayed inside the Membership context public query API.
   - ADR 0009: Used existing Ecto projection schemas (`RoleAssignment`, `RoleProjection`) rather than custom projection plumbing.
   - ADR 0021/0022: Did not change projector publication or projection-barrier behaviour.