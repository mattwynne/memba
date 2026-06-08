1. **Selected todo line**
   - `003 Add a member-facing route/action for inviting club members, scoped to the current club.`

2. **Changes made**
   - Added member-facing LiveView route:
     - `GET /members/invitations/new`
     - Routed through existing `[:browser, :club_member_required]` pipeline.
     - Uses existing `:club_member` live session and host/query club selection semantics.
   - Added new LiveView:
     - `web/lib/memba_web/live/member_invitation_live/new.ex`
     - Renders a club-site-layout invitation page shell scoped to the selected club.
     - Supports:
       - Query-selected club: `/members/invitations/new?club_id=<club_id>`
       - Host-selected club: `/members/invitations/new`
     - Includes stable selectors:
       - `#member-club-invitation-new`
       - `#member-invitation-selected-club`
       - `#member-invitation-club-home-link`
   - Added tests:
     - `web/test/memba_web/router_test.exs`
       - Verifies route pipeline and LiveView action.
     - `web/test/memba_web/live/member_invitation_live/new_test.exs`
       - Verifies isolated shell rendering.
       - Verifies query-selected club scoping.
       - Verifies host-selected club scoping.
   - Checked off todo 003 only.

3. **Focused validation commands and results**
   - Initial direct `bin/mix test ...` attempts failed before tests ran because `pg_isready` is unavailable outside the devenv shell in this sandbox.
   - Formatting check:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix format --check-formatted lib/memba_web/router.ex lib/memba_web/live/member_invitation_live/new.ex test/memba_web/router_test.exs test/memba_web/live/member_invitation_live/new_test.exs`
     - Passed.
   - Focused tests:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/router_test.exs test/memba_web/live/member_invitation_live/new_test.exs`
     - Passed: `16 tests, 0 failures`.
   - Full required validation for routing/LiveView change:
     - `PATH="$PWD/bin:$PATH" devenv shell -- dev check`
     - Passed:
       - ExUnit: `725 tests, 0 failures`
       - Acceptance: `69 scenarios (69 passed), 466 steps (466 passed)`

4. **Todo check-off made**
   - Changed:
     - `- [ ] 003 Add a member-facing route/action for inviting club members, scoped to the current club.`
   - To:
     - `- [x] 003 Add a member-facing route/action for inviting club members, scoped to the current club.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0015: implemented the member-facing invitation surface as a LiveView.
   - ADR 0007: web code does not query Membership projection tables directly; it scopes from existing authenticated identity club assigns.
   - ADR 0013: added focused web tests for routing and LiveView user-visible selectors; lower-level route/LiveView tests are appropriate for this route/action slice.
   - Phoenix guidance: route added inside existing `scope "/", MembaWeb`; LiveView uses `Layouts.club_site`, HEEx `~H`, stable DOM IDs, and no deprecated LiveView navigation APIs.