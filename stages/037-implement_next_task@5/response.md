Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 005 Make CreateClub emit GroupCreated for both system groups while preserving the existing Admin-role creation and permission grant.`

2. **Changes made**
   - Updated `Memba.Membership.Club.execute/2` for `CreateClub` to emit two additional `GroupCreated` events:
     - deterministic Everyone group using `SystemGroups.everyone_group_id/1`
     - deterministic Admin group using `SystemGroups.admin_group_id/1`
   - Preserved the existing `ClubCreated`, default Admin role creation, and `club.manage_members` permission grant.
   - Added `GroupCreated` no-op handling to `Memba.Membership.Projectors.Club` so the strong club projector/checkpoint barrier stays current when `CreateClub` now emits group facts.
   - Updated focused aggregate, dispatch, and public API tests to assert the new system-group facts and resulting aggregate versions/state.

3. **Validation commands run**
   - TDD expected failing run after adding expectations:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/club_test.exs test/memba/membership/create_club_dispatch_test.exs`
     - Result: expected failures because `CreateClub` did not yet emit `GroupCreated`.
   - Focused passing run:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/club_test.exs test/memba/membership/create_club_dispatch_test.exs test/memba/membership/system_groups_test.exs`
     - Result: `31 tests, 0 failures`.
   - Related public API/barrier passing run:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/public_api_test.exs test/memba/projection_barrier_test.exs`
     - Result: `30 tests, 0 failures`.
   - Broader per-task check:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: command exited `0`; ExUnit output still reports the same 2 unrelated `MembaWeb.PageControllerTest` footer failures for `"Red Donkey Technology Corp"` noted by prior checkpoints.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Make CreateClub emit GroupCreated for both system groups while preserving the existing Admin-role creation and permission grant.`
   - To:
     - `- [x] 005 Make CreateClub emit GroupCreated for both system groups while preserving the existing Admin-role creation and permission grant.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002: preserves explicit event-sourced domain facts for group creation rather than projector-only inference.
   - ADR 0007: keeps group ownership and event emission inside the Membership context; no Messaging storage/query dependency added.
   - ADR 0011: uses caller/resolver-accessible deterministic typed group IDs, not aggregate-generated identities.