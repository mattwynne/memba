Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `005 Ensure ordinary members do not see the invitation action and cannot use it by direct URL or crafted request.`

2. **Changes made**
   - `web/lib/memba_web/member_dashboard_presentation.ex`
     - Added `can_manage_members?` dashboard assign using `Membership.person_has_club_permission?/3` and `Permissions.club_manage_members/0`.
   - `web/lib/memba_web/controllers/page_html/club.html.heex`
     - Added `data-can-manage-members` to `#club-members`, giving the dashboard a permission-gated visibility state for the future invite action.
   - `web/test/memba_web/member_dashboard_presentation_test.exs`
     - Added coverage that ordinary members do not get member-management visibility, including when a same-email member has permission in another club.
   - `web/test/memba_web/live/member_dashboard_live_test.exs`
     - Added coverage that ordinary members see `data-can-manage-members="false"` and do not see `#member-invite-member-link`.
   - `web/test/memba_web/live/member_invitation_live/new_test.exs`
     - Added direct LiveView-route rejection coverage for ordinary members.
     - Added host-selected direct URL rejection coverage for ordinary members.

3. **Validation commands run**
   - Formatting check:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/member_dashboard_presentation.ex lib/memba_web/controllers/page_html/club.html.heex test/memba_web/member_dashboard_presentation_test.exs test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_invitation_live/new_test.exs`
     - Passed.
   - Focused tests:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/member_dashboard_presentation_test.exs test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_invitation_live/new_test.exs`
     - Passed: `24 tests, 0 failures`.
   - Full required validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance tests: `69 scenarios (69 passed), 466 steps (466 passed)`.
   - Whitespace check:
     - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Ensure ordinary members do not see the invitation action and cannot use it by direct URL or crafted request.`
   - To:
     - `- [x] 005 Ensure ordinary members do not see the invitation action and cannot use it by direct URL or crafted request.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADR was explicitly referenced by the plan, and local `docs/adr/` contains only the template.
   - The implementation follows the plan/prior inspection guidance by:
     - keeping the member-facing surface as the existing LiveView-backed dashboard;
     - using the Membership public permission API instead of querying permission projections from the web layer;
     - preserving the actual admin-visible invite link for the next pending task (`005a`) while ensuring ordinary-member non-visibility and route rejection are covered now.