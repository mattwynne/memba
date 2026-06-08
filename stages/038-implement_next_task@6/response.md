Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `005 Ensure ordinary members do not see the invitation action and cannot use it by direct URL or crafted request.`

2. **Changes made**
   - Added regression coverage in `web/test/memba_web/live/member_dashboard_live_test.exs`:
     - Verifies an ordinary active member does **not** see any member-invitation affordance/link in the dashboard `#club-members` section.
   - Added regression coverage in `web/test/memba_web/live/club_member_invitations_live/new_test.exs`:
     - Verifies an ordinary active member on a club subdomain is rejected with `MembaWeb.ForbiddenError` / `403` when directly requesting `/members/invitations/new`.
   - Checked off only task `005` in `docs/iterations/029-membership-admin-invitations/todo.md`.

3. **Validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/club_member_invitations_live/new_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/club_member_invitations_live/new_test.exs`
     - Hit the known sandbox PGHOST readiness mismatch before tests started.
   - `devenv shell -- bin/mix test test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/club_member_invitations_live/new_test.exs`
     - Passed: `18 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `729 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 005 Ensure ordinary members do not see the invitation action and cannot use it by direct URL or crafted request.`
   - To:
     - `- [x] 005 Ensure ordinary members do not see the invitation action and cannot use it by direct URL or crafted request.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001: stays within Phoenix/Phoenix LiveView.
   - ADR 0007: continues using Membership context authorization boundaries already in place.
   - ADR 0009: validates projected permission/read-model based authorization behaviour without querying aggregates.
   - ADR 0015: keeps member-facing behaviour covered through LiveView tests.