Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 006 Add Group aggregate-state validation and idempotent commands for creating a group and adding/removing a membership: a group belongs to its club; a membership is not added twice; commands carry club, group, membership, and person identities.`

2. **Changes made**
   - Updated `Memba.Membership.Club` group command handling:
     - `CreateGroup` is idempotent for the same normalized group ID/key/name.
     - Conflicting duplicate group IDs return `{:error, :group_already_defined}`.
     - Conflicting duplicate group keys return `{:error, :group_key_already_defined}`.
     - `AddGroupMember` and `RemoveGroupMember` require the group to exist in the command’s club.
     - Duplicate active adds are no-ops (`[]`).
     - Duplicate/removing already-inactive memberships are no-ops (`[]`).
     - Re-adding an inactive group membership emits `GroupMemberAdded`.
     - Person mismatches for an existing group-membership row return `{:error, :group_membership_person_mismatch}`.
   - Updated aggregate tests to cover validation, idempotency, re-add behavior, and person mismatch cases.
   - Updated dispatch tests so direct group-command routing uses a non-system group key and now proves Commanded dispatch no-op behavior for repeated group/create/add/remove commands.

3. **Focused validation**
   - TDD pre-implementation run:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/club_test.exs`
     - Result: expected failure, `26 tests, 4 failures`.
   - Focused final run:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/club_test.exs test/memba/membership/create_club_dispatch_test.exs test/memba/membership/group_command_event_modules_test.exs`
     - Result: `35 tests, 0 failures`.
   - Broad per-task check:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: command exited `0`; ExUnit output still reports the same 2 pre-existing `MembaWeb.PageControllerTest` public-footer failures noted by prior checkpoints.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 006 Add Group aggregate-state validation and idempotent commands for creating a group and adding/removing a membership: a group belongs to its club; a membership is not added twice; commands carry club, group, membership, and person identities.`
   - To:
     - `- [x] 006 Add Group aggregate-state validation and idempotent commands for creating a group and adding/removing a membership: a group belongs to its club; a membership is not added twice; commands carry club, group, membership, and person identities.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: preserves aggregate-enforced domain invariants and explicit event-sourced facts.
   - ADR 0007: keeps group rules inside the Membership bounded context; no Messaging dependency or Membership read-model leakage added.
   - ADR 0011: continues using caller-supplied typed IDs for club/group/membership/person identities.
   - ADR 0022: idempotent no-op command behavior supports safe redelivery/read-your-writes workflows for later strong handlers/projectors.