Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `005 Ensure duplicate checks use normalized email:`

2. **Changes made**
   - Updated `web/lib/memba/membership.ex`:
     - `invite_club_member/2` now blocks invitations when the normalized invited email already belongs to an active member of the club.
     - `invite_club_member/2` now detects an existing pending invitation for the same club + normalized email and resends/rotates that pending invitation instead of dispatching a duplicate invite.
     - Existing-person-not-in-club invitation behavior remains allowed and is still covered by the existing acceptance test.
   - Updated `web/test/memba/membership/public_api_test.exs`:
     - Added coverage for blocking an active club member via normalized alternate email.
     - Added coverage for duplicate pending invite submission resending the original invitation by normalized email and not creating a second invitation.

3. **Focused validation commands run**
   - TDD failure before implementation:
     - `devenv shell -- bin/mix test test/memba/membership/public_api_test.exs`
     - Result: failed as expected on new duplicate-rule tests.
   - Formatting:
     - `devenv shell -- bin/mix format --check-formatted lib/memba/membership.ex test/memba/membership/public_api_test.exs`
     - Result: passed.
   - Focused tests:
     - `devenv shell -- bin/mix test test/memba/membership/public_api_test.exs test/memba/membership/club_invitation_dispatch_test.exs test/memba/membership/club_invitation_projection_test.exs`
     - Result: `22 tests, 0 failures`.
   - Broad quick validation:
     - `devenv shell -- dev check --quick`
     - Result: `688 tests, 0 failures`.
   - Whitespace:
     - `git diff --check`
     - Result: passed.
   - Note: I used `devenv shell -- ...` because the prepared `PATH=... bin/mix ...` wrapper hit the known stale Postgres lock issue in this sandbox.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 005 Ensure duplicate checks use normalized email:`
   - To:
     - `- [x] 005 Ensure duplicate checks use normalized email:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002: Invitation lifecycle still goes through Commanded commands/events.
   - ADR 0007: Duplicate invitation behavior remains inside the Membership bounded context.
   - ADR 0009: Duplicate checks use Membership projections/read models.
   - ADR 0011: No natural-key aggregate identity was introduced; invitation/member IDs remain UUID-style caller/application generated IDs.
   - ADR 0022: Tests use strong consistency when asserting projected read-your-writes behavior.