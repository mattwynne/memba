Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `003 Add a section-tabs__action slot with a per-tab primary New message action on Conversations, linking to member_compose_path(@selected_club, club_id_source).`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html/club.html.heex`
     - Added `#member-section-tabs-action.section-tabs__action`
     - Added `#member-section-action-new-message`
     - Uses `<.button variant="primary" size="sm">`
     - Links via `member_compose_path(@selected_club, club_id_source)`
     - Marks the action with `data-action="conversations"`
   - Updated `web/test/memba_web/live/member_dashboard_live_test.exs`
     - Added focused coverage proving the Conversations tab action renders as:
       - `.section-tabs__action`
       - primary small button
       - text `New message`
       - `href="/messages/new"`
       - `data-action="conversations"`
   - Updated `docs/iterations/045-club-home-section-tabs/todo.md`
     - Checked off only task `003`.

3. **Validation run**
   - TDD failure before implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs:66`
     - Failed as expected because the new action slot/button did not exist.
   - Focused validation after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs:66`
     - Passed: `19 tests, 0 failures, 18 excluded`.
   - Full final validation on the final worktree state:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance suite: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Add a ...`
   - to:
     - `- [x] 003 Add a ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no ADRs directly.
   - No ADR markdown files were found under `docs/adr/`.
   - The change stays within the selected task scope and preserves later unchecked work for Invite member, panels, CSS, and JS tab switching.