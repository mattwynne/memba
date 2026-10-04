Implemented packet `task-009a-4621875-group-live-binding-1` with result `ready_for_review`.

- Migrated [new.ex](/workspace/memba/web/lib/memba_web/live/member_group_live/new.ex:24) to the accepted `LiveQuery.Binding` using the sole projection-backed `:group_creation_context` assign and stable `current_identity_email`.
- Removed the old `group_context/3` and email-comparison member lookup.
- Routed committed read-model notifications through the binding. Relevant changes refresh the context; membership or manage-members loss raises the existing `ForbiddenError`.
- Preserved generated group identity, routes, typed forms, previews, validation errors, retry behavior, commands, flash, navigation, and UI.
- Added focused refresh, isolation, state-preservation, and access-loss coverage in [new_test.exs](/workspace/memba/web/test/memba_web/live/member_group_live/new_test.exs:119).
- Wrote the required [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json).

Validation:

- Focused test set: 68 tests, 0 failures.
- `bin/mix format --check-formatted`: passed.
- `git diff --check`: passed.
- Result artifact JSON parses successfully.

Task 009A remains unchecked. No plan, todo, acceptance feature, ADR, package, query, adapter, projector, schema, command, route, or later LiveView was changed. Per the packet, the full `dev check` was not run; the deterministic workflow owns that final gate.