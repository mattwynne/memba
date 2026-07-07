1. **Selected todo line**
   - `005 Replace the #member-conversation-follow-control card + Follow/Stop buttons with a compact follow toggle (checkbox/switch) that reads as following/not-following from @following_conversation.`

2. **Changes made**
   - `web/lib/memba_web/controllers/page_html/message.html.heex`
     - Replaced the previous `#member-conversation-follow-control` card with a compact `<label class="follow-toggle">`.
     - Added `#member-conversation-follow-toggle` checkbox using `toggle toggle-primary toggle-sm`.
     - Bound checked state to `@following_conversation`.
     - Added compact text states:
       - `Following` / `Emailed on new replies`
       - `Not following` / `Not emailed on replies`
     - Removed old Follow / Stop following buttons from the markup.
     - Preserved `data-following` and `data-can-follow` on `#member-conversation-follow-control`.
     - Did **not** wire events yet; task `006` remains pending for that.

   - `web/test/memba_web/live/member_message_live/show_test.exs`
     - Updated heading-row test to assert the compact `.follow-toggle`, checkbox, unchecked state, and absence of old buttons.

   - `web/test/memba_web/live/member_message_live/show_reply_test.exs`
     - Updated reply/follow-state assertions to expect the compact toggle.
     - Updated the previous follow/unfollow button interaction test into a state-reflection test, since event wiring is intentionally deferred to task `006`.

   - `docs/iterations/046-conversation-page-alignment/todo.md`
     - Checked off task `005` only.

3. **Focused validation commands run and results**
   - TDD expected failure after updating tests:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs test/memba_web/live/member_message_live/show_reply_test.exs`
     - Failed as expected: old card/button markup did not satisfy `.follow-toggle` selectors.
   - After implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs test/memba_web/live/member_message_live/show_reply_test.exs`
     - Passed: `14 tests, 0 failures`.
   - Formatting:
     - `cd web && mix format --check-formatted lib/memba_web/controllers/page_html/message.html.heex test/memba_web/live/member_message_live/show_test.exs test/memba_web/live/member_message_live/show_reply_test.exs`
     - Passed.
   - Full UI-change validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 005 Replace the #member-conversation-follow-control card + Follow/Stop buttons with a compact follow toggle (checkbox/switch) that reads as following/not-following from @following_conversation.`
   - To:
     - `- [x] 005 Replace the #member-conversation-follow-control card + Follow/Stop buttons with a compact follow toggle (checkbox/switch) that reads as following/not-following from @following_conversation.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Plan references no explicit ADRs.
   - Inspected relevant accepted ADRs:
     - ADR 0015: member application pages use LiveView by default.
     - ADR 0013: member-facing web behaviour should be test-driven; lower-level `Phoenix.LiveViewTest` is acceptable for LiveView-specific mechanics.
   - This task keeps the member message detail in the existing LiveView/HEEx surface, adds focused LiveView assertions using stable DOM IDs/selectors, avoids acceptance feature-file changes, and leaves server-side follow/unfollow behaviour unchanged for the pending wiring task.