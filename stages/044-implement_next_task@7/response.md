Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `002b2 Add the Membership Admin invite action to the existing member dashboard #club-members section once the member-facing invitation route/action is in place.`

2. **Changes made**
   - Added a permission-gated **Invite member** link inside `#club-members` in `web/lib/memba_web/controllers/page_html/club.html.heex`.
   - Added `member_invitation_path/2` in `web/lib/memba_web/controllers/page_html.ex`:
     - Query-selected club: `/members/invitations/new?club_id=...`
     - Club subdomain/host-selected club: `/members/invitations/new`
   - Added dashboard LiveView tests in `web/test/memba_web/live/member_dashboard_live_test.exs` proving:
     - Membership Admins see the invite action in `#club-members`.
     - Club subdomain dashboards use the host-scoped invitation link.
   - Extended the dashboard test helper to grant `club.manage_members` permission through the projected `MemberPermission` read model.

3. **Validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format test/memba_web/live/member_dashboard_live_test.exs lib/memba_web/controllers/page_html.ex lib/memba_web/controllers/page_html/club.html.heex` — passed.
   - `devenv shell -- bin/mix test test/memba_web/live/member_dashboard_live_test.exs:400 test/memba_web/live/member_dashboard_live_test.exs:423` — passed, `15 tests, 0 failures, 13 excluded`.
   - `devenv shell -- bin/mix test test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/club_member_invitations_live/new_test.exs` — passed, `20 tests, 0 failures`.
   - `git diff --check` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed, including `69 scenarios (69 passed)`.

   Note: the direct `PATH="$PWD/bin:$PATH" bin/mix test ...` attempt hit the known sandbox `PGHOST` readiness mismatch before tests started, so I used `devenv shell -- ...` for the focused test runs.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 002b2 Add the Membership Admin invite action to the existing member dashboard #club-members section once the member-facing invitation route/action is in place.`
   - To:
     - `- [x] 002b2 Add the Membership Admin invite action to the existing member dashboard #club-members section once the member-facing invitation route/action is in place.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: remains within Phoenix/Phoenix LiveView.
   - ADR 0007: uses Membership context permission/read-model boundaries.
   - ADR 0009: authorization state is read from projected membership permission state.
   - ADR 0015: member-facing app UI remains LiveView-backed and covered by LiveView tests.