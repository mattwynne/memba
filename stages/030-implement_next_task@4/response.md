Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `004 Preserve the existing members **empty state** and the **Invite member** action from 045.`

2. **Changes made**
   - Added focused regression coverage in `web/test/memba_web/live/member_dashboard_live_test.exs`.
   - New test verifies a first-member Membership Admin on `/members` still sees:
     - the visible Members panel,
     - the tab-level `Invite member` action,
     - the members-panel `Invite member` action,
     - the first-member empty state,
     - the named member row.
   - No app template/CSS/feature-file changes were made.

3. **Validation**
   - Passed focused test:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
     - Result: `26 tests, 0 failures`
   - Ran broad quick check:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: failed with 5 failures in unrelated existing test files.
   - Re-ran only those failing files:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/club_site_shell_surfaces_test.exs test/memba_web/member_page_design_system_alignment_test.exs test/memba_web/live/admin/club_member_invitations_live/new_test.exs test/memba_web/live/member_invitation_live/send_test.exs`
     - Result: same `12 tests, 5 failures`, confirming they are outside this selected task’s changed file/scope.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Preserve the existing members **empty state** and the **Invite member** action from 045.`
   - To:
     - `- [x] 004 Preserve the existing members **empty state** and the **Invite member** action from 045.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no explicit ADRs.
   - Inspected relevant accepted ADRs: Phoenix core app, PhoenixTest/web testing, LiveView member pages, and URL-addressable LiveView state.
   - This task stays within existing Phoenix LiveView test coverage, adds no custom JS, no route/state changes, and no acceptance feature-file changes.