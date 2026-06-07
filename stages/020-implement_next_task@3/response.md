Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `003 Add commands/events for creating the default Membership Administrator role, granting club.manage_members, and assigning/removing the role from active members. Prefer events that preserve future role customisation rather than baking all logic into one opaque flag.`

2. **Changes made**
   - Added role ID support to `Memba.ID` with `:role` / `rol_...`.
   - Added Membership constants/modules:
     - `Memba.Membership.Permissions`
     - `Memba.Membership.Roles`
   - Added commands:
     - `DefineClubRole`
     - `GrantClubRolePermission`
     - `AssignMemberRole`
     - `RemoveMemberRole`
   - Added events:
     - `ClubRoleDefined`
     - `ClubRolePermissionGranted`
     - `MemberRoleAssigned`
     - `MemberRoleRemoved`
   - Routed the new commands through `Memba.Membership.Router` to the `Club` aggregate.
   - Extended `Memba.Membership.Club` aggregate state/behaviour to:
     - define club-scoped roles;
     - grant app-defined permissions to roles;
     - assign/remove roles from members;
     - reject duplicate role IDs/keys, duplicate permission grants, unknown roles, duplicate assignments, and missing assignments.
   - Added/updated tests for:
     - aggregate command/event behaviour;
     - Commanded dispatch routing;
     - registered Membership app commands.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted ...` — passed for touched Elixir files.
   - `PATH="$PWD/bin:$PATH" MIX_ENV=test bin/mix compile --warnings-as-errors` — passed.
   - Direct pure aggregate test run:
     - `cd web && MIX_ENV=test ERL_LIBS=_build/test/lib elixir ... test/memba/membership/club_test.exs ...`
     - Result: `19 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed.
     - Result: `641 tests, 0 failures`.
   - `git diff --check` — passed.
   - Note: an initial direct `bin/mix test ...` attempt failed before running tests because the wrapper’s Postgres readiness check saw a sandbox `PGHOST` socket mismatch; `dev check --quick` successfully ran the project-managed test gate.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 ...`
   - To:
     - `- [x] 003 ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002: kept new domain behaviour in Commanded commands, aggregate execution, and events.
   - ADR 0007: kept role/permission behaviour inside the Membership bounded context and router.
   - ADR 0008: validated through the persistent EventStore-backed quick test gate.
   - ADR 0009: did not add projections yet; projection work remains for the later explicit todo item.
   - ADR 0011: role IDs are caller/deterministically generated typed IDs via `Memba.ID`, not aggregate-generated.
   - ADR 0022: no read-your-writes/projection assertions added in this task; projection/API work remains deferred to the planned later tasks.