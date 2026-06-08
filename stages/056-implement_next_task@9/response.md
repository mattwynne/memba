Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `007 If needed, add an inviter/actor distinction to the invitation API so both Staff/system actors and club Membership Admin actors can be represented without giving Staff implicit club membership.`

2. **Changes made**
   - Added `Memba.Membership.invite_club_member_as_club_member/2`.
     - Requires `:actor_person_id` / `"actor_person_id"`.
     - Authorizes the actor through projected `club.manage_members`.
     - Delegates to the existing shared invitation lifecycle after authorization.
   - Clarified `Memba.Membership.invite_club_member/2` as the Staff/system invitation API, preserving Staff flow without requiring Staff club membership.
   - Updated `MembaWeb.ClubMemberInvitationSender` to choose the appropriate Membership application service:
     - no actor → Staff/system path;
     - `actor_person_id` present → club-member actor path.
   - Updated the member-facing invitation LiveView to pass the current member’s person ID as the actor.
   - Added focused public API tests for:
     - Membership Admin actor invitation through the shared lifecycle;
     - ordinary member rejection;
     - Staff/system invitation continuing without club membership.

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/membership.ex lib/memba_web/club_member_invitation_sender.ex lib/memba_web/live/club_member_invitations_live/new.ex test/memba/membership/public_api_test.exs` — passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/public_api_test.exs test/memba_web/live/club_member_invitations_live/send_test.exs` — hit known sandbox `PGHOST` readiness mismatch.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/membership/public_api_test.exs test/memba_web/live/club_member_invitations_live/send_test.exs` — passed, `21 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check` — passed, including `69 scenarios (69 passed)`.
   - `git diff --check` — passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 007 If needed, add an inviter/actor distinction to the invitation API so both Staff/system actors and club Membership Admin actors can be represented without giving Staff implicit club membership.`
   - To:
     - `- [x] 007 If needed, add an inviter/actor distinction to the invitation API so both Staff/system actors and club Membership Admin actors can be represented without giving Staff implicit club membership.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Kept invitation lifecycle in the Membership context and Commanded-backed application service boundary.
   - Preserved Staff/system invitation flow separately from club-member actor authorization.
   - Kept web layer as orchestration only: LiveView passes the actor, Membership authorizes and dispatches.
   - No new dependencies, HTTP clients, migrations, or acceptance feature changes introduced.