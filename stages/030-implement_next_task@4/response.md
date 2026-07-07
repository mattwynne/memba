1. **Selected todo line**
   - `004 In message.html.heex, wrap the subject <h1> and the follow control in a detail-head row so the follow control sits compactly beside the title.`

2. **Changes made**
   - `web/lib/memba_web/controllers/page_html/message.html.heex`
     - Added `#member-message-heading-row.detail-head`.
     - Wrapped the subject in `.detail-head__main`.
     - Added `id="member-message-subject"` to the `<h1>`.
     - Moved existing `#member-conversation-follow-control` into that detail-head row beside the title.
     - Preserved the existing follow/unfollow buttons, events, copy, and member gating for later tasks.
   - `web/test/memba_web/live/member_message_live/show_test.exs`
     - Added a LiveView test proving the subject and follow control render as direct children of the detail-head row.
   - `docs/iterations/046-conversation-page-alignment/todo.md`
     - Checked off only task `004`.

3. **Focused validation**
   - TDD expected failure after adding the test:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs`
     - Failed as expected: new detail-head selector was absent.
   - After implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs`
     - Passed: `11 tests, 0 failures`.
   - Follow/reply regression:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_reply_test.exs`
     - Passed: `3 tests, 0 failures`.
   - Formatting:
     - `cd web && mix format --check-formatted lib/memba_web/controllers/page_html/message.html.heex test/memba_web/live/member_message_live/show_test.exs`
     - Passed.
   - Full validation for browser-facing UI change:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 004 In message.html.heex, wrap the subject <h1> and the follow control in a detail-head row so the follow control sits compactly beside the title.`
   - To:
     - `- [x] 004 In message.html.heex, wrap the subject <h1> and the follow control in a detail-head row so the follow control sits compactly beside the title.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Plan references no explicit ADRs.
   - Inspected relevant ADR context: ADR 0015 confirms member app pages should use LiveView patterns.
   - The change stays within the existing LiveView/HEEx surface, adds a focused LiveView test using stable DOM IDs/selectors, and does not alter routing, server-side follow behaviour, permissions, business rules, or acceptance feature files.