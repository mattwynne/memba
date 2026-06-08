1. **Selected todo line**
   - `- [ ] 002 Inspect current member-facing club pages to find whether a members list already exists. If it exists, add the invite action there for Membership Admins. If it does not, add the smallest member-facing club members/admin page needed to host the invite action.`

2. **Changes made**
   - Confirmed an existing member-facing members surface:
     - `MemberDashboardLive` rendering `section#club-members` in `web/lib/memba_web/controllers/page_html/club.html.heex`.
   - Added the Membership Admin invite affordance to that existing members section:
     - Link id: `#member-invite-member-link`
     - Copy: `Invite member`
     - Query-host href: `/members/invitations/new?club_id=<club_id>`
     - Club-subdomain href: `/members/invitations/new`
   - Added permission-derived visibility:
     - `MembaWeb.MemberDashboardPresentation` now assigns `current_member_can_manage_members?`
     - Uses existing `Memba.Membership.Authorization.authorize_manage_members/2`
   - Added LiveView tests proving:
     - A member with `club.manage_members` sees the invite action.
     - An ordinary member does not see it.
   - Added inspection note:
     - `docs/iterations/029-membership-admin-invitations/member-facing-club-surface-inspection.md`
   - Checked off only task 002 in `todo.md`.

3. **Focused validation commands/results**
   - Attempted direct focused test:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/member_dashboard_live_test.exs`
     - Result: failed due sandbox wrapper/Postgres readiness tooling outside the devenv shell, not due test failures.
   - Ran broad quick gate through project wrapper:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: passed — `723 tests, 0 failures`.
   - Ran full required gate because this changed member-facing UI:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: passed — `723 tests, 0 failures`; acceptance `69 scenarios (69 passed)`, `466 steps (466 passed)`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 002 Inspect current member-facing club pages to find whether a members list already exists. If it exists, add the invite action there for Membership Admins. If it does not, add the smallest member-facing club members/admin page needed to host the invite action.`
   - To:
     - `- [x] 002 Inspect current member-facing club pages to find whether a members list already exists. If it exists, add the invite action there for Membership Admins. If it does not, add the smallest member-facing club members/admin page needed to host the invite action.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0009: uses the existing Ecto projection-backed member permission read model.
   - ADR 0013: added user-visible LiveView test coverage for the new web affordance.
   - ADR 0015: kept the member app affordance on the existing LiveView-backed dashboard.
   - ADR 0022: introduced no new command/read-after-write flow in this task; route/submission work remains for later tasks.