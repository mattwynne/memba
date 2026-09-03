Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 013 Configure Group projectors as strong and dispatch affected member/role commands with strong consistency, so those commands return only after group membership is queryable.`

2. **Changes made**
   - Updated `web/lib/memba/membership.ex`:
     - `add_member/2`, `remove_member/2`, `assign_member_role_as_club_member/2`, and `remove_member_role_as_club_member/2` now dispatch with system-group membership consistency.
     - Invitation acceptance paths that create memberships now also wait for the system-group policy before returning.
     - Existing caller dispatch options are preserved:
       - `consistency: :strong` remains unchanged.
       - `consistency: :eventual` or omitted consistency is upgraded to wait for `Memba.Membership.Policies.SystemGroupMembership`.
       - Explicit handler lists are augmented with `SystemGroupMembership` unless already present.
   - Updated `web/test/memba/membership/group_projection_test.exs`:
     - Added coverage that both Group projectors are configured with `consistency: :strong`.
   - Updated `web/test/memba/membership/public_api_test.exs`:
     - Added coverage that public member/Admin-role APIs return only after group membership projection rows are immediately queryable, even without explicit consistency options.

3. **Focused validation**
   - `cd web && mix format --check-formatted lib/memba/membership.ex test/memba/membership/group_projection_test.exs test/memba/membership/public_api_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/group_projection_test.exs test/memba/membership/public_api_test.exs`
     - Passed: `34 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/system_group_membership_policy_test.exs test/memba/membership/system_group_membership_policy_dispatch_test.exs`
     - Passed: `6 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Exited `0`.
     - Output still showed the known unrelated public-footer `MembaWeb.PageControllerTest` failures.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly task 013 from:
     - `- [ ] 013 Configure Group projectors as strong and dispatch affected member/role commands with strong consistency, so those commands return only after group membership is queryable.`
   - to:
     - `- [x] 013 Configure Group projectors as strong and dispatch affected member/role commands with strong consistency, so those commands return only after group membership is queryable.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007 remains respected:
     - Changes stay inside the Membership bounded context.
     - Messaging is not coupled to Membership projection schemas.
     - Membership public APIs own the consistency guarantee for membership/role lifecycle commands.
   - Projectors remain mechanical projections of events; system group alignment remains in the policy/aggregate flow, not in projector inference.