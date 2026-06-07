Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `005 Update onboarding conversion so the requester/first member receives the Membership Administrator assignment after membership creation.`

2. **Changes made**
   - Updated `web/lib/memba/onboarding.ex`
     - After creating the first active membership during request conversion, onboarding now dispatches `AssignMemberRole` to assign the deterministic Membership Administrator role to the requester/first member.
     - Uses strong consistency for the assignment command.
   - Updated `web/lib/memba/membership/projectors/club.ex`
     - Added a no-op projection for `MemberRoleAssigned` so strong-consistency dispatches can advance the club projector through role-assignment events.
   - Updated `web/test/memba/onboarding_conversion_test.exs`
     - Added assertions that converted requesters receive the Membership Administrator assignment.
     - Covered both:
       - new-person conversion path;
       - existing-person reuse conversion path.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/onboarding_conversion_test.exs`
     - Attempted before/after implementation, but the direct wrapper run could not start Postgres due an existing `postmaster.pid`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `641 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/onboarding.ex lib/memba/membership/projectors/club.ex test/memba/onboarding_conversion_test.exs`
     - Passed.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Update onboarding conversion so the requester/first member receives the Membership Administrator assignment after membership creation.`
   - To:
     - `- [x] 005 Update onboarding conversion so the requester/first member receives the Membership Administrator assignment after membership creation.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: implemented the behaviour through Commanded command/event flow rather than CRUD mutation.
   - ADR 0007: kept role assignment inside the Membership bounded context; onboarding only orchestrates membership commands for conversion.
   - ADR 0008: validated through the persistent EventStore-backed quick test gate.
   - ADR 0011: reused deterministic/caller-known IDs; the aggregate does not generate identities.
   - ADR 0022: preserved strong-consistency/projector advancement by handling `MemberRoleAssigned` in the club projector.