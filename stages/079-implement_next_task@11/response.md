Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `011 Add/update Phoenix/LiveView/rendered tests for: no full public footer on member app pages while public pages retain it.`

2. **Changes made**
   - Updated `web/test/memba_web/controllers/page_controller_test.exs`
     - Added a routed GET test proving public pages retain the full public footer.
     - Added coverage for `/`, `/about`, `/get-started`, `/terms`, and `/privacy`.
     - Strengthened the public club page test to assert the full public footer remains there too.
     - Added `assert_full_public_footer/1` helper checking:
       - `Red Donkey Technology Corp`
       - footer navigation
       - About / Terms / Privacy / Contact links.
   - Updated `web/test/memba_web/live/member_dashboard_live_test.exs`
     - Strengthened authenticated member dashboard/footer assertions to structurally refute the full public footer/nav/legal/contact links.
   - Updated `web/test/memba_web/live/member_message_live/show_test.exs`
     - Strengthened authenticated message-detail footer assertions to structurally refute the full public footer/nav/legal/contact links.

3. **Focused validation commands run**
   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/controllers/page_controller_test.exs test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_message_live/show_test.exs`
     - Passed: `83 tests, 0 failures`
   - `git diff --check`
     - Passed
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed on final current worktree: `961 tests, 0 failures`
   - Note: attempted `PATH="$PWD/bin:$PATH" dev format --check-formatted`, but this wrapper does not support that argument; validation continued with `dev check --quick`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 011 Add/update Phoenix/LiveView/rendered tests for: no full public footer on member app pages while public pages retain it.`
   - To:
     - `- [x] 011 Add/update Phoenix/LiveView/rendered tests for: no full public footer on member app pages while public pages retain it.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan did not explicitly reference any ADRs.
   - Scope stayed limited to rendered/controller/LiveView test coverage for the existing footer policy.
   - No routing, layout implementation, permissions, data model, migrations, acceptance feature files, or product behavior were changed.