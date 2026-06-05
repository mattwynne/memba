Implemented the next unchecked task.

1. **Selected todo line**
   - `004a Route-verify the People and Messages staff nav links after /admin/people and /admin/messages exist so the original task-003 working-link requirement is fully satisfied.`

2. **Changes made**
   - Updated `web/lib/memba_web/components/layouts.ex`
     - Changed staff nav People link from literal `href="/admin/people"` to verified LiveView navigation: `navigate={~p"/admin/people"}`
     - Changed staff nav Messages link from literal `href="/admin/messages"` to verified LiveView navigation: `navigate={~p"/admin/messages"}`
   - Updated `web/test/memba_web/components/layouts_test.exs`
     - Added assertions that People and Messages nav links render as LiveView navigation links with:
       - `data-phx-link="redirect"`
       - `data-phx-link-state="push"`
   - Updated `docs/iterations/021-staff-area-redesign/todo.md`
     - Checked off only task `004a`.

3. **Validation run**
   - TDD check after test update:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/components/layouts_test.exs`
     - Did not reach tests due known sandbox Postgres readiness wrapper issue.
   - TDD check inside devenv:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/components/layouts_test.exs'`
     - Failed as expected before implementation: missing `data-phx-link` attributes.
   - Formatting:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/components/layouts.ex test/memba_web/components/layouts_test.exs`
     - Passed.
   - Verified route compile validation:
     - `PATH="$PWD/bin:$PATH" bin/mix compile --warnings-as-errors`
     - Passed.
   - Focused layout tests:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/components/layouts_test.exs'`
     - Passed: `4 tests, 0 failures`.
   - Full validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed:
       - ExUnit: `516 tests, 0 failures`
       - Acceptance: `34 scenarios (34 passed), 215 steps (215 passed)`
   - Whitespace/status check:
     - `git diff --check`
     - Passed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 004a Route-verify the People and Messages staff nav links after /admin/people and /admin/messages exist so the original task-003 working-link requirement is fully satisfied.`
   - To:
     - `- [x] 004a Route-verify the People and Messages staff nav links after /admin/people and /admin/messages exist so the original task-003 working-link requirement is fully satisfied.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: Kept the implementation within Phoenix/Phoenix LiveView.
   - ADR 0013: Added focused web-facing test coverage for user-visible staff navigation behavior.
   - ADR 0015: Used LiveView navigation patterns (`<.link navigate={...}>`) for application/admin LiveView surfaces.