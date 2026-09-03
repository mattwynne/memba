Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 011 It handles each MemberAdded, MemberRemoved, MemberRoleAssigned, and MemberRoleRemoved independently, dispatching idempotent Club-group membership commands for Everyone and the deterministic Admin role.`

2. **Changes made**
   - Implemented `Memba.Membership.Policies.SystemGroupMembership.handle/2` for:
     - `MemberAdded` → dispatch `AddGroupMember` for Everyone.
     - `MemberRemoved` → dispatch `RemoveGroupMember` for Everyone and Admin.
     - `MemberRoleAssigned` for deterministic Admin role → dispatch `AddGroupMember` for Admin.
     - `MemberRoleRemoved` for deterministic Admin role → dispatch `RemoveGroupMember` for Admin.
     - Non-Admin role lifecycle events are ignored.
   - Nested group commands use explicit consistency for `Memba.Membership.Projectors.GroupMembership`, avoiding background projection writes after test ownership exits while avoiding handler self-deadlock.
   - `MemberRemoved` events now carry `club_id` and `person_id` in addition to `membership_id`, so the policy can dispatch removal commands with the identities required by the Club aggregate.
   - Kept `MemberRemoved` backward-tolerant by retaining only `membership_id` in `@enforce_keys`.
   - Added focused integration tests in:
     - `web/test/memba/membership/system_group_membership_policy_dispatch_test.exs`
   - Updated existing aggregate test to assert `MemberRemoved` includes club/person identities.

3. **Focused validation run**
   - Formatting:
     - `cd web && mix format --check-formatted lib/memba/membership/policies/system_group_membership.ex lib/memba/membership/events/member_removed.ex lib/memba/membership/membership.ex test/memba/membership/membership_test.exs test/memba/membership/system_group_membership_policy_dispatch_test.exs`
     - Passed.
   - Focused tests:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/membership_test.exs test/memba/membership/system_group_membership_policy_test.exs test/memba/membership/system_group_membership_policy_dispatch_test.exs test/memba/membership/create_club_dispatch_test.exs test/memba/membership/group_projection_test.exs`
     - Passed: `23 tests, 0 failures`.
   - Broad quick check:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Command exited `0`.
     - Output still reports the known unrelated `MembaWeb.PageControllerTest` public-footer failures already present in prior checkpoint output.

4. **Todo check-off made**
   - Changed exactly task 011 from `- [ ]` to `- [x]`.
   - Confirmed the todo diff only changes that one line.

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0002: Uses Commanded event-handler and command dispatch patterns for domain workflow.
   - ADR 0007: Stays inside Membership bounded context; no Messaging or cross-context schema dependency added.
   - ADR 0009: Keeps policy decisions outside projectors; projectors remain mechanical read models of group events.
   - ADR 0022: Uses explicit projection consistency/barrier-aware testing so read-model side effects are synchronized rather than timing-dependent.