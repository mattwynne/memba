Done. The selected-task diff is staged, with no unstaged changes.

1. **Selected todo line**
   - `009 Apply the boxed message-card treatment to the original and reply cards in conversation_entry_card so they match the design (message / message--original).`

2. **Changes made**
   - `web/lib/memba_web/controllers/page_html.ex`
     - Added design-system message card vocabulary to `conversation_entry_card/1`:
       - all entries now render with `message`
       - original entry additionally renders with `message--original`
       - child elements now carry mirror-friendly classes:
         - `message__avatar`
         - `message__body`
         - `message__head`
         - `message__name`
         - `message__time`
         - `message__text`
     - Preserved existing DOM IDs, data attributes, labels, timestamps, and Tailwind card treatment.
   - `web/test/memba_web/live/member_message_live/show_test.exs`
     - Added assertions that:
       - original conversation card has `.message.message--original`
       - reply cards have `.message`
       - reply cards do **not** have `.message--original`
   - `docs/iterations/046-conversation-page-alignment/todo.md`
     - Checked off only task `009`.

3. **Validation commands/results**
   - TDD failure before implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs`
     - Failed as expected on missing `.message.message--original`.
   - Focused LiveView tests after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs`
     - Passed: `12 tests, 0 failures`.
   - Formatting:
     - `cd web && mix format --check-formatted lib/memba_web/controllers/page_html.ex test/memba_web/live/member_message_live/show_test.exs`
     - Passed.
   - Full final validation on the staged selected-task diff:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 009 Apply the boxed message-card treatment...`
   - To:
     - `- [x] 009 Apply the boxed message-card treatment...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No ADRs are explicitly referenced by the plan, and no `docs/adr/*.md` files are present.
   - Change is presentation-only, scoped to the selected task, and preserves follow/reply/delivery behavior.