Implemented packet `task-008c-34a236d-settings-query-1` with result `ready_for_review`.

Changes:

- Added [member_settings_query.ex](/workspace/memba/web/lib/memba_web/member_settings_query.ex), defining `:member_settings` / `:settings`.
- Added [member_settings_query_test.exs](/workspace/memba/web/test/memba_web/member_settings_query_test.exs), covering:
  - Exact four-field coherent result
  - Normalized primary and attached-email identity resolution
  - Fresh membership entry/departure and interest replacement
  - Selected-club membership loss
  - Fail-closed invalid contexts
  - Exact deduplicated interests and transient-state exclusions
- Wrote [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json).

Validation passed:

- Focused query plus unchanged MySettingsLive regression tests: `16 tests, 0 failures`
- `bin/mix format --check-formatted`: exit 0
- `git diff --check`: exit 0
- Worker result JSON parses successfully

Task 008C remains unchecked. No LiveView wiring, adapter, package, projector, plan, todo, ADR, matrix, or acceptance feature was changed. Per packet instructions, the full `dev check` was left to the deterministic workflow node.