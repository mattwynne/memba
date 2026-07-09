Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `006 Remove the "Current members" heading block (including the redundant inline "Invite member" button) from the Members panel in club.html.heex; confirm the tab-row "Invite member" action still covers the same permission check (@current_member_can_manage_members?).`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html/club.html.heex`
     - Removed the Members panel header block containing:
       - `Current members`
       - the `hero-users` icon
       - the redundant inline `#member-invite-member-link` button.
     - Left the tab-row `#member-section-action-invite-member` intact with its existing `@current_member_can_manage_members?` permission guard.
   - Updated `web/test/memba_web/live/member_dashboard_live_test.exs`
     - Replaced positive assertions for the removed inline invite button with refutations.
     - Added/refined assertions that Membership Admins still get the tab-row invite action.
     - Added exact-count coverage that the members tab renders only one invite action.
     - Added coverage that the `Current members` heading is gone.
   - Updated `docs/iterations/050-club-home-conversation-and-member-row-fidelity/todo.md`
     - Checked off only task `006`.

3. **Focused validation commands/results**
   - Red check before implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs:149`
     - Failed as expected because `Current members` still rendered.
   - Focused green checks:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs:149 test/memba_web/live/member_dashboard_live_test.exs:379 test/memba_web/live/member_dashboard_live_test.exs:488 test/memba_web/live/member_dashboard_live_test.exs:680 test/memba_web/live/member_dashboard_live_test.exs:708 test/memba_web/live/member_dashboard_live_test.exs:755`
     - Passed: `28 tests, 0 failures, 22 excluded`.
   - Full affected test file:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
     - Passed: `28 tests, 0 failures`.
   - Full validation on final diff:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including `87 scenarios (87 passed)` and `536 steps (536 passed)`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 006 Remove the "Current members" heading block ...`
   - To:
     - `- [x] 006 Remove the "Current members" heading block ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan does not explicitly reference ADRs for this task.
   - Followed local Phoenix/HEEx and LiveView test guidance:
     - Minimal HEEx deletion.
     - Stable DOM selectors in tests.
     - No acceptance feature edits; those remain explicitly tracked by task `007`.
   - No architecture or ADR conflict found.