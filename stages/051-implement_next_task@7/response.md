Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `007 Add/update component, LiveView, and template tests for button/avatar/status usage and the member delivery-colour mapping; keep existing member tests green.`

2. **Changes made**
   - Extended component tests in `web/test/memba_web/components/core_components_test.exs`:
     - `avatar/1` forwards member-page `id`, `data-testid`, `title`, and custom class while retaining shared avatar classes.
     - `status_badge/1` forwards member receipt data/ARIA attributes while retaining tone classes.
   - Extended source/design-system guard tests in `web/test/memba_web/member_page_design_system_alignment_test.exs`:
     - Verifies member page/layout sources call shared `<.button>`, `<.avatar>`, and `<.status_badge>` where expected.
   - Added LiveView coverage in `web/test/memba_web/live/member_dashboard_live_test.exs`:
     - Verifies the club-home active-member avatar stack renders the shared overflow avatar (`+2`) for larger member lists.
   - Added template/rendered HTML delivery-colour coverage in `web/test/memba_web/controllers/member_message_detail_test.exs`:
     - Verifies member delivery summary bars use `bg-sage-600`, `bg-warning`, and `bg-error`.

3. **Focused validation run**
   - Formatting:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba_web/components/core_components_test.exs test/memba_web/member_page_design_system_alignment_test.exs test/memba_web/live/member_dashboard_live_test.exs test/memba_web/controllers/member_message_detail_test.exs`
     - Passed.
   - Focused tests:
     - Initial `PATH="$PWD/bin:$PATH" bin/mix test ...` attempts failed before running tests due a sandbox Postgres readiness/socket path issue.
     - Re-ran with the previously working environment path:
       - `devenv shell -- bash -lc 'cd web && mix test test/memba_web/components/core_components_test.exs test/memba_web/member_page_design_system_alignment_test.exs test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_message_live/show_test.exs test/memba_web/controllers/member_message_detail_test.exs'`
       - Passed: `48 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev down`
     - No process manager was running.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 007 Add/update component, LiveView, and template tests for button/avatar/status usage and the member delivery-colour mapping; keep existing member tests green.`
   - to:
     - `- [x] 007 Add/update component, LiveView, and template tests for button/avatar/status usage and the member delivery-colour mapping; keep existing member tests green.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0006 respected: added member-facing delivery visual tests only; no staff delivery path changes.
   - ADR 0015 respected: LiveView member-page coverage was added for the member dashboard.
   - ADR 0013 respected: used lower-level component/LiveView/template tests where they directly validate implementation-specific design-system rendering and selectors.