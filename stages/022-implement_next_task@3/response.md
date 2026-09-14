Implemented task 009 and left it unchecked for independent review.

1. Selected task

   `- [ ] 009 Query candidates through Membership's public API, reauthorize on submit and render fresh membership after a successful transition.`

2. Changes made

   - Connected candidate and admin self-add buttons to the LiveView admission event, including server submission values and in-flight labels in [club.html.heex](/workspace/memba/web/lib/memba_web/controllers/page_html/club.html.heex:294).
   - Added the admission handler in [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex:107). Club, group, and authenticated actor identities come from server-owned assigns; only the target pair comes from the submitted action.
   - Submission calls the public actor-bearing `Membership.add_custom_group_member/2` use case with strong consistency, so the `Club` aggregate reauthorizes current actor, target, and group state.
   - Successful submission reloads the dashboard from projected Membership state. Added candidates disappear immediately, member rows/counts update, and outside admins receive the ordinary participating view after self-add.
   - Candidate loading continues through Membership’s public `list_active_members_of_club/1` and `list_active_members_of_group/1` APIs in [member_dashboard_presentation.ex](/workspace/memba/web/lib/memba_web/member_dashboard_presentation.ex:160).
   - Added feature-style LiveView coverage in [member_dashboard_admission_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_admission_live_test.exs:10) for:
     - member adding another active club member;
     - outside-admin self-add;
     - stale projected authorization being rejected by the authoritative aggregate.
   - No acceptance feature files were changed.

3. Validation

   - TDD red phase: all three new tests initially failed because the action buttons had no LiveView event.
   - Focused admission test: 3 tests, 0 failures.
   - Dashboard, presentation, admission, and domain dispatch suites: 71 tests, 0 failures.
   - `mix format --check-formatted` on all touched files: passed.
   - `git diff --check`: passed.
   - `dev check --quick`: 1,433 tests, 0 failures.

4. Task remains unchecked

   `- [ ] 009 Query candidates through Membership's public API, reauthorize on submit and render fresh membership after a successful transition.`

5. Todo changes

   None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

   - ADR 0013: user-visible behaviour is covered through `PhoenixTest` and the routed LiveView boundary.
   - ADR 0015: the member dashboard LiveView coordinates submission, context invocation, errors, and refreshed screen state.
   - ADRs 0021/0022: dispatch waits for committed projections before reloading projected membership.
   - ADR 0023: the existing URL-addressable Members route remains intact.
   - ADR 0024: authorization remains in the `Club` consistency boundary; the UI does not trust its projected permission preview on submit.