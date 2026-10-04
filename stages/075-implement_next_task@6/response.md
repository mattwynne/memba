Implemented packet `task-008f-e9eec54-invitation-context-query-1` with result `ready_for_review`.

- Added [member_invitation_query.ex](/workspace/memba/web/lib/memba_web/member_invitation_query.ex:21) with descriptor ID `:member_invitation`, assign `:invitation_context`, and stable `club_id` / `authenticated_email` inputs.
- The result contains exactly `selected_club`, `current_member`, and `active_member_count`.
- Every load normalizes the email, rereads active clubs, resolves the current Person and selected-club member by Person ID, counts active members, and rechecks `club.manage_members`.
- Interests cover `club`, `club_members`, exact `membership`, current `person`, exact `person_club`, exact `member_roles` / `member_permissions`, and same-club `club_roles` / `club_permissions`. No broad `person_clubs` interest is registered.
- Added [member_invitation_query_test.exs](/workspace/memba/web/test/memba_web/member_invitation_query_test.exs:23), proving primary and attached-email authentication, member entry/exit counts, membership and permission loss, fail-closed contexts, real adapter notification matching, unrelated-scope isolation, and exclusion of LiveView-owned transient state.
- Updated the required [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json:1). Task 008F remains unchecked in [todo.md](/workspace/memba/docs/iterations/067-live-projection-queries/todo.md:21).

Validation passed:

- Focused combined suite: `66 tests, 0 failures`
- `bin/mix format --check-formatted`: exit 0
- `git diff --check`: exit 0

Implementation changes are limited to the two packet-approved code/test paths. No LiveView wiring, adapter, package, read API, projector, schema, command, event, route, plan, todo, matrix, ADR, or acceptance feature changed. Per packet instructions, the full `dev check` was not run; the workflow’s deterministic gate owns that validation.