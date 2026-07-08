1. **Selected todo line**
   - `004 Update MemberDashboardPresentation only as needed to pass through/prep roles for member rows; keep the HEEx template free of direct projection queries.`

2. **Changes made**
   - Updated `web/lib/memba_web/member_dashboard_presentation.ex`
     - `present_member/1` now explicitly ensures each member presentation row has a `:roles` key, defaulting to `[]` when absent.
     - No HEEx/template projection queries were added.
   - Updated `web/test/memba_web/member_dashboard_presentation_test.exs`
     - Added role/role-assignment projection aliases.
     - Added a focused presentation test proving:
       - member roles pass through into `assigns.members`;
       - role order from the Membership query is preserved;
       - no-role members have `roles: []`;
       - `current_member` also carries roles.
     - Extended the local active-member fixture return value with `membership_id` so tests can attach role assignments.

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/member_dashboard_presentation_test.exs`
     - Passed: `4 tests, 0 failures`
   - `cd web && mix format lib/memba_web/member_dashboard_presentation.ex test/memba_web/member_dashboard_presentation_test.exs`
     - Passed.
   - Re-ran focused test after formatting:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/member_dashboard_presentation_test.exs`
     - Passed: `4 tests, 0 failures`
   - Also ran:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - It still reports the same 5 existing unrelated web-test failures previously noted by the workflow; I am not treating it as passing evidence for this task.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Update MemberDashboardPresentation only as needed to pass through/prep roles for member rows; keep the HEEx template free of direct projection queries.`
   - To:
     - `- [x] 004 Update MemberDashboardPresentation only as needed to pass through/prep roles for member rows; keep the HEEx template free of direct projection queries.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan did not explicitly reference any ADRs.
   - Relevant local project guidance for Elixir/Phoenix tests was followed.
   - The change preserves CQRS separation: role data still comes through `Membership.list_active_members_of_club/1`; no direct projection query was added to the HEEx template.