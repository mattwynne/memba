1. **Selected todo line**
   - `002 In conversation_entry_card (page_html.ex), render @entry.message.inserted_at via that helper in the card head, beside the sender name — a timestamp on the original and every reply.`

2. **Changes made**
   - `web/lib/memba_web/controllers/page_html.ex`
     - Removed the temporary `_format_message_time` reference.
     - Added a `<time>` element beside the sender name inside `conversation_entry_card/1`.
     - Uses:
       - `format_message_time(@entry.message.inserted_at)` for display text.
       - `DateTime.to_iso8601(@entry.message.inserted_at)` for the `datetime` attribute.
       - `data-testid="member-conversation-entry-time"` for stable test selection.
   - `web/test/memba_web/live/member_message_live/show_test.exs`
     - Added timestamp assertions for the original message and both replies.
     - Allowed the test helper `create_message/1` to accept deterministic `inserted_at` / `updated_at` values.
   - `docs/iterations/046-conversation-page-alignment/todo.md`
     - Checked off only task `002`.

3. **Focused validation**
   - TDD check before implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs:98`
     - Failed as expected because timestamps were not rendered yet.
   - After implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs:98`
     - Passed.
   - Full related test file:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs`
     - Passed: `10 tests, 0 failures`.
   - Formatting:
     - `cd web && mix format --check-formatted lib/memba_web/controllers/page_html.ex test/memba_web/live/member_message_live/show_test.exs`
     - Passed.
   - Final project check on the completed diff:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance tests: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 002 In conversation_entry_card ...`
   - To:
     - `- [x] 002 In conversation_entry_card ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Reviewed relevant accepted ADRs:
     - ADR 0015: member app pages use LiveView by default.
     - ADR 0023: visible LiveView state should be URL-addressable where practical.
   - This task only adds server-rendered presentation to the existing LiveView-rendered member message page.
   - No routing, URL state, custom JavaScript, business rules, or acceptance feature files were changed.