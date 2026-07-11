Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `002 Rewrite the message detail HEEx/component markup to use the ported semantic classes while preserving IDs/test hooks and LiveView events needed by existing tests.`

2. **Changes made for this task**
   - Reworked message detail conversation-entry markup in `web/lib/memba_web/controllers/page_html.ex` to use the semantic structure/classes:
     - `.message`
     - `.message--original`
     - `.message__avatar`
     - `.message__body`
     - `.message__head`
     - `.message__name`
     - `.message__time`
     - `.message__text`
     - `.message__menu`
     - `.message__kebab`
     - `.message-menu`
   - Reworked `web/lib/memba_web/controllers/page_html/message.html.heex` to use:
     - `h1.page-title`
     - `#member-message-reply-composer.composer`
     - `.composer__head`
     - `.composer__title`
     - `.composer__as`
     - `.composer__actions`
     - `.composer__error`
   - Preserved existing IDs/test hooks/LiveView events, including:
     - `#member-message-detail`
     - `#member-message-subject`
     - `#member-conversation-follow-toggle`
     - delivery menu/link IDs and `data-testid`s
     - `#member-message-reply-form[phx-submit='post_reply']`
     - `#member-message-reply-body-input`
     - `#member-message-reply-submit-button`
   - Added `flex: 1 1 auto;` to `.message__body` in `web/assets/css/app.css` so the semantic message layout fills the card correctly without the removed Tailwind wrapper.
   - Updated focused LiveView tests in `web/test/memba_web/live/member_message_live/show_test.exs` to prove the rendered semantic structure is present and old oversized title utility classes are gone.

3. **Validation run**
   - TDD/focused failure first:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs`
     - Failed as expected before implementation on missing `.page-title` and direct `.message__avatar` semantic structure.
   - Focused validation after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs test/memba_web/live/member_message_live/show_reply_test.exs test/memba_web/app_css_test.exs`
     - Passed: `19 tests, 0 failures`
   - Full required browser-facing quality gate on the final working-tree state:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including `107 scenarios (107 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Rewrite the message detail HEEx/component markup to use the ported semantic classes while preserving IDs/test hooks and LiveView events needed by existing tests.`
   - to:
     - `- [x] 002 Rewrite the message detail HEEx/component markup to use the ported semantic classes while preserving IDs/test hooks and LiveView events needed by existing tests.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan did not explicitly reference ADRs.
   - Checked relevant current ADRs:
     - ADR 0015: member app pages remain LiveView-backed.
     - ADR 0013: lower-level `Phoenix.LiveViewTest` is appropriate here for LiveView-specific structural/selector assertions.
   - No routing, domain, data-model, command/event, projection, notification, or acceptance feature-file changes were made.