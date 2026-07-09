1. **Selected todo line**
   - `001 Add a preview element to the club-home conversation row template using message_row.body, clamped to one line with CSS (no server-side character truncation).`

2. **Changes made**
   - Added a club-home conversation body preview in `web/lib/memba_web/controllers/page_html/club.html.heex`.
     - Renders `{message_row.body}` directly.
     - Uses `data-testid="message-body-preview"`.
     - Uses Tailwind `line-clamp-1` for one-line CSS clamping.
     - No server-side truncation added.
   - Updated `web/test/memba_web/live/member_dashboard_live_test.exs` to assert the rendered preview contains the full message body and has the `line-clamp-1` class.

3. **Validation**
   - TDD red check:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs:302`
     - Failed as expected before implementation because the preview element did not exist.
   - Focused green check:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs:302`
     - Passed after implementation.
   - Full quality gate on final worktree:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `87 scenarios (87 passed)`, `536 steps (536 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 001 Add a preview element...`
   - To:
     - `- [x] 001 Add a preview element...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Reviewed relevant accepted ADRs:
     - ADR 0001: Phoenix remains the core app stack.
     - ADR 0013: Added user-visible LiveView/Phoenix test coverage for the behaviour.
     - ADR 0015: Kept the member application surface in LiveView/template flow; no controller rendering shift.
   - Also followed local HEEx/LiveView guidance by using template-safe interpolation and selector-based LiveView assertions.