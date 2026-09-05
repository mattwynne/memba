Implemented task 014 and left the final working-tree state passing `dev check`.

1. Selected task

> `014 Refactor current web query callers to pass the Everyone group, preserving the existing visual UI and ensuring Admin conversations remain absent until the later group display iteration.`

2. Changes made

- The dashboard now derives the club’s deterministic Everyone group and calls `Messaging.list_conversations_for_group/1` in [member_dashboard_presentation.ex](/workspace/memba/web/lib/memba_web/member_dashboard_presentation.ex:98).
- Message and delivery detail loading now calls `Messaging.list_conversation_messages_for_group/2` before assembling any detail data in [member_message_detail.ex](/workspace/memba/web/lib/memba_web/member_message_detail.ex:29).
  - Admin-only and otherwise inaccessible conversations return `{:error, :not_found}`.
  - Direct URLs cannot expose the message subject, body, receipts, follow state, or reply UI.
  - Root and reply URL behavior remains unchanged for Everyone conversations.
- Added browser-facing and loader coverage proving:
  - Admin conversations are absent from the dashboard.
  - Admin-only detail routes return 404 without leaking content.
  - Existing Everyone presentation remains unchanged.
- Added group-access-aware projection fixtures in [messaging_fixtures.ex](/workspace/memba/web/test/support/messaging_fixtures.ex:1) and updated affected web tests to create the grants now required by the production query boundary.
- No templates, routes, feature files, or visual presentation were changed.

3. Validation

- Test-first focused run: `12 tests, 2 failures`, both demonstrating the previous Admin disclosure.
- After implementation:
  - Focused loader tests: `12 tests, 0 failures`.
  - Affected dashboard/detail tests: `112 tests, 0 failures`.
- `git diff --check`: passed.
- Full `PATH="$PWD/bin:$PATH" dev check`: passed on the exact final diff, including the todo check-off. This included the complete ExUnit and browser acceptance gates.

4. Todo check-off

Updated [todo.md](/workspace/memba/docs/iterations/057-admin-group-email-conversations/todo.md:16) exactly to:

```markdown
- [x] 014 Refactor current web query callers to pass the Everyone group, preserving the existing visual UI and ensuring Admin conversations remain absent until the later group display iteration.
```

Tasks 015–018 remain unchecked.

5. Todo structure

No tasks were split, added, removed, or reordered.

6. ADR conformance

The iteration plan explicitly references no ADRs. Relevant accepted decisions remain satisfied:

- ADR 0007: the web uses public Membership and Messaging APIs without querying another context’s projection schemas.
- ADR 0009: reads remain backed by the established Messaging projections and access-grant queries.
- ADR 0015: existing member LiveView boundaries and route behavior are preserved.
- ADRs 0021/0022: no projector publication, consistency, or synchronization behavior was changed.