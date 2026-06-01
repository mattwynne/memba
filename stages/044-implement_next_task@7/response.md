1. **Selected todo line**
   - `007 Design and render empty states deliberately:`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html/club.html.heex`
     - Added an explicit active-member empty/first-member state when `@active_member_count <= 1`.
     - Preserved the current member’s `club-member-row` stable data attributes in the first-member state.
     - Kept the normal active-member avatar stack/copy only for clubs with more than one active member.
     - Added `data-active-members-state` to distinguish `first-member` vs `active-members`.
   - Updated `web/test/memba_web/live/member_dashboard_live_test.exs`
     - Asserted the message empty state is omitted when messages exist.
     - Asserted the active-member first-member copy appears only when the signed-in member is alone.
     - Asserted the normal active-member copy remains for multi-member clubs.

3. **Validation commands run**
   - `cd web && mix format --check-formatted`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `252 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - Note: direct bare `cd web && mix test test/memba_web/live/member_dashboard_live_test.exs` could not connect to Postgres outside the dev-managed service environment; `dev check` ran the test suite successfully with services.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 007 Design and render empty states deliberately:`
   - To:
     - `- [x] 007 Design and render empty states deliberately:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0015 remains satisfied: the signed-in selected-club dashboard continues to be rendered through `MembaWeb.MemberDashboardLive`.
   - The public/logged-out club page boundary was not changed.
   - The implementation stays in HEEx/Tailwind with `<.icon>` and no scripts/external assets.