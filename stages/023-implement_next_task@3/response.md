Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `003 Apply the five message-detail decisions: `All conversations`, no helper sentence, inline `Replying as`, quiet posted note, compact member-app footer only.`

2. **Changes made**
   - Updated message detail template:
     - Back link copy is now `All conversations`.
     - Removed the helper sentence: `Your reply inherits the subject and is emailed to current followers except you.`
     - Kept `Replying as <name>` inline in `.composer__as` near the composer title.
     - Changed posted success feedback to quiet `.composer__note` styling.
   - Updated root layout handling narrowly for this task:
     - Suppresses the full public footer on message detail routes so only the compact `#club-site-footer.app-foot` remains there.
     - Left broader member-app footer policy work for task `005`.
   - Added/updated focused tests in:
     - `web/test/memba_web/live/member_message_live/show_test.exs`
     - `web/test/memba_web/live/member_message_live/show_reply_test.exs`

3. **Validation**
   - TDD failure first:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs test/memba_web/live/member_message_live/show_reply_test.exs`
     - Failed as expected: `14 tests, 4 failures`.
   - Focused tests after implementation:
     - Same command
     - Passed: `14 tests, 0 failures`.
   - Layout regression check:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs`
     - Passed: `8 tests, 0 failures`.
   - Full final gate on the exact final working tree:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including `107 scenarios (107 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Apply the five message-detail decisions: ...`
   - to:
     - `- [x] 003 Apply the five message-detail decisions: ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0015 respected: message detail remains a LiveView member app page.
   - ADR 0013 respected: used focused LiveView/ConnTest-style assertions for route/rendered UI mechanics.
   - ADR 0023 unaffected: no new URL-addressable state or routing semantics added.
   - No domain, data-model, permissions, command/event, projection, notification, or acceptance feature-file changes were made.