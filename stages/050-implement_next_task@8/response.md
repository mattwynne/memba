Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `008 Ensure verified request submission does not create Person, club, membership, or club access.`

2. **Changes made**
   - Updated `web/test/memba_web/controllers/page_controller_test.exs`
     - Strengthened the verified `/get-started` submission test to capture membership-domain projection counts before submission and assert they are unchanged afterward:
       - `membership_people`
       - `membership_person_email_addresses`
       - `membership_clubs`
       - `membership_memberships`
       - `membership_role_assignments`
       - `membership_member_permissions`
     - Added an assertion that the verified requester has no active clubs after submission:
       - `Memba.Membership.list_active_clubs_for_member_email("robin@example.com") == []`

3. **Focused validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba_web/controllers/page_controller_test.exs`
     - Passed.
   - Initial focused wrapper test command hit the known sandbox Postgres readiness path mismatch.
   - Retried with explicit devenv process setup:
     - `DEVENV_TUI=false devenv processes up --strict-ports -d postgres && DEVENV_TUI=false devenv processes wait --timeout 120 && devenv shell -- bash -lc 'cd web && mix test test/memba_web/controllers/page_controller_test.exs:1137 --seed 0'`
     - Passed: `39 tests, 0 failures, 38 excluded`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `746 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 008 Ensure verified request submission does not create Person, club, membership, or club access.`
   - To:
     - `- [x] 008 Ensure verified request submission does not create Person, club, membership, or club access.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No ADRs were explicitly referenced by the plan, and no `docs/adr/*.md` files were present in the current tree.
   - The change is limited to focused regression coverage for the selected task and preserves the verified request flow semantics already implemented.