1. **Selected todo line**
   - `003 Add or update Membership query tests covering: members with no roles, members with multiple roles sorted alphabetically, and removed members not appearing even when they had roles.`

2. **Changes made**
   - Updated `web/test/memba/membership/query_test.exs`
     - Added `RemoveMember` command alias.
     - Added query test: removed members are excluded from `Membership.list_active_members_of_club/1` even when they previously had an assigned role.
     - Added `remove_member/1` test helper using `App.dispatch(..., consistency: :strong)`.
   - Updated `docs/iterations/049-member-role-badges/todo.md`
     - Checked off only task `003`.

3. **Focused validation**
   - Ran:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/query_test.exs`
   - Result:
     - Passed: `18 tests, 0 failures`
   - Ran broad per-task check:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
   - Result:
     - The output still reports the same 5 unrelated existing web-test failures noted by the prior checkpoint:
       - `MembaWeb.ClubSiteShellSurfacesTest` x2
       - `MembaWeb.MemberPageDesignSystemAlignmentTest`
       - `MembaWeb.MemberInvitationLive.SendTest`
       - `MembaWeb.Admin.ClubMemberInvitationsLive.NewTest`
     - The Membership query test file passed.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 003 Add or update Membership query tests covering: members with no roles, members with multiple roles sorted alphabetically, and removed members not appearing even when they had roles.`
   - To:
     - `- [x] 003 Add or update Membership query tests covering: members with no roles, members with multiple roles sorted alphabetically, and removed members not appearing even when they had roles.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan did not explicitly reference ADR files.
   - This task only adds Membership query tests and uses existing Commanded commands/projections through established test helpers.
   - No write-side shortcuts, UI queries, acceptance feature edits, or architecture changes were introduced.