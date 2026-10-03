Packet `task-008a-8cb6cc9-full-projector-isolation-revision-6` is complete with result `ready_for_review` and no unresolved items.

Changes:

- Corrected [MembaReadModelSource](/workspace/memba/web/lib/memba_web/live_query/memba_read_model_source.ex:135):
  - Club compatibility publications now validate real identifiers and return `:ignore`.
  - Role definition emits `role` plus `club_roles`.
  - Permission grants emit only deliberate `club_permissions` fan-out.
  - Role assignment/removal and member removal emit only exact `member_roles` and `member_permissions`.
- Removed broad `club_members` and `group_members` interests from [MemberMessageDetailQuery](/workspace/memba/web/lib/memba_web/member_message_detail_query.ex:53), retaining exact fresh-authority and conversation dependencies.
- Added exact invalidation and Binding loader-count coverage in [memba_read_model_source_test.exs](/workspace/memba/web/test/memba_web/live_query/memba_read_model_source_test.exs:417).
- Updated the eleven-projector audit and both consumer mappings in [migration-matrix.md](/workspace/memba/docs/iterations/067-live-projection-queries/migration-matrix.md:160).
- Wrote the required [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json:1).

Validation passed:

- Adapter/Binding suite: 41 tests, 0 failures.
- Dashboard/detail query suite: 8 tests, 0 failures.
- `bin/mix format --check-formatted`: passed.
- `git diff --check`: passed.
- Worker-result JSON parsed successfully.

The predicted TDD failures matched before implementation: 7 adapter failures and the broad conversation-detail interest failure. Task 008A remains unchecked for independent acceptance. Per packet instructions, I did not run `dev check`; the deterministic workflow’s full gate owns that validation.