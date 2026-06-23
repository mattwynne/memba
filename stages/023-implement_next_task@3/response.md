Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 003 Update PageHTML.club (club.html.heex) #member-message-list markup to the`
   - Full plan task: update the member message list to render a conversation row with originator avatar, subject, “Started by …”, reply-activity line, original send date, and no delivery glance.

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html/club.html.heex`:
     - Uses originator avatar/initials.
     - Shows subject.
     - Shows `Started by <originator>`.
     - Shows reply activity (`No replies yet` / `N replies · latest from …`).
     - Keeps original send date display.
     - Removes receipt/delivery glance markup from home rows.
   - Removed now-unused `receipt_segment_width/1` helper from `PageHTML`.
   - Updated `web/test/memba_web/live/member_dashboard_live_test.exs` to assert the new conversation-row markup and absence of delivery glance.
   - No acceptance feature files changed.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/controllers/page_html.ex lib/memba_web/controllers/page_html/club.html.heex test/memba_web/live/member_dashboard_live_test.exs`
     - Passed.
   - `devenv shell -- bin/mix test test/memba_web/live/member_dashboard_live_test.exs`
     - Passed: `18 tests, 0 failures`.
     - Used `devenv shell --` because the direct wrapper test run hit the known sandbox Postgres readiness/socket issue.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed on the staged commit-ready diff.
     - Acceptance summary: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Update PageHTML.club (club.html.heex) #member-message-list markup to the`
   - To:
     - `- [x] 003 Update PageHTML.club (club.html.heex) #member-message-list markup to the`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: Kept the change inside the Phoenix web application/templates.
   - ADR 0015: Preserved the member dashboard LiveView surface and only updated its rendered template markup.
   - ADR 0013: Updated existing LiveView web tests to cover user-visible row rendering.
   - ADR 0006: Removed home-row delivery status rather than exposing more delivery/provider detail; delivery detail remains on the conversation/message page as planned.

Task 004 remains unchecked; the row link target was left unchanged while implementing this markup task.