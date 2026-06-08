Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `009 Add an invitation callback route that validates invitation tokens, signs in the invited email for the invitation journey, and routes to either profile completion or the invited club. Do not consume a pending unknown invitee's token on first open; consume it only when profile completion or existing-person acceptance succeeds.`

2. **Changes made**
   - Added `MembaWeb.ClubMemberInvitationController` with callback handling at:
     - `GET /invitations/club-members/:token`
   - Added Membership query support:
     - `Membership.get_club_member_invitation_by_token/1`
     - Looks up invitations by hashed plaintext token and supports pending + accepted invitations.
   - Added invitation journey session key helper:
     - `IdentityAuth.club_member_invitation_session_key/0`
   - Callback behavior implemented:
     - Invalid/unknown token redirects to `/auth` with a clear invalid-invitation message and no sign-in.
     - Pending unknown invitee is signed in with the invited email, invitation journey state is stored in session, and they are redirected to `/invitations/club-members/profile`.
     - Pending existing person is accepted immediately, creates active ordinary membership via Membership API, marks invitation accepted, signs in, and redirects to the invited club.
     - Accepted invitation links can be reopened idempotently: they sign in and redirect to the club without creating duplicate membership.
   - Added focused controller tests in:
     - `web/test/memba_web/controllers/club_member_invitation_controller_test.exs`
   - Checked off todo `009` only.

3. **Validation run**
   - Initial preferred wrapper command hit the known sandbox Postgres readiness/socket mismatch:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/controllers/club_member_invitation_controller_test.exs`
   - Reran focused tests successfully:
     - `devenv shell -- bin/mix test test/memba_web/controllers/club_member_invitation_controller_test.exs`
     - Result: `4 tests, 0 failures`
   - Formatting:
     - `devenv shell -- bin/mix format --check-formatted lib/memba/membership.ex lib/memba_web/identity_auth.ex lib/memba_web/router.ex lib/memba_web/controllers/club_member_invitation_controller.ex test/memba_web/controllers/club_member_invitation_controller_test.exs`
     - Passed.
   - Focused adjacent tests:
     - `devenv shell -- bin/mix test test/memba_web/controllers/club_member_invitation_controller_test.exs test/memba_web/controllers/auth_controller_test.exs test/memba_web/live/admin/club_member_invitations_live/new_test.exs test/memba/membership/public_api_test.exs`
     - Result: `48 tests, 0 failures`
   - Full required gate for routing/browser-facing controller change:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `62 scenarios (62 passed)`.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 009 Add an invitation callback route that validates invitation tokens, signs in the invited email for the invitation journey, and routes to either profile completion or the invited club. Do not consume a pending unknown invitee's token on first open; consume it only when profile completion or existing-person acceptance succeeds.`
   - To:
     - `- [x] 009 Add an invitation callback route that validates invitation tokens, signs in the invited email for the invitation journey, and routes to either profile completion or the invited club. Do not consume a pending unknown invitee's token on first open; consume it only when profile completion or existing-person acceptance succeeds.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: Kept implementation in the Phoenix core app.
   - ADR 0002/0007: Membership writes still go through the Membership public API/Commanded flow; the web controller does not mutate projections directly.
   - ADR 0013: Added Phoenix web tests for user-visible callback behavior.
   - ADR 0015: Did not introduce controller-rendered member app UI; this task only adds the callback route. Profile completion UI remains for the next planned task.
   - ADR 0022: Existing-person acceptance uses `consistency: :strong` before redirecting to club read-model-backed surfaces.