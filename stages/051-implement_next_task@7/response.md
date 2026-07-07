1. **Selected todo line**
   - `007 Preserve the non-member state: when !@can_follow_conversation, show the existing "Only current club members can follow…" explanation instead of an interactive toggle.`

2. **Changes made**
   - `web/lib/memba_web/controllers/page_html/message.html.heex`
     - Wrapped the compact follow toggle in `if @can_follow_conversation`.
     - Added the `else` non-interactive state using the same `#member-conversation-follow-control` stable id and data attrs.
     - Restored the explanatory copy:
       - “Only current club members can follow this conversation in Memba.”
     - Ensured the non-member state does **not** render `#member-conversation-follow-toggle` or any follow/unfollow event wiring.
   - `web/test/memba_web/live/member_message_live/show_test.exs`
     - Added focused coverage for `can_follow_conversation: false`.
     - Asserts the explanatory copy renders.
     - Asserts the interactive toggle and old follow/unfollow buttons are absent.
   - `docs/iterations/046-conversation-page-alignment/todo.md`
     - Checked off task `007` only.

3. **Validation commands run**
   - Expected TDD failure after adding the test:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs`
     - Failed as expected because the explanation was not rendered.
   - Focused tests after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs`
     - Passed: `12 tests, 0 failures`.
   - Formatting check:
     - `cd web && mix format --check-formatted lib/memba_web/controllers/page_html/message.html.heex test/memba_web/live/member_message_live/show_test.exs`
     - Passed.
   - Broader focused LiveView tests:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs test/memba_web/live/member_message_live/show_reply_test.exs`
     - Passed: `15 tests, 0 failures`.
   - Full check because this is browser-facing LiveView/UI:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 007 Preserve the non-member state: when ...`
   - To:
     - `- [x] 007 Preserve the non-member state: when ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no explicit ADRs.
   - No `docs/adr/*.md` files are present.
   - Followed local Phoenix/LiveView/HEEx guidance: stable DOM ids retained, conditional HEEx used safely, and tests assert through selectors/LazyHTML rather than brittle raw HTML comparisons.