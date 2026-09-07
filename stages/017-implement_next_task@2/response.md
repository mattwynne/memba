Implemented and checked off task 020:

> Preserve correct access for a future conversation shared with several groups.

Changes:

- Added a focused regression test in [conversation_group_access_projection_test.exs](/workspace/memba/web/test/memba/messaging/conversation_group_access_projection_test.exs:239).
- The test creates one conversation shared with two groups at different access levels and proves:
  - A member of the read group can read but cannot write.
  - A member of the write group can both read and write.
  - An active club member outside both groups receives no access.
- The existing `Messaging.member_has_conversation_access?/4` implementation already correctly composes access across all active group memberships, so no production-code change was necessary.

Validation:

- `PATH="$PWD/bin:$PATH" dev test test/memba/messaging/conversation_group_access_projection_test.exs`
  - 9 tests, 0 failures.
- `PATH="$PWD/bin:$PATH" dev check --quick`
  - 1,169 tests, 0 failures.
- `git diff --check`
  - Passed.

Exact check-off in [todo.md](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:22):

```markdown
- [x] 020 Preserve correct access for a future conversation shared with several groups.
```

No tasks were split, added, reordered, or otherwise checked off. Tasks 021 and 022 remain pending.

ADR conformance:

- ADR 0002/0009: authorization remains a query over projected state; no aggregate or command responsibilities changed.
- ADR 0007: Messaging continues to obtain active group membership through Membership’s public query API rather than querying Membership projection schemas directly.
- ADR 0015/0023: no LiveView or route-state changes were introduced.
- ADR 0021/0022: no projection publication or synchronization behavior changed; the regression uses established event-sourced test infrastructure.