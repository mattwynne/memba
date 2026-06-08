1. **Selected todo line**
   - `- [ ] 003 Add a member-facing route/action for inviting club members, scoped to the current club.`

2. **Changes made for this task**
   - Added member-facing LiveView route:
     - `GET /members/invitations/new`
     - `MembaWeb.MemberInvitationLive.New`
     - routed through `[:browser, :club_member_required]`
   - Added `MembaWeb.MemberInvitationLive.New`:
     - Uses the existing club-member LiveView session/host scoping pattern.
     - Supports both:
       - query-host URL: `/members/invitations/new?club_id=<club_id>`
       - club-subdomain URL: `/members/invitations/new`
     - Renders a club-scoped invitation entry page with:
       - `#member-club-invitation-new`
       - selected club data
       - current member data
       - host/query-aware “Club home” link.
   - Updated the dashboard invitation link helper to use verified `~p` routes now that the route exists.
   - Added tests:
     - Router test proving `/members/invitations/new` routes through the club-member-required pipeline.
     - LiveView tests proving query-host and club-subdomain scoping.
     - Signed-out redirect/return-path coverage for the new route.

3. **Validation commands/results**
   - Attempted focused test command:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/router_test.exs test/memba_web/live/member_invitation_live/new_test.exs`
     - Result: did not reach tests due sandbox Postgres readiness/lock wrapper issue.
   - Broad ExUnit validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: passed — `727 tests, 0 failures`.
   - Full required validation for routing/browser-facing UI change:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: passed — `727 tests, 0 failures`; acceptance `69 scenarios (69 passed)`, `466 steps (466 passed)`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 003 Add a member-facing route/action for inviting club members, scoped to the current club.`
   - To:
     - `- [x] 003 Add a member-facing route/action for inviting club members, scoped to the current club.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0015: implemented the new member-facing app surface as a LiveView.
   - ADR 0013: added user-visible route/LiveView tests.
   - ADR 0009: reused existing projection-backed club/member reads; no parallel membership state.
   - ADR 0022: introduced no command/write flow in this task, so no new read-your-writes synchronization need.