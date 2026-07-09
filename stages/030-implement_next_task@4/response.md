1. **Selected todo line**
   - `004 Rewrite the club-home conversation row in club.html.heex to use the ported classes, rendering the avatar-stack via the existing <.avatar> component for each participant plus an overflow badge.`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html/club.html.heex`:
     - `#member-message-list` now uses `conversation-list`.
     - Conversation links now use `conversation`.
     - Row internals now use:
       - `conversation__avatar`
       - `conversation__body`
       - `conversation__head`
       - `conversation__subject`
       - `conversation__date`
       - `conversation__preview`
       - `conversation__participants`
       - `conversation__replies`
     - Participant avatars render through `<.avatar>` inside `.avatar-stack`.
     - Overflow renders as `.is-more` with `+N`.
     - Existing acceptance-oriented `data-testid` and row/link attributes were preserved.
   - Updated `web/test/memba_web/live/member_dashboard_live_test.exs`:
     - Added focused rendering coverage for the design-system row classes, participant avatar stack, and overflow badge.
     - Updated an existing preview selector assertion from the old `line-clamp-1` class to `conversation__preview`.
   - Updated `docs/iterations/051-conversation-participant-avatar-stack/todo.md` to check off task `004` only.

3. **Validation commands/results**
   - TDD red run after adding the test:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
     - Failed as expected on missing `#member-message-list.conversation-list`.
   - Focused green run:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
     - Passed: `29 tests, 0 failures`.
   - Formatting check:
     - `cd web && mix format --check-formatted lib/memba_web/controllers/page_html/club.html.heex test/memba_web/live/member_dashboard_live_test.exs`
     - Passed.
   - Full required UI validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance suite: `88 scenarios (88 passed)`, `541 steps (541 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Rewrite the club-home conversation row in ...`
   - to:
     - `- [x] 004 Rewrite the club-home conversation row in ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The iteration plan references no ADRs.
   - `docs/adr/**/*` is empty in this checkout.
   - Followed local Phoenix/HEEx/LiveView/frontend guidance: used HEEx component syntax, preserved selectors for tests, reused the existing `<.avatar>` component, avoided inline scripts and `@apply`, and ran full `dev check` because this is browser-facing UI work.