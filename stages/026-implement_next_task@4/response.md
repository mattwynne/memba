Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `004 Add public Membership APIs/commands for Staff/system use:`

2. **Changes made**
   - Updated `web/lib/memba/membership.ex` with public Membership APIs for:
     - `invite_club_member/2`
       - Generates a plaintext invitation token.
       - Stores only the invitation token hash via `InviteClubMember`.
       - Returns the plaintext token for later email delivery.
     - `resend_club_member_invitation/2`
       - Finds a pending invitation by `invitation_id` or `club_id` + `email`.
       - Rotates the token hash via `ResendClubMemberInvitation`.
       - Returns the new plaintext token.
     - `accept_club_member_invitation_for_existing_person/2`
       - Validates the existing person owns the invited email.
       - Creates an active ordinary membership.
       - Marks the invitation accepted.
     - `complete_invited_club_member_profile/2`
       - Creates the invited person only after a submitted name.
       - Uses the invited email as primary.
       - Creates active membership.
       - Marks the invitation accepted.
   - Added Membership query helpers:
     - `get_club_member_invitation/1`
     - `get_pending_club_member_invitation_by_email/2`
   - Added focused tests in `web/test/memba/membership/public_api_test.exs` covering:
     - pending invitation creation and plaintext token return;
     - pending invitation resend/token rotation by normalized email lookup;
     - existing-person invitation acceptance;
     - unknown invitee profile completion, person creation, membership creation, and acceptance.

3. **Focused validation commands run**
   - Formatting:
     - `devenv shell -- bin/mix format --check-formatted lib/memba/membership.ex test/memba/membership/public_api_test.exs`
     - Result: passed.
   - Focused tests:
     - `devenv shell -- bin/mix test test/memba/membership/public_api_test.exs test/memba/membership/club_invitation_dispatch_test.exs test/memba/membership/club_invitation_projection_test.exs`
     - Result: `20 tests, 0 failures`.
   - Broad quick validation:
     - `devenv shell -- dev check --quick`
     - Result: `686 tests, 0 failures`.
   - Whitespace:
     - `git diff --check`
     - Result: passed.
   - Note: I used a clean `devenv shell` wrapper because the sandbox had a stale Postgres environment, matching the earlier run’s known issue.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Add public Membership APIs/commands for Staff/system use:`
   - To:
     - `- [x] 004 Add public Membership APIs/commands for Staff/system use:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002: New behavior continues through Commanded commands/aggregates/events.
   - ADR 0007: Invitation APIs remain inside the Membership bounded context.
   - ADR 0009: Public queries use Membership projections internally without exposing cross-context table coupling.
   - ADR 0011: Aggregate IDs are generated before dispatch by the application service or accepted from callers.
   - ADR 0022: Tests use strong consistency where asserting projected read-your-writes behavior.