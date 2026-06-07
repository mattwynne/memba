Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `008 Add authorization handling to membership-management operations. For paths where Memba staff currently act through staff-only screens, keep staff authorization separate, but make club-member role assignment/removal commands rely on the permission model.`

2. **Changes made**
   - Added permission-gated club-member role operation APIs:
     - `Memba.Membership.assign_member_role_as_club_member/2`
     - `Memba.Membership.remove_member_role_as_club_member/2`
   - These require `actor_person_id`, check projected `club.manage_members`, validate the target membership is active, then dispatch the existing role assignment/removal commands.
   - Left existing staff/system-oriented paths (`add_member/2`, `remove_member/2`, onboarding/system dispatch) separate and unchanged.
   - Added `Memba.Membership.Authorization.authorize_manage_members/2`.
   - Added focused tests in:
     - `web/test/memba/membership/member_role_authorization_test.exs`

3. **Focused validation**
   - Formatting check:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/membership.ex lib/memba/membership/authorization.ex test/memba/membership/member_role_authorization_test.exs`
     - Passed.
   - Focused tests:
     - Direct `bin/mix test ...` hit the known PGHOST readiness mismatch.
     - Reran with devenv shell due that mismatch:
       - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/member_role_authorization_test.exs test/memba/membership/authorization_test.exs test/memba/membership/public_api_test.exs'`
       - Passed: `16 tests, 0 failures`.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `651 tests, 0 failures`.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 008 Add authorization handling to membership-management operations...`
   - To:
     - `- [x] 008 Add authorization handling to membership-management operations...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002: keeps behavior in Membership command/application-service flow over Commanded commands/events.
   - ADR 0007: authorization remains encapsulated in Membership’s public API; callers do not query projection tables directly.
   - ADR 0008/0009: validation uses persistent EventStore-backed tests and projected permission read models.
   - ADR 0022: tests use strong consistency before reading projected permission state.