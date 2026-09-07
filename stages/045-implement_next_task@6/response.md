Implemented task 006:

> Return the same not-found result for missing, foreign-club, or non-member group selection.

Changes:

- Updated [member_dashboard_presentation.ex](/workspace/memba/web/lib/memba_web/member_dashboard_presentation.ex:49) so explicit group selections return `{:error, :not_found}` for invalid, missing, foreign-club, or unauthorized groups.
- Kept club and identity authorization failures as `{:error, :forbidden}`.
- Preserved the existing Everyone-route behavior of `load/3`.
- Added a focused regression test in [member_dashboard_presentation_test.exs](/workspace/memba/web/test/memba_web/member_dashboard_presentation_test.exs:381) covering:
  - an unknown group ID;
  - a group belonging to another club;
  - a same-club private group the current member has not joined.
- The test was written first and failed against the previous `:forbidden` result before the implementation change.

Validation passed:

- `PATH="$PWD/bin:$PATH" dev test test/memba_web/member_dashboard_presentation_test.exs` — 9 tests, 0 failures.
- `PATH="$PWD/bin:$PATH" dev check --quick` — 1,146 tests, 0 failures.
- `PATH="$PWD/bin:$PATH" dev check` — full ExUnit and acceptance/browser quality gate passed.
- `git diff --check` — passed.

Checked off exactly [task 006](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:8). No tasks were split, added, removed, or reordered; task 007 remains next.

ADR conformance:

- ADR 0007 and 0009: authorization continues through Membership’s public group-summary API without exposing projection schemas to the web layer.
- ADR 0015 and 0023: existing LiveView and URL-state architecture remains unchanged; route work is correctly left for task 007.
- The result is privacy-preserving: callers cannot distinguish an unknown group from a foreign or inaccessible private group.