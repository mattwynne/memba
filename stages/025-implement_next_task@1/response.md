Implemented packet `task-008b-ef0b156-group-creation-query-1` with result `ready_for_review`.

Changes:

- Added [member_group_creation_query.ex](/workspace/memba/web/lib/memba_web/member_group_creation_query.ex:1), exposing query ID `:member_group_creation`, assign `:group_creation_context`, and inputs `club_id`/`authenticated_email`.
- Every load freshly resolves active-club authority, Person identity, active membership by Person ID, and manage-members permission.
- Returns only `selected_club` and `current_member`, with the exact nine required interests.
- Added [member_group_creation_query_test.exs](/workspace/memba/web/test/memba_web/member_group_creation_query_test.exs:1), covering normalized and attached-email authentication, authorization freshness, fail-closed inputs, exact interests, and transient-state exclusions.
- Updated [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json:1).
- Task 008B remains unchecked, and no LiveView wiring or other excluded files changed.

Validation passed:

- Focused query and unchanged LiveView regressions: `17 tests, 0 failures`
- `bin/mix format --check-formatted`: exit 0
- `git diff --check`: exit 0
- Worker-result artifact parses as valid JSON

The initial TDD run failed as expected with the query module absent. `dev check` was not run because the packet explicitly reserves the full gate for the deterministic workflow.