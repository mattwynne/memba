1. **Selected todo line**
   - `009 Ensure accepted Membership Admin invitations create ordinary active memberships only.`

2. **Changes made**
   - Updated `web/test/memba/membership/public_api_test.exs`.
   - Added focused public API coverage for Membership Admin-created invitations:
     - Existing complete invitee accepts an invitation and receives an active membership only.
     - Unknown invitee completes profile and receives an active membership only.
   - Both tests assert:
     - Invitation was created via `invite_club_member_as_club_member/2`.
     - Acceptance creates a `MemberAdded` membership.
     - Invitee does **not** receive the club’s Membership Administrator role.
     - Invitee does **not** receive `club.manage_members`.
   - Added small test helpers for creating a Membership Admin inviter and checking active role assignment projection state.
   - No application code changes were needed; existing acceptance orchestration already creates ordinary memberships via `AddMember` only.

3. **Focused validation commands run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba/membership/public_api_test.exs`
     - Initially failed due formatting; fixed indentation and reran.
     - Passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/public_api_test.exs`
     - Failed due sandbox PGHOST readiness mismatch.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/membership/public_api_test.exs`
     - Passed: `22 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `737 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 009 Ensure accepted Membership Admin invitations create ordinary active memberships only.`
   - To:
     - `- [x] 009 Ensure accepted Membership Admin invitations create ordinary active memberships only.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Preserved the Membership bounded-context API shape by testing through `Memba.Membership` public application services.
   - Followed Commanded/event-sourced workflow constraints: tests assert commands/events/projections rather than introducing CRUD shortcuts.
   - Used caller-generated aggregate IDs in tests for people, memberships, clubs, and invitations.
   - Used Ecto projections only to verify projected role-assignment state after strongly consistent dispatches.
   - No new dependencies, routes, UI changes, feature edits, or HTTP clients introduced.