Implemented the next unchecked task.

1. **Selected todo line**
   - `- [ ] 009 Ensure accepted Membership Admin invitations create ordinary active memberships only.`

2. **Changes made**
   - Updated `web/test/memba_web/live/member_invitation_live/send_test.exs`.
   - Strengthened the Membership Admin invitation lifecycle test to prove that, after Dana accepts Robin’s Membership Admin invitation:
     - Dana has an active club membership.
     - Dana does **not** have `club.manage_members`.
     - No `MemberPermission` projection grants Dana that permission.
   - No production code changes were needed; the existing acceptance flow already creates only an active membership and does not assign roles/permissions.

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba_web/live/member_invitation_live/send_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/member_invitation_live/send_test.exs`
     - Blocked by the known direct-mix sandbox Postgres lock/readiness issue.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `734 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `734 tests, 0 failures`; acceptance suite `69 scenarios, 466 steps` passed.
     - Note: an initial full `dev check` attempt timed out while the quality-gate lock was held; a rerun completed successfully.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 009 Ensure accepted Membership Admin invitations create ordinary active memberships only.`
   - To:
     - `- [x] 009 Ensure accepted Membership Admin invitations create ordinary active memberships only.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR/project conformance**
   - The plan references no explicit ADRs, and no `docs/adr/` files were present to inspect.
   - Followed local project guidance for Phoenix/LiveView tests and Elixir/Mix validation.
   - Kept the change focused on the selected task and did not alter acceptance features, routing, production invitation logic, or later planned tasks.