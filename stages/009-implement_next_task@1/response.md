Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `001 In the Members section-panel of web/lib/memba_web/controllers/page_html/club.html.heex (added in 045), replace the avatar-stack card with a member-list container.`

2. **Changes made**
   - Replaced the Members panel container:
     - From `id="active-members-card"` with card styling.
     - To `id="active-members-list"` with `class="member-list mt-4"`.
   - Updated focused LiveView tests to expect `#active-members-list.member-list`.
   - Added a refutation that `#active-members-card` no longer appears in the members panel.
   - Checked off only task `001` in `docs/iterations/048-named-member-rows/todo.md`.

3. **Validation run**
   - TDD red check:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
     - Result: expected failure, `25 tests, 5 failures`, because tests expected the new `member-list` before the template changed.
   - Focused green check:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
     - Result: `25 tests, 0 failures`.
   - Full validation on final worktree:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: passed, including `85 scenarios (85 passed)` and `523 steps (523 passed)`.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 001 ... replace the avatar-stack card with a member-list container.`
   - To:
     - `- [x] 001 ... replace the avatar-stack card with a member-list container.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan references no ADRs, and no ADR files were found under `docs/adr/*.md`.
   - Followed local Phoenix/HEEx and LiveView testing guidance:
     - Kept HEEx interpolation/class usage valid.
     - Added/updated focused LiveView tests.
     - Made no acceptance feature-file changes.