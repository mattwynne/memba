1. **Selected todo line**
   - `004 Move selected-club dashboard data loading into the LiveView mount path plus a small query/presentation helper, MembaWeb.MemberDashboardPresentation, so the LiveView stays readable and the row-shaping logic is unit-testable:`

2. **Changes made**
   - Added `web/lib/memba_web/member_dashboard_presentation.ex`.
     - Loads/authorizes selected club from the signed-in identity’s active clubs.
     - Loads active members and adds initials/avatar-initials presentation data.
     - Derives current member from authenticated identity email.
     - Loads recent club messages newest-first.
     - Builds sender-name lookup data.
     - Shapes unit-testable `message_rows` with sender info and member-facing receipt summary data.
     - Queries receipt projections in one batched query for the dashboard rows.
   - Updated `web/lib/memba_web/live/member_dashboard_live.ex`.
     - Removed inline dashboard data-loading helpers.
     - Delegates selected-club dashboard assigns to `MembaWeb.MemberDashboardPresentation.load/3`.
   - Added `web/test/memba_web/member_dashboard_presentation_test.exs`.
     - Covers selected club/current member/member initials, recent messages, sender names, message row data, receipt summary data, and forbidden cases.

3. **Focused validation commands run**
   - Focused dashboard tests inside devenv with Postgres:
     - `mix test test/memba_web/member_dashboard_presentation_test.exs test/memba_web/live/member_dashboard_live_test.exs`
     - Result: `5 tests, 0 failures`
   - Formatting:
     - `cd web && mix format --check-formatted`
     - Result: passed
   - Required full check:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `248 tests, 0 failures`
   - Whitespace:
     - `git diff --check`
     - Result: passed

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Move selected-club dashboard data loading...`
   - To:
     - `- [x] 004 Move selected-club dashboard data loading...`

5. **Todo splits/additions/reordering**
   - None. No todo items were split, added, removed, or reordered.

6. **ADR conformance evidence**
   - ADR 0015 says authenticated member application pages, including club home/member dashboard, should use LiveView by default.
   - The member dashboard remains LiveView-backed, and its mount path now delegates dashboard data loading/presentation shaping to a dedicated helper.
   - The controller/public logged-out boundary from the previous completed task remains unchanged.