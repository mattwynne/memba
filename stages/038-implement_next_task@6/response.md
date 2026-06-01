1. **Selected todo line**
   - `006 Render the dashboard toward dashboard.jsx:`

2. **Changes made**
   - Updated `web/lib/memba_web/controllers/page_html/club.html.heex`
     - Reworked member dashboard layout toward `dashboard.jsx`:
       - compact hero/greeting and lede;
       - single “Got something to share?” CTA card linking to `/messages/new?club_id=<club_id>`;
       - polished recent-message rows using `@message_rows`;
       - sender initials/avatar, sender name, subject, timestamp label, receipt mini-bar, glance copy, and detail link;
       - designed no-messages empty state with “Send the first one” action;
       - compact active-members card with avatar stack and count.
     - Preserved key stable DOM attributes:
       - `data-testid="club-message-row"`
       - `data-testid="club-message-link"`
       - `data-testid="club-member-row"`
       - member/message data attributes.
   - Updated `web/lib/memba_web/controllers/page_html.ex`
     - Added small render helpers:
       - `first_name/1`
       - `active_member_count_label/1`
       - `receipt_segment_width/1`
   - Updated tests:
     - `web/test/memba_web/live/member_dashboard_live_test.exs`
       - Added focused assertions for polished CTA, message row rendering, receipt glance/mini-bar, timestamp, and active-member card.
       - Added empty-message state assertion.
     - `web/test/memba_web/controllers/page_controller_test.exs`
       - Updated expectations to match the polished dashboard structure/copy.
     - `web/test/memba_web/auth_gates_test.exs`
       - Updated active-member dashboard copy assertion.

3. **Focused validation commands run and results**
   - `cd web && mix format --check-formatted`
     - Passed.
   - `cd web && mix compile`
     - Passed.
   - Focused dashboard/controller/auth tests with dev Postgres:
     - `mix test test/memba_web/live/member_dashboard_live_test.exs test/memba_web/controllers/page_controller_test.exs test/memba_web/auth_gates_test.exs`
     - Result: `26 tests, 0 failures`.
   - Final required check:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `251 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Render the dashboard toward \`dashboard.jsx\`:`
   - To:
     - `- [x] 006 Render the dashboard toward \`dashboard.jsx\`:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0015 remains satisfied: the signed-in selected-club home continues to render through `MembaWeb.MemberDashboardLive`.
   - The public/logged-out club page boundary was not changed.
   - The dashboard remains inside `<Layouts.club_site>` and uses Phoenix/HEEx/Tailwind conventions plus `<.icon>`.
   - No acceptance feature files were changed.