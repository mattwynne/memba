Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `004 Ensure club creation initializes the default Membership Administrator role and permission bundle. If the creator/first member is not known at CreateClub time, assign the role when the first member is added through onboarding conversion or an explicit assignment command.`

2. **Changes made**
   - Updated `Memba.Membership.Club.execute/2` for `CreateClub` to emit:
     - `ClubCreated`
     - `ClubRoleDefined` for the deterministic default Membership Administrator role
     - `ClubRolePermissionGranted` granting `club.manage_members`
   - Updated the club projector to no-op project the new role-initialization events so projection barriers can advance past the full create-club event bundle.
   - Updated tests to assert the new create-club event stream and aggregate state:
     - `web/test/memba/membership/club_test.exs`
     - `web/test/memba/membership/create_club_dispatch_test.exs`
     - `web/test/memba/membership/public_api_test.exs`
   - Adjusted role-command dispatch tests to define a custom role after club creation, since the default Membership Administrator role is now created automatically.
   - Did **not** assign the requester/first member yet; that remains task `005`.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/membership/club_test.exs test/memba/membership/create_club_dispatch_test.exs test/memba/membership/public_api_test.exs`
     - Failed before running tests because the sandbox Mix wrapper could not start/connect to Postgres due an existing `postmaster.pid`.
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/membership/club.ex lib/memba/membership/projectors/club.ex test/memba/membership/club_test.exs test/memba/membership/create_club_dispatch_test.exs test/memba/membership/public_api_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - First run exposed a projection barrier regression caused by the new multi-event club creation.
     - Fixed by making the club projector advance through the role-initialization events.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `641 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Ensure club creation initializes the default Membership Administrator role and permission bundle...`
   - To:
     - `- [x] 004 Ensure club creation initializes the default Membership Administrator role and permission bundle...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: modeled the behaviour with Commanded aggregate events.
   - ADR 0007: kept the work inside the Membership bounded context.
   - ADR 0008: validated through the persistent EventStore-backed quick test gate.
   - ADR 0009: used Commanded Ecto projection machinery for projector advancement.
   - ADR 0011: the built-in role ID is deterministic from the club ID and role key; no random identity is generated inside the aggregate.
   - ADR 0022: preserved projection barrier semantics by ensuring the club projector reaches the full create-club checkpoint.