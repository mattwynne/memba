Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 003 Extend the Club aggregate state and commands so it owns group definitions and group memberships.`

2. **Changes made**
   - Extended `Memba.Membership.Club` aggregate state with:
     - `groups`
     - `group_keys`
     - `group_memberships`
   - Added Club aggregate command handling for:
     - `CreateGroup`
     - `AddGroupMember`
     - `RemoveGroupMember`
   - Added Club aggregate event application for:
     - `GroupCreated`
     - `GroupMemberAdded`
     - `GroupMemberRemoved`
   - Routed group commands through `Memba.Membership.Router` to the existing `Club` aggregate.
   - Updated Membership app/router command registration expectations.
   - Added focused tests proving:
     - Club emits group definition/member events for group commands.
     - Group commands are rejected before club creation.
     - Club aggregate state records group definitions and current group membership state.
     - Membership app dispatch routes group commands to the Club aggregate.

3. **Focused validation**
   - Ran TDD-focused test command initially after adding tests; it failed as expected because `Club` did not yet have group fields/handlers.
   - Passed focused validation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/club_test.exs test/memba/membership/app_test.exs test/memba/membership/create_club_dispatch_test.exs test/memba/membership/group_command_event_modules_test.exs`
     - Result: `34 tests, 0 failures`
   - Ran broad quick gate:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - ExUnit reported `1029 tests, 2 failures`, both existing/unrelated `MembaWeb.PageControllerTest` footer assertions expecting `"Red Donkey Technology Corp"`.
     - The wrapper exited `0`, but I am not reporting the quick check as clean because the test output contains failures.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Extend the Club aggregate state and commands so it owns group definitions and group memberships.`
   - To:
     - `- [x] 003 Extend the Club aggregate state and commands so it owns group definitions and group memberships.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Followed ADR 0002 by modeling the change through Commanded commands, aggregate decisions, and domain events.
   - Followed ADR 0007 by keeping group ownership inside the Membership context and not exposing Membership storage details to Messaging.
   - Followed ADR 0011 by requiring callers to provide group IDs; no aggregate-generated identities were introduced.
   - Did not implement deterministic Everyone/Admin IDs, CreateClub system-group emission, projections, policy handlers, public query APIs, or messaging access changes; those remain for later checked-off tasks.