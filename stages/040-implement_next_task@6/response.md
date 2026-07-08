1. **Selected todo line**
   - `006 Add/update LiveView or presentation tests proving role badges render, no-role members show none, and removed members remain absent.`

2. **Changes made**
   - Added a LiveView test in `web/test/memba_web/live/member_dashboard_live_test.exs` proving:
     - role badges render with `member-row__role badge badge-primary badge-soft`
     - multiple roles render in alphabetical order
     - members with no roles render no role badges
     - removed/inactive members do not appear even if they have an active role assignment
   - Added local test helpers for creating projected roles and role assignments.
   - Updated `web/lib/memba_web/controllers/page_html/club.html.heex` to use `Map.get(member, :roles, [])`, preserving role badge rendering while avoiding `KeyError` for existing test/member rows that omit `:roles`.

3. **Focused validation commands run**
   - `cd web && mix format --check-formatted lib/memba_web/controllers/page_html/club.html.heex test/memba_web/live/member_dashboard_live_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
     - Passed: `28 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `85 scenarios (85 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Add/update LiveView or presentation tests proving role badges render, no-role members show none, and removed members remain absent.`
   - To:
     - `- [x] 006 Add/update LiveView or presentation tests proving role badges render, no-role members show none, and removed members remain absent.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan does not explicitly reference any ADRs.
   - I followed the local Phoenix/HEEx, LiveView, and frontend guidance.
   - The HEEx template still consumes presentation data only and does not query projections directly.