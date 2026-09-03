Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 009 membership_group_memberships has one current-state row keyed by (group_id, membership_id); add/remove toggles its active flag, so re-add reactivates the row and the event stream retains history.`

2. **Changes made**
   - Added focused regression coverage in:
     - `web/test/memba/membership/group_projection_test.exs`
   - New test verifies:
     - `AddGroupMember` creates an active projected row.
     - `RemoveGroupMember` toggles the same row to inactive.
     - A later `AddGroupMember` reactivates the same row.
     - Only one projection row exists for `(group_id, membership_id)`.
     - The Club event stream still contains the historical sequence:
       - `GroupMemberAdded`
       - `GroupMemberRemoved`
       - `GroupMemberAdded`
   - No production code changes were needed because the existing projector/migration already use an upsert with conflict target `[:group_id, :membership_id]`.

3. **Focused validation**
   - `cd web && mix format --check-formatted test/memba/membership/group_projection_test.exs`
     - Passed after a small indentation patch.
   - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/group_projection_test.exs`
     - Passed: `3 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Command exited `0`.
     - Output still includes the previously noted unrelated `MembaWeb.PageControllerTest` public-footer failures; I did not touch those.

4. **Todo check-off made**
   - Changed exactly this line:
     - From: `- [ ] 009 ...`
     - To: `- [x] 009 ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007 respected: changes stay inside Membership tests and do not expose Membership projection storage to Messaging.
   - ADR 0009 respected: behaviour is verified through the existing Commanded Ecto projector.
   - No acceptance `.feature` files were modified.