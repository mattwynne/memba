Implemented the next unchecked task.

1. **Selected todo line**
   - `002 Remove conversation_entry_label/1 and its call site in page_html.ex.`

2. **Changes made**
   - Removed the conversation entry badge rendering from `web/lib/memba_web/controllers/page_html.ex`.
   - Removed the now-unused private helper:
     - `conversation_entry_label(:original)`
     - `conversation_entry_label(_kind)`
   - Updated `web/test/memba_web/live/member_message_live/show_test.exs` with coverage proving conversation entry labels are no longer rendered.

3. **Validation run**
   - TDD red check:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs:288`
     - Failed as expected before implementation because `[data-testid='member-conversation-entry-label']` still rendered.
   - Focused green check:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs:288`
     - Passed.
   - Full quality gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including `87 scenarios (87 passed)` and `536 steps (536 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Remove conversation_entry_label/1 and its call site in page_html.ex.`
   - To:
     - `- [x] 002 Remove conversation_entry_label/1 and its call site in page_html.ex.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: Kept the change within the Phoenix app.
   - ADR 0013: Added user-visible web test coverage for the presentation change.
   - ADR 0015: Preserved the LiveView member application surface and updated its LiveView-focused test coverage.