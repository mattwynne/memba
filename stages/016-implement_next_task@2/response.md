Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `002 Remove conversation_entry_label/1 and its call site in page_html.ex.`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html.ex`
     - Removed the `member-conversation-entry-label` badge rendering from `conversation_entry_card/1`.
     - Removed the now-unused `conversation_entry_label/1` helper.
   - Updated `web/test/memba_web/controllers/member_message_detail_test.exs`
     - Added focused coverage that conversation entries still render, but no longer include the kind badge element.
     - Added a regression assertion that `"Original message"` is not rendered.

3. **Validation commands/results**
   - TDD red check before implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/controllers/member_message_detail_test.exs`
     - Failed as expected because `member-conversation-entry-label` still rendered.
   - Focused validation after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/controllers/member_message_detail_test.exs`
     - Passed: `5 tests, 0 failures`.
   - Full validation because this changes browser-facing UI:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Remove conversation_entry_label/1 and its call site in page_html.ex.`
   - To:
     - `- [x] 002 Remove conversation_entry_label/1 and its call site in page_html.ex.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan does not explicitly reference any ADRs.
   - Checked nearby relevant accepted ADRs:
     - ADR 0013: lower-level Phoenix helpers are acceptable when controller/template internals are specifically needed.
     - ADR 0015: no new member surface was introduced; this task only removes a badge from an existing member page.
   - Followed local Phoenix/HEEx guidance from `docs/reference/`.