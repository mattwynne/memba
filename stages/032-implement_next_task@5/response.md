1. **Selected todo line**
   - `- [ ] 005 Ensure ordinary members do not see the invitation action and cannot use it by direct URL or crafted request.`

2. **Changes made**
   - Updated `web/test/memba_web/live/member_dashboard_live_test.exs`
     - Added coverage that an ordinary member on a club subdomain does **not** see the `Invite member` action or any invitation link in the members section.
   - Updated `web/test/memba_web/live/member_invitation_live/new_test.exs`
     - Added coverage that an ordinary member cannot craft a club-subdomain request directly to `/members/invitations/new`; it raises `MembaWeb.ForbiddenError`.
   - No production code changes were needed; the earlier permission gate already enforced the behavior.

3. **Validation**
   - Attempted focused test:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_invitation_live/new_test.exs`
     - Did not reach ExUnit because the sandbox Postgres wrapper hit an existing `postmaster.pid` lock.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `730 tests, 0 failures`.
   - Full validation:
     - First `PATH="$PWD/bin:$PATH" dev check` attempt timed out while another quality gate lock was active.
     - Retried `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `730 tests, 0 failures`; `69 scenarios (69 passed), 466 steps (466 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Ensure ordinary members do not see the invitation action and cannot use it by direct URL or crafted request.`
   - To:
     - `- [x] 005 Ensure ordinary members do not see the invitation action and cannot use it by direct URL or crafted request.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0015: member-facing invitation surface remains LiveView-based.
   - ADR 0013: added user-facing web regression coverage for visibility and authorization behavior.
   - ADR 0009: continued using projection-backed permission behavior; no duplicate permission state added.
   - ADR 0022: no new write/read-after-write flow was introduced.