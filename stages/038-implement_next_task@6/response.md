Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `005a Add the invitation action to the selected member-facing members surface for Membership Admins once it can target the route and permission-gated visibility.`

2. **Changes made**
   - `web/lib/memba_web/controllers/page_html.ex`
     - Added `member_invitation_path/2` helper preserving host-selected club routing (`/members/invitations/new`) and query fallback (`/members/invitations/new?club_id=...`).
   - `web/lib/memba_web/controllers/page_html/club.html.heex`
     - Added a permission-gated `#member-invite-member-link` in the `#club-members` section.
     - The link only renders when `@can_manage_members?` is true.
   - `web/test/memba_web/live/member_dashboard_live_test.exs`
     - Added coverage that Membership Admins see the invite action.
     - Added coverage that host-selected club routes omit `club_id`.
     - Existing ordinary-member non-visibility coverage remains intact.
   - `docs/iterations/029-membership-admin-invitations/todo.md`
     - Checked off only the selected task line.

3. **Validation commands run**
   - Attempted:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/member_dashboard_live_test.exs`
     - Failed before tests due inherited sandbox `PGHOST` mismatch.
   - Focused tests:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/live/member_dashboard_live_test.exs`
     - Passed: `15 tests, 0 failures`.
   - Formatting:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix format --check-formatted lib/memba_web/controllers/page_html.ex lib/memba_web/controllers/page_html/club.html.heex test/memba_web/live/member_dashboard_live_test.exs`
     - Passed.
   - Full required check for browser-facing UI change:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance tests: `69 scenarios (69 passed), 466 steps (466 passed)`.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Exact todo check-off made**
   - From:
     - `- [ ] 005a Add the invitation action to the selected member-facing members surface for Membership Admins once it can target the route and permission-gated visibility.`
   - To:
     - `- [x] 005a Add the invitation action to the selected member-facing members surface for Membership Admins once it can target the route and permission-gated visibility.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADR is explicitly referenced by the plan.
   - Relevant accepted ADRs were respected:
     - ADR 0015: kept the member-facing surface in the existing LiveView-backed dashboard.
     - ADR 0019: preserved host-based club routing for subdomain-selected clubs.
     - ADR 0013: added focused web coverage using the existing LiveView test style for selector/link mechanics.