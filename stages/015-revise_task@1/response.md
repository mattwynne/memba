Implemented packet `task-008a-e881b12-isolation-vocabulary-revision-5` with result `ready_for_review`.

Changes:

- Tightened invalidations in [memba_read_model_source.ex](/workspace/memba/web/lib/memba_web/live_query/memba_read_model_source.ex:275):
  - Membership and GroupMembership no longer emit unchanged Person identities.
  - ConversationFollow emits only the exact member-follow relationship.
  - ConversationGroupAccess retains collection, exact-access, and conversation-wide authorization keys without unchanged Group identity.
- Removed producerless fallback interests from [member_dashboard_query.ex](/workspace/memba/web/lib/memba_web/member_dashboard_query.ex:15).
- Removed fallback and broad-follow interests from [member_message_detail_query.ex](/workspace/memba/web/lib/memba_web/member_message_detail_query.ex:15).
- Added Binding-level loader-count isolation tests proving unrelated notifications do not reread queries while relevant notifications do.
- Reconciled the four permitted rows in [migration-matrix.md](/workspace/memba/docs/iterations/067-live-projection-queries/migration-matrix.md:161).
- Wrote the required [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json:1). The todo remains unchecked.

Validation passed:

- Adapter and Binding tests: 34 tests, 0 failures.
- Dashboard and conversation-detail query tests: 8 tests, 0 failures.
- `bin/mix format --check-formatted`: passed.
- `git diff --check`: passed.
- Worker result JSON parses successfully.

The initial red runs matched the prediction: unrelated notifications caused loader counts to rise from one to two, and consumer tests exposed the fallback/broad-follow interests. No unresolved items remain. Per packet instructions, I did not run `dev check`; the deterministic workflow’s `dev_check` node owns that full gate.