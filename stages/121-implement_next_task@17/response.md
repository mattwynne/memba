Implemented and checked off task 017:

> `017 Keep existing Everyone acceptance regressions passing.`

No production code, feature files, or step definitions needed changes—the existing Everyone scenarios pass at both acceptance layers.

Validation:

- `PATH="$PWD/bin:$PATH" dev test test/features/domain_cucumber_acceptance_test.exs`
  - `100 tests, 0 failures`
- `PATH="$PWD/bin:$PATH" dev acceptance features/member_message_deliverability.feature features/club_message_replies.feature`
  - Passed with exit status 0. The configured runner exercised the full browser suite, including both requested feature files.
- `git diff --check`
  - Passed.

Checked off [todo.md](/workspace/memba/docs/iterations/057-admin-group-email-conversations/todo.md:19):

```markdown
- [x] 017 Keep existing Everyone acceptance regressions passing.
```

No tasks were split, added, removed, or reordered. Task 018 remains unchecked and owns the Admin-scenario runner support, tag narrowing, and final `dev check`.

This preserves ADR 0003 and ADR 0010’s shared domain/browser acceptance contract. No feature tags or accepted scenarios were altered, and no sleep-based synchronization was introduced, consistent with ADR 0022.