Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `007 Wrap today's members content (avatar stack + count, invite gating) in a Members section-panel that is hidden by default.`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html/club.html.heex`
     - Wrapped the existing `#club-members` section in:
       - `#member-section-panel-members`
       - `class="section-panel"`
       - `data-panel="members"`
       - `hidden`
     - Kept the existing members content unchanged inside the wrapper:
       - avatar stack
       - active member count/card state
       - existing invite-member gating and link
   - Updated `web/test/memba_web/live/member_dashboard_live_test.exs`
     - Added a focused LiveView test asserting:
       - the Members panel renders hidden by default,
       - `#club-members` is inside that panel,
       - the invite link remains inside the panel for a member with manage-members permission,
       - active member count/state and avatar stack render inside the panel.
   - Updated `docs/iterations/045-club-home-section-tabs/todo.md`
     - Checked off task `007` only.

3. **Validation commands run**
   - Pre-implementation focused test, failed as expected:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs:165`
     - Result: `1 failure` because `#member-section-panel-members` was absent.
   - Post-implementation focused test:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs:165`
     - Result: `23 tests, 0 failures, 22 excluded`.
   - Full validation for browser-facing LiveView change:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: passed, including acceptance suite: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 007 Wrap today's members content (avatar stack + count, invite gating) in a Members \`section-panel\` that is hidden by default.`
   - To:
     - `- [x] 007 Wrap today's members content (avatar stack + count, invite gating) in a Members \`section-panel\` that is hidden by default.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no explicit ADRs.
   - No ADR-specific architecture changes were introduced.
   - Work stayed within the Phoenix/HEEx/LiveView member dashboard surface, followed local HEEx/LiveView testing guidance, and did not modify acceptance feature files.