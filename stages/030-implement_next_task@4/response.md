Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `004 In the same action slot, add the **Invite member** action linking to member_invitation_path, rendered only when @current_member_can_manage_members? (hidden otherwise).`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html/club.html.heex`
     - Added `#member-section-action-invite-member` inside `#member-section-tabs-action.section-tabs__action`.
     - Uses `member_invitation_path(@selected_club, club_id_source)`.
     - Uses primary small button styling.
     - Adds `data-action="members"` and `hidden` for the default Conversations state.
     - Renders only when `@current_member_can_manage_members?`.
   - Updated `web/test/memba_web/live/member_dashboard_live_test.exs`
     - Added coverage proving:
       - Manage-members users get the Members tab invite action in the section action slot.
       - The action links to `/members/invitations/new`.
       - The action is primary/small and tagged with `data-action="members"`.
       - Ordinary members do not get the section action invite button.
   - Updated `docs/iterations/045-club-home-section-tabs/todo.md`
     - Checked off only task `004`.

3. **Validation run**
   - TDD failure before implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs:104`
     - Failed as expected because the new invite action did not exist.
   - Focused validation after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs:104`
     - Passed: `20 tests, 0 failures, 19 excluded`.
   - Full validation on the final worktree diff:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance suite: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 004 In the same action slot, add the **Invite member** action linking to member_invitation_path, rendered only when @current_member_can_manage_members? (hidden otherwise).`
   - To:
     - `- [x] 004 In the same action slot, add the **Invite member** action linking to member_invitation_path, rendered only when @current_member_can_manage_members? (hidden otherwise).`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no ADRs explicitly.
   - No ADR markdown files were found under `docs/adr/`.
   - The change follows the approved plan scope for task `004` only and does not touch acceptance feature files.