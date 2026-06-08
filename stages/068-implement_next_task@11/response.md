Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 011 Add or update LiveView/controller tests for Membership Admin visibility, ordinary member non-visibility, and direct URL/action rejection.`

2. **Changes made**
   - Updated `web/test/memba_web/live/member_dashboard_live_test.exs`
     - Added coverage that a Membership Admin on a club subdomain sees the invite action at:
       - `#club-members #member-invite-member-link[href='/members/invitations/new']`
     - Asserted the subdomain link does not fall back to a `club_id` query string.
   - Updated `web/test/memba_web/live/member_invitation_live/new_test.exs`
     - Added coverage that an ordinary member cannot directly mount the invitation LiveView.
     - Asserted no `ClubInvitation` projection is created during the rejected access attempt.
   - Updated `docs/iterations/029-membership-admin-invitations/todo.md`
     - Checked off task 011 only.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_invitation_live/new_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_invitation_live/new_test.exs`
     - Blocked before tests executed by sandbox Postgres readiness/socket-path issue.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `737 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 011 Add or update LiveView/controller tests for Membership Admin visibility, ordinary member non-visibility, and direct URL/action rejection.`
   - To:
     - `- [x] 011 Add or update LiveView/controller tests for Membership Admin visibility, ordinary member non-visibility, and direct URL/action rejection.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No ADRs are explicitly referenced by the iteration plan.
   - Relevant accepted ADRs were checked:
     - ADR 0015: member application surfaces use LiveView — tests target existing LiveViews.
     - ADR 0013: feature-style web tests may use PhoenixTest, with lower-level LiveViewTest when useful — these focused tests use existing `Phoenix.LiveViewTest` patterns and stable selectors.
     - ADR 0019: local club subdomains use `lvh.me` — added subdomain coverage using `wcp.lvh.me`.