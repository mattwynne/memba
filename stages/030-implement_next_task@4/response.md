Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `004 Remove the desktop club-home `Prefer email?` card/copy.`

2. **Changes made**
   - Removed the club-home Conversations panel inbound email card from:
     - `web/lib/memba_web/controllers/page_html/club.html.heex`
   - Removed now-unused club-home inbound email helper plumbing from:
     - `web/lib/memba_web/controllers/page_html.ex`
   - Updated focused dashboard LiveView coverage in:
     - `web/test/memba_web/live/member_dashboard_live_test.exs`
   - Checked off only task `004` in:
     - `docs/iterations/052-desktop-member-app-design-alignment/todo.md`

3. **Validation**
   - TDD failure first:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
     - Failed as expected: `29 tests, 1 failure` on the new absence assertion.
   - Focused validation after implementation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
     - Passed: `29 tests, 0 failures`.
   - Full final validation on the final working tree including the todo check-off:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including `107 scenarios (107 passed)`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 004 Remove the desktop club-home `Prefer email?` card/copy.`
   - To:
     - `- [x] 004 Remove the desktop club-home `Prefer email?` card/copy.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0015 respected: club home remains a LiveView member app surface.
   - ADR 0013 respected: the change is covered with focused Phoenix/LiveView-style rendered assertions.
   - ADR 0023 unaffected: no routing or URL-addressable state semantics changed.
   - No permissions, data-model, command/event/projection, notification, or acceptance feature-file changes were made.