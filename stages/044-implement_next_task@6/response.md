Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `006 Update the LiveView/controller test: members render as named rows; the current member's row is marked "You"; the Invite action and empty state still behave as before.`

2. **Changes made**
   - Updated `web/test/memba_web/live/member_dashboard_live_test.exs` with a focused controller/template-style regression test covering:
     - Members render as `.member-row` rows inside `.member-list`
     - Avatar initials and member names render per row
     - Current member row has `data-current-member="true"` and displays `You`
     - Non-current rows do not display the current-member indicator
     - Invite actions remain visible for member admins
     - Invite actions remain hidden for ordinary members
     - First-member empty state remains present with its existing copy
     - Old avatar stack selector remains absent
   - Added a small `html_has_selector?/3` helper for LazyHTML selector + text assertions.

3. **Focused validation**
   - Passed:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
     - Result: `27 tests, 0 failures`
   - Passed:
     - `git diff --check -- web/test/memba_web/live/member_dashboard_live_test.exs`
   - Also attempted broader validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: failed with 5 failures in unrelated existing tests around `/` vs `/conversations` redirects and a design-system alignment assertion. I did not change unrelated behavior for this selected task.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Update the LiveView/controller test: members render as named rows; the current member's row is marked "You"; the Invite action and empty state still behave as before.`
   - To:
     - `- [x] 006 Update the LiveView/controller test: members render as named rows; the current member's row is marked "You"; the Invite action and empty state still behave as before.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no explicit ADRs.
   - No `docs/adr/**/*.md` files were present.
   - Change is test-only and follows the local Phoenix/HEEx and Elixir test guidance read for this task.