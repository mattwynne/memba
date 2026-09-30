Implemented packet `task-003-95b3c6a-dashboard-boundary-1` with result `ready_for_review`.

Key changes:

- Added [member_dashboard_query.ex](/workspace/memba/web/lib/memba_web/member_dashboard_query.ex:1), which normalizes the authenticated email and reloads active-club authority on every invocation.
- Updated [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex:34) to:
  - subscribe before connected initial reads;
  - retain routed club ID and identity email as stable inputs;
  - store projection-backed dashboard data solely under `:dashboard`;
  - preserve existing notification predicates, access transitions, commands, and transient state.
- Added focused fresh-authority tests in [member_dashboard_query_test.exs](/workspace/memba/web/test/memba_web/member_dashboard_query_test.exs:1).
- Added single-assign and transient picker-state coverage in [member_dashboard_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_live_test.exs:33).
- Wrote the required [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json:1).

Validation passed:

- Focused dashboard/query/presentation/admission/targeted-add suite: 85 tests, 0 failures.
- `bin/mix format --check-formatted`
- `git diff --check`

No unresolved packet work. `todo.md` and acceptance features remain untouched. Per packet instructions, the unscoped `dev check` was not run; the workflow’s deterministic `dev_check` node owns that final gate.