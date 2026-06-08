Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `003 Add a member-facing route/action for inviting club members, scoped to the current club.`

2. **Changes made**
   - Added member-facing route:
     - `GET /members/invitations/new`
     - Mounted under the existing `:club_member_required` pipeline and `:club_member` LiveView session.
   - Added `MembaWeb.ClubMemberInvitationsLive.New`:
     - Uses the existing club-member layout.
     - Resolves the current club from either `?club_id=...` or club subdomain session context.
     - Renders a scoped invitation action shell with stable selectors and current-club/current-member metadata.
     - Does **not** add the dashboard link, permission authorization, invitation form, or invitation submission yet; those remain in later todo items.
   - Added tests:
     - Router test proving the new route uses the required club-member pipeline.
     - LiveView tests proving:
       - query-selected club scope works;
       - host-selected club scope works and preserves host-style links;
       - signed-out users are redirected and return path is preserved.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format lib/memba_web/router.ex lib/memba_web/live/club_member_invitations_live/new.ex test/memba_web/router_test.exs test/memba_web/live/club_member_invitations_live/new_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test ...`
     - Hit sandbox Postgres socket readiness mismatch before tests ran.
   - `devenv shell -- bin/mix test test/memba_web/router_test.exs test/memba_web/live/club_member_invitations_live/new_test.exs`
     - Passed: `16 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 003 Add a member-facing route/action for inviting club members, scoped to the current club.`
   - To:
     - `- [x] 003 Add a member-facing route/action for inviting club members, scoped to the current club.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No `docs/adr/` files were present in this checkout.
   - The change stays in Phoenix routing/LiveView.
   - It reuses the existing member-facing club LiveView/session conventions.
   - It reads club/member state through existing Membership query APIs and projections.
   - It does not duplicate invitation lifecycle/domain behavior; that remains for the planned service-reuse tasks.