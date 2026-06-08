Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `010 Generalize the current staff onboarding/profile completion enough that invited unknown members can enter their name before membership activation. For this slice, profile-completion state can live in the invitation/session journey; do not create an incomplete person before the name is submitted, and avoid overbuilding date-of-birth or configurable detail schemas.`

2. **Changes made**
   - Added invitation profile completion routes:
     - `GET /invitations/club-members/profile`
     - `POST /invitations/club-members/profile`
   - Extended `MembaWeb.ClubMemberInvitationController` to:
     - validate the invitation journey from session state;
     - show a name-only profile completion page for verified unknown invitees;
     - reject direct profile-page visits without a verified invitation journey;
     - keep blank-name submissions on the form without creating a person or membership;
     - call `Membership.complete_invited_club_member_profile/2` on valid name submission;
     - create the invited person and ordinary active membership via Membership APIs;
     - clear invitation journey state, keep/sign in the invited email, and redirect to the invited club.
   - Added `MembaWeb.ClubMemberInvitationHTML` and `profile.html.heex`.
   - Added focused controller tests proving:
     - profile form is shown only after invitation callback;
     - no person/member is created before name submission;
     - blank name leaves the invitation pending and token reusable;
     - valid name creates profile + active membership and clears invitation session state.

3. **Validation**
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/controllers/club_member_invitation_controller_test.exs`
     - Hit the known Fabro/devenv Postgres readiness socket mismatch.
   - `devenv shell -- bin/mix test test/memba_web/controllers/club_member_invitation_controller_test.exs`
     - Passed: `8 tests, 0 failures`.
   - `devenv shell -- bin/mix format --check-formatted ...`
     - Passed for touched code/template/test files.
   - `devenv shell -- bin/mix test test/memba_web/controllers/club_member_invitation_controller_test.exs test/memba_web/controllers/auth_controller_test.exs test/memba_web/live/admin/club_member_invitations_live/new_test.exs test/memba/membership/public_api_test.exs`
     - Passed: `52 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `62 scenarios (62 passed)`.
   - `git diff --check`
     - Passed.

4. **Todo check-off**
   - Changed exactly task `010` from `- [ ]` to `- [x]`.
   - No other ordinary todo lines were checked off.

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: Kept implementation in the Phoenix app.
   - ADR 0002/0007/0009: Membership writes go through the Membership public API/Commanded flow; no projection mutation from web code.
   - ADR 0013: Added Phoenix web/controller tests for user-visible behaviour.
   - ADR 0015: This is an invitation/profile-completion journey rather than an authenticated club-member app page; controller rendering is used deliberately to manage Plug session state cleanly.
   - ADR 0022: Successful completion uses `consistency: :strong` before redirecting to read-model-backed club surfaces.