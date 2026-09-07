Implemented and checked off task 015. The production behavior was already established by task 013, so this task adds explicit regression coverage without unnecessary application changes.

1. Selected task

`015 Retain the current Everyone default when entered through existing routes; do not expose an audience selector.`

2. Changes made

- Strengthened [new_test.exs](/workspace/memba/web/test/memba_web/live/member_message_live/new_test.exs:148) to verify `/messages/new` selects the deterministic Everyone group and exposes neither `audience_group_id` nor `group_id` form controls.
- Strengthened [new_send_test.exs](/workspace/memba/web/test/memba_web/live/member_message_live/new_send_test.exs:31) with a member who belongs to both Everyone and a custom group. The test proves that the unscoped route:
  - still selects Everyone;
  - delivers to all Everyone members;
  - grants the resulting conversation to Everyone;
  - does not grant it to the custom group;
  - exposes no audience controls.
- No production code or acceptance feature files were changed. The new tests passed immediately because the task-013 implementation already provided the required behavior.

3. Validation

- Corrected focused command:

  `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/new_test.exs test/memba_web/live/member_message_live/new_send_test.exs`

  Result: 17 tests, 0 failures.

- Full quality gate:

  `PATH="$PWD/bin:$PATH" dev check`

  Result: passed, including browser acceptance.

- `git diff --cached --check`

  Result: passed.

The initial focused invocation used repository-relative `web/test/...` paths, which the wrapper rejected because it runs Mix from `web/`; no tests ran in that attempt.

4. Todo check-off

Changed only [todo.md](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:17):

`- [ ] 015 ...` → `- [x] 015 ...`

Task 016 is now the first unchecked task.

5. Todo structure

No tasks were split, added, removed, or reordered. The final three-file diff is staged with no unstaged changes.

6. ADR conformance

- ADR 0013: user-facing behavior is covered through focused LiveView tests.
- ADR 0015: compose remains a LiveView-owned member application flow.
- ADR 0019: tests exercise the canonical club-subdomain `/messages/new` route.
- ADR 0023: omitted group state retains the stable Everyone default, while explicit group selection remains URL-addressable.