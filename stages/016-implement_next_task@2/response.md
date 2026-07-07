Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `002 Render each of @members as a member-row: avatar initials + the member's name.`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html/club.html.heex`:
     - Replaced the remaining avatar-stack/overflow member rendering with one `.member-row` per `@members` item.
     - Each row now includes:
       - stable row id: `club-member-#{member.id}`
       - `data-testid="club-member-row"`
       - member id/name data attributes
       - `.member-row__avatar` with initials
       - `.member-row__name` with the member name
     - Kept the existing first-member empty-state copy; adjusted its preview avatar so it no longer duplicates the member row id/test id.
   - Removed now-unused `active_member_count_label/1` from `web/lib/memba_web/controllers/page_html.ex`.
   - Updated focused LiveView tests in `web/test/memba_web/live/member_dashboard_live_test.exs` to assert named member rows and refute the old avatar stack/overflow affordance.

3. **Validation**
   - TDD red check:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
     - Result: expected failure, `25 tests, 5 failures`.
   - Focused green check:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
     - Result: `25 tests, 0 failures`.
   - Final full check on the final worktree:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: passed, including `85 scenarios (85 passed)` and `523 steps (523 passed)`.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 002 Render each of @members as a member-row: avatar initials + the member's name.`
   - To:
     - `- [x] 002 Render each of @members as a member-row: avatar initials + the member's name.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Plan references no explicit ADRs.
   - Reviewed relevant accepted ADRs: Phoenix core app, LiveView for member application pages, URL-addressable LiveView state, and Phoenix web testing guidance.
   - Kept the work within the existing LiveView/template route structure, added no custom JS/routes, and made no acceptance feature-file changes.