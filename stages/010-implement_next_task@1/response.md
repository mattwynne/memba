Completed task 001 only: “Inspect the current group projections and Messaging group queries from iterations 056–057.”

- Added durable findings to [implementation-notes.md](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/implementation-notes.md:1). The notes document the Membership group/group-membership read models, public query boundaries, Messaging conversation-access queries, stable ordering, authorization responsibilities, and the existing cross-club send invariant gap.
- No application code, configuration, migrations, or tests were changed.
- Focused validation passed:
  - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/query_test.exs test/memba/messaging/message_projection_test.exs test/memba/messaging/conversation_group_access_projection_test.exs`
  - Result: 44 tests, 0 failures.
  - `git diff --check` passed.
  - An initial test invocation used repository-relative `web/test/...` paths and was rejected because `dev test` runs inside `web/`; the corrected command above passed.
- Checked off exactly [todo task 001](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:3):
  - `- [x] 001 Inspect the current group projections and Messaging group queries from iterations 056–057.`
- No todo items were split, added, reordered, or otherwise changed.
- ADR conformance:
  - ADR 0007: Messaging and web code remain behind Membership’s public API; no projection-schema leakage was introduced.
  - ADR 0009: group and access tables remain query-side Commanded/Ecto projections.
  - ADRs 0021–0022: the notes confirm the existing strong projectors publish committed changes and participate in projection synchronization.
  - The plan did not explicitly reference an ADR; these were the nearby accepted ADRs relevant to this inspection.

`dev check` was not run because this task changed only iteration documentation and execution state; project guidance exempts docs-only changes.