Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `005 Adjust shared member app layout/footer rendering so authenticated member app pages use only the compact app footer and public/marketing/legal pages keep the full public footer.`

2. **Changes made**
   - `web/lib/memba_web/router.ex`
     - Added `plug :suppress_public_footer` to the authenticated `:club_member_required` pipeline, after active-member authorization.
     - The plug assigns `:hide_public_footer` for authenticated member app routes.
   - `web/lib/memba_web/components/layouts.ex`
     - Changed root footer suppression from message-detail path matching to a shared conn assign policy.
     - Public footer now hides when `conn.assigns.hide_public_footer == true`.
   - `web/test/memba_web/components/layouts_test.exs`
     - Added rendered layout coverage proving:
       - member app chrome suppresses the full public footer while preserving compact footer content;
       - public pages keep the full public footer by default.
   - `web/test/memba_web/live/member_dashboard_live_test.exs`
     - Added routed dashboard coverage for `/conversations` and `/members` proving authenticated member app pages render exactly one compact footer and no public footer.
   - `docs/iterations/052-desktop-member-app-design-alignment/todo.md`
     - Checked off task `005` only.

3. **Validation**
   - TDD failure evidence:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
     - Failed as expected before implementation: dashboard rendered `2` footers instead of `1`.
   - Focused validation after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs`
       - Passed: `10 tests, 0 failures`.
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
       - Passed: `30 tests, 0 failures`.
   - Full validation on the staged final diff:
     - `PATH="$PWD/bin:$PATH" dev check`
       - Passed, including `107 scenarios (107 passed)` and `761 steps (761 passed)`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 005 Adjust shared member app layout/footer rendering so authenticated member app pages use only the compact app footer and public/marketing/legal pages keep the full public footer.`
   - To:
     - `- [x] 005 Adjust shared member app layout/footer rendering so authenticated member app pages use only the compact app footer and public/marketing/legal pages keep the full public footer.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0015 respected: authenticated member app surfaces remain LiveView routes; the footer policy is applied through the member route pipeline/shared layout.
   - ADR 0013 respected: behaviour is covered with Phoenix rendered/LiveView-style tests.
   - ADR 0023 unaffected: no URL-addressable state, route shape, or navigation semantics changed.
   - ADR 0001 respected: implementation stays within Phoenix/Plug layout and routing conventions.

Note: changes are staged and there are no unstaged diffs; no commit was created manually.