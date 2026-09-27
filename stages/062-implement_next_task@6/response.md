Packet `006-8d42dd1-1` is `ready_for_review`.

Implemented:

- Added the signed-in `/groups/:group_id/members/add/:person_id` LiveView route with `:targeted_add`.
- Added route-driven target lifecycle and current actor authorization before calling `Membership.resolve_custom_group_target_authoritatively/3`.
- Added the focused Members-page panel with server-resolved identity, heading focus, active club-member context, welcome consequences, and authoritative already-member state.
- Preserved outside-admin conversation privacy and ensured denied/invalid requests reveal no protected person details.
- Verified direct GET and connected mount perform no membership mutation, emit no target `GroupMemberAdded`, and send no welcome.
- Added focused coverage in [member_dashboard_targeted_add_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_targeted_add_live_test.exs) and [router_test.exs](/workspace/memba/web/test/memba_web/router_test.exs).

Validation passed:

- Formatting check: exit 0.
- Router tests: 18 tests, 0 failures.
- Targeted-add LiveView tests: 7 tests, 0 failures.
- Authoritative resolver tests: 7 tests, 0 failures.
- Additional admission regression: 11 tests, 0 failures.

The result artifact is recorded in [latest-worker-result.json](/workspace/memba/docs/iterations/066-request-group-access/.delivery/latest-worker-result.json). There are no unresolved issues. `todo.md` remains untouched, and no explicit Add mutation, welcome dispatch, Cancel/Escape handling, acceptance feature, or browser journey was included. Per packet constraints, `dev check` was not run; task 009 owns that full gate.