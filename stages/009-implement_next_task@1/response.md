Implemented the next unchecked task.

1. **Selected todo line**
   - `001 In web/lib/memba_web/controllers/page_html/club.html.heex, remove the #member-dashboard-hero greeting section; club/member identity now lives in the 044 app-bar.`

2. **Changes made**
   - Removed the `#member-dashboard-hero` greeting section from `web/lib/memba_web/controllers/page_html/club.html.heex`.
   - Removed now-unused `first_name/1` private helper from `web/lib/memba_web/controllers/page_html.ex`.
   - Updated `web/test/memba_web/live/member_dashboard_live_test.exs` to assert the hero is absent.
   - Updated existing acceptance step definition to assert club identity via `.app-bar__club` and ensure the old hero is absent:
     - `acceptance-tests/features/step_definitions/member_club_subdomain_steps.js`
   - No acceptance feature files were changed.

3. **Validation run**
   - TDD failure confirmed before implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs:66`
     - Failed as expected because `#member-dashboard-hero` still existed.
   - Focused test after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs:66`
     - Passed.
   - Full check for browser-facing UI change:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

4. **Todo check-off made**
   - Changed exactly this line:
     - `- [ ] 001 ...`
     - to:
     - `- [x] 001 ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no ADRs directly.
   - `docs/adr/` had no ADR files to inspect.
   - Change conforms to the plan’s explicit direction that club/member identity now lives in the 044 app-bar and the in-card hero greeting is removed.