Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 012 It retains no per-membership workflow state: the Club aggregate owns membership state and makes at-least-once handler redelivery safe.`

2. **Changes made**
   - Added focused coverage to `web/test/memba/membership/system_group_membership_policy_dispatch_test.exs`.
   - New test directly simulates redelivery by invoking `Memba.Membership.Policies.SystemGroupMembership.handle/2` twice for:
     - `MemberAdded`
     - `MemberRoleAssigned` for Admin
     - `MemberRemoved`
   - The test asserts:
     - Everyone/Admin group membership state is updated correctly.
     - Only one `GroupMemberAdded` fact per group is appended despite duplicate add/role events.
     - Only one `GroupMemberRemoved` fact per group is appended despite duplicate removal events.
   - This proves redelivery safety comes from the Club aggregate’s idempotent group-membership state, not handler-held workflow memory.

3. **Focused validation**
   - `cd web && mix format --check-formatted test/memba/membership/system_group_membership_policy_dispatch_test.exs`
     - Initially failed due formatting; fixed.
     - Re-ran and passed.
   - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/system_group_membership_policy_test.exs test/memba/membership/system_group_membership_policy_dispatch_test.exs test/memba/membership/club_test.exs`
     - Passed: `32 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Command exited `0`.
     - Output still contains the known unrelated `MembaWeb.PageControllerTest` public-footer failures reported by prior checkpoints.

4. **Todo check-off made**
   - Changed exactly task 012 from:
     - `- [ ] 012 It retains no per-membership workflow state: the Club aggregate owns membership state and makes at-least-once handler redelivery safe.`
   - to:
     - `- [x] 012 It retains no per-membership workflow state: the Club aggregate owns membership state and makes at-least-once handler redelivery safe.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007: Changes remain inside the Membership bounded context and do not expose Membership read-model storage to Messaging.
   - Commanded/event-sourcing boundaries are preserved: the policy dispatches commands; the Club aggregate owns decisions and idempotency; projections remain mechanical.
   - No acceptance feature files or browser-facing behavior were changed.