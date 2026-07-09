Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `006 Remove the "Current members" heading block (including the redundant inline "Invite member" button) from the Members panel in club.html.heex; confirm the tab-row "Invite member" action still covers the same permission check (@current_member_can_manage_members?).`

2. **Changes made**
   - `web/lib/memba_web/controllers/page_html/club.html.heex`
     - Removed the Members panel header block containing:
       - `Current members`
       - redundant inline `#member-invite-member-link`
     - Left the existing tab-row `#member-section-action-invite-member` intact with its existing `@current_member_can_manage_members?` permission guard.
   - `web/test/memba_web/live/member_dashboard_live_test.exs`
     - Updated tests that expected the removed inline invite button.
     - Added/updated assertions that:
       - `Current members` no longer renders in the Members panel.
       - `#member-invite-member-link` no longer renders.
       - membership admins still see the tab-row `Invite member` action on the Members tab.
       - ordinary members still do not see the invite action.
       - the rendered club home has exactly one invite action for a member who can manage members.

3. **Validation commands/results**
   - TDD red run after updating expectations, before template removal:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
     - Failed as expected on remaining `Current members` heading / inline invite button.
   - Focused validation after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
     - Passed: `30 tests, 0 failures`.
   - Focused validation rerun after cleanup:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
     - Passed: `30 tests, 0 failures`.
   - Full validation on final worktree state:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `87 scenarios (87 passed), 536 steps (536 passed)`.

4. **Exact todo check-off made**
   - Changed only task `006` from:
     - `- [ ] 006 Remove the "Current members" heading block ...`
   - To:
     - `- [x] 006 Remove the "Current members" heading block ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0015 respected: club home remains a member application LiveView surface.
   - ADR 0013 respected: user-visible behaviour is covered with LiveView/Phoenix tests.
   - ADR 0023 respected: URL-addressable tab state and LiveView patch behaviour remain unchanged.
   - Acceptance feature files were not edited; those updates are explicitly reserved for later task `007`.