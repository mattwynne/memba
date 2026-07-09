Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `004 Resize the conversation subject heading in message.html.heex to match .page-title scale.`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html/message.html.heex`
     - Changed the conversation subject `<h1>` from hero-scale Tailwind classes:
       - `text-4xl ... sm:text-5xl`
     - To page-title-equivalent sizing:
       - `text-[38px] font-semibold leading-[1.08] tracking-[-0.032em] text-base-content`
   - Updated `web/test/memba_web/live/member_message_live/show_test.exs`
     - Added focused coverage asserting the subject heading uses the page-title scale classes.
     - Added refutations ensuring the old hero-scale classes are gone.
   - Checked off only task `004` in:
     - `docs/iterations/050-club-home-conversation-and-member-row-fidelity/todo.md`

3. **Focused validation commands/results**
   - Red check before implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs:99`
     - Failed as expected because the heading still used `text-4xl ... sm:text-5xl`.
   - Focused green check:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs:99`
     - Passed: `10 tests, 0 failures, 9 excluded`.
   - Full browser-facing validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including `87 scenarios (87 passed)` and `536 steps (536 passed)`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 004 Resize the conversation subject heading in \`message.html.heex\` to match \`.page-title\` scale.`
   - To:
     - `- [x] 004 Resize the conversation subject heading in \`message.html.heex\` to match \`.page-title\` scale.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR/reference conformance evidence**
   - No ADRs were explicitly referenced by this plan/task.
   - Followed local Phoenix/HEEx and LiveView testing guidance:
     - Minimal HEEx class change.
     - Test targets the key element ID `#member-message-subject`.
     - Used `LazyHTML`/LiveView rendering rather than raw HTML string matching.