Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `004 Resize the conversation subject heading in message.html.heex to match .page-title scale.`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html/message.html.heex`
     - Replaced hero-scale classes:
       - `text-4xl ... sm:text-5xl`
     - With `.page-title`-equivalent Tailwind sizing:
       - `text-[38px] font-semibold leading-[1.08] tracking-[-0.032em] text-base-content`
   - Updated `web/test/memba_web/live/member_message_live/show_test.exs`
     - Added a focused LiveView test asserting the subject uses page-title-scale classes.
     - Added a small `classes/2` helper for class assertions.

3. **Validation commands/results**
   - TDD red check before template update:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs`
     - Failed as expected because `#member-message-subject` still had `text-4xl` / `sm:text-5xl`.
   - Focused validation after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs`
     - Passed: `11 tests, 0 failures`.
   - Full validation on final working-tree diff:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance suite: `87 scenarios (87 passed), 536 steps (536 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Resize the conversation subject heading in message.html.heex to match .page-title scale.`
   - To:
     - `- [x] 004 Resize the conversation subject heading in message.html.heex to match .page-title scale.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan does not explicitly reference any ADRs.
   - No `docs/adr/*.md` files are present.
   - Change follows the iteration’s explicit scope and keeps the broader `.page-title` CSS-class port out of scope, using only local Tailwind-equivalent classes for this heading.