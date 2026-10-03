Packet `task-008a-c0227b5-selected-club-authority-revision-7` is complete with result `ready_for_review`.

Changes:

- Membership notifications now emit all four justified keys: `club_members`, `membership`, selected-club `person_club`, and person-wide `person_clubs` in [memba_read_model_source.ex](/workspace/memba/web/lib/memba_web/live_query/memba_read_model_source.ex).
- Dashboard and conversation-detail queries now use selected-club `person_club` authority instead of broad `person_clubs` in [member_dashboard_query.ex](/workspace/memba/web/lib/memba_web/member_dashboard_query.ex) and [member_message_detail_query.ex](/workspace/memba/web/lib/memba_web/member_message_detail_query.ex).
- Tests now assert complete interest sets, exact Membership invalidation sets, real Binding loader counts, different-club isolation, and all eleven projector families.
- [migration-matrix.md](/workspace/memba/docs/iterations/067-live-projection-queries/migration-matrix.md) documents the corrected authority vocabulary and two-query projector audit.
- The required [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json) is valid and records no unresolved items.

Validation passed:

- Adapter/Binding suite: 44 tests, 0 failures.
- Dashboard/detail query suites: 8 tests, 0 failures.
- Format check: passed.
- `git diff --check`: passed.

The initial TDD runs failed as predicted—44 tests/5 failures in the adapter suite and 8 tests/2 failures in the query suites—showing the missing `person_club` and unintended `person_clubs` match before the correction.

Task 008A remains unchecked for independent review. Per the packet exclusion, the workflow-owned full `dev check` was not run in this worker node.