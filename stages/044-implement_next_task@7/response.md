Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `007 Add the Staff club-scoped invite route and form. Exact route name is implementation detail, but it should sit under /admin/clubs/:club_id/... and not replace the existing person edit route.`

2. **Changes made**
   - Added Staff route:
     - `GET /admin/clubs/:club_id/invitations/new`
     - LiveView: `MembaWeb.Admin.ClubMemberInvitationsLive.New`
   - Added email-only invitation form:
     - asks only for invitee email;
     - validates malformed email;
     - calls `Membership.invite_club_member/2` with strong consistency;
     - delivers via `Memba.Membership.ClubMemberInvitationEmail`;
     - creates a pending invitation without creating a person or active membership;
     - handles duplicate pending invitation as resend via existing Membership API;
     - shows clear active-member duplicate error from domain result.
   - Added an “Invite member” link from the Staff club detail memberships card.
   - Preserved existing person edit route/link coverage.
   - Added focused LiveView/PhoenixTest coverage in:
     - `web/test/memba_web/live/admin/club_member_invitations_live/new_test.exs`
   - Added `Memba.Membership.Projectors.ClubInvitation` to acceptance reset projector restart list:
     - needed because the invitation projector was added earlier in this iteration;
     - without it, full browser acceptance reset left a projector running across event-store truncation, causing broad consistency timeouts in `dev check`.

3. **Focused validation commands/results**
   - Formatting check:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted ...`
     - Passed.
   - Focused tests:
     - Preferred wrapper first failed before tests due sandbox Postgres readiness/socket issue.
     - Reran with sandbox workaround:
       - `devenv shell -- bin/mix test test/memba_web/live/admin/club_member_invitations_live/new_test.exs test/memba_web/live/admin/clubs_live/show_test.exs`
       - Result: `14 tests, 0 failures`.
   - Full quality gate:
     - Initial `PATH="$PWD/bin:$PATH" dev check` exposed acceptance reset consistency timeouts.
     - After adding the missing `ClubInvitation` projector to reset handling:
       - `PATH="$PWD/bin:$PATH" dev check`
       - Result: `697 tests, 0 failures`; `62 scenarios (62 passed)`.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 007 Add the Staff club-scoped invite route and form...`
   - To:
     - `- [x] 007 Add the Staff club-scoped invite route and form...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: Uses Phoenix/LiveView for the new Staff web surface.
   - ADR 0013: Added feature-style web coverage through PhoenixTest/LiveView test helpers.
   - ADR 0015: Uses LiveView for this application-style authenticated Staff flow.
   - ADR 0007: Keeps membership invitation lifecycle in the Membership boundary; web layer calls Membership public APIs and does not mutate projections directly.
   - ADR 0016: Email delivery remains through `Memba.Mailer`/Swoosh via the existing invitation email module; no direct provider HTTP code added.