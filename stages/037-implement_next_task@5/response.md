Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `005 Remove the "Recent club messages" heading block from the Conversations panel in club.html.heex.`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html/club.html.heex`
     - Removed the Conversations panel heading block containing:
       - `Recent club messages`
       - the `hero-envelope` icon
   - Updated `web/test/memba_web/live/member_dashboard_live_test.exs`
     - Added focused LiveView coverage asserting the Conversations panel no longer renders an `h2` with `Recent club messages`.
   - Updated `docs/iterations/050-club-home-conversation-and-member-row-fidelity/todo.md`
     - Checked off only task `005`.

3. **Focused validation commands/results**
   - TDD red check before implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs:302`
     - Failed as expected because the heading still rendered.
   - Focused green check after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs:302`
     - Passed: `28 tests, 0 failures, 27 excluded`.
   - Full validation on final working tree:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including `87 scenarios (87 passed)` and `536 steps (536 passed)`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 005 Remove the "Recent club messages" heading block from the Conversations panel in \`club.html.heex\`.`
   - To:
     - `- [x] 005 Remove the "Recent club messages" heading block from the Conversations panel in \`club.html.heex\`.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan did not explicitly reference any ADRs for this task.
   - Followed local Phoenix/HEEx and test guidance:
     - Minimal HEEx removal.
     - Added focused LiveView test coverage using stable DOM scope/selectors.
     - Did not touch acceptance feature files; those are reserved for the later explicit acceptance-update task.