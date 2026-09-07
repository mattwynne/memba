Implemented task 007: canonical group-scoped Conversations and Members routes are working, authorized server-side, and the full `dev check` passes.

1. Selected task

   `007 Add canonical group-scoped member routes for Conversations and Members using an opaque group ID, while retaining /conversations and /members as Everyone routes.`

2. Changes

   - Added canonical routes in [router.ex](/workspace/memba/web/lib/memba_web/router.ex:70):
     - `/groups/:group_id` → Conversations
     - `/groups/:group_id/members` → Members
   - Retained `/conversations` and `/members` as Everyone routes.
   - Updated [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex:16) to:
     - load and authorize the route’s opaque group ID;
     - reload scoped dashboard data when route parameters change;
     - preserve the selected group during read-model refreshes;
     - return the ordinary 404 response for malformed or unauthorized groups.
   - Added router coverage in [router_test.exs](/workspace/memba/web/test/memba_web/router_test.exs:107).
   - Added LiveView integration coverage in [member_dashboard_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_live_test.exs:71) proving:
     - group-scoped conversation filtering;
     - group-scoped member filtering;
     - correct Members-section routing;
     - non-member and malformed group URLs return 404 without disclosure;
     - existing Everyone route mappings remain intact.
   - Left task 008 navigation-link preservation untouched.

3. Validation

   - TDD red run: focused suite initially reported 52 tests, 3 expected failures because the scoped routes did not exist.
   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/router_test.exs test/memba_web/live/member_dashboard_live_test.exs`
     - 52 tests, 0 failures.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Full ExUnit, acceptance, browser, formatting, and quality gate passed.
   - `git diff --check`
     - Passed.

4. Todo check-off

   Checked off only [task 007](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:9).

5. Todo structure

   No tasks were split, added, removed, or reordered. Task 008 remains the next unchecked task.

6. ADR conformance

   The plan contains no explicit ADR references. The implementation conforms to the relevant accepted decisions:

   - ADR 0013: route behavior is covered with user-facing LiveView tests plus focused router assertions.
   - ADR 0015: the member dashboard remains a LiveView.
   - ADR 0019: club identity remains host/session-selected; no club ID was added to member URLs.
   - ADR 0023: selected group and section are URL-addressable and handled through LiveView routes and `handle_params/3`.
   - ADRs 0007/0009, referenced by the iteration’s implementation notes: the web layer continues through `MemberDashboardPresentation` and Membership’s public API without querying Membership projection schemas directly.