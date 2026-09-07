Implemented and checked off task 022:

> Implement the planned Cucumber step support, remove/narrow runner-debt tags as each runner becomes executable, and run `dev check`.

Changes made:

- Added domain/application Cucumber steps for group discovery, named-group membership, conversation/member scoping, group-aware sending, recipient access, and private-group authorization in [group_conversation_steps.exs](/workspace/memba/web/test/features/step_definitions/group_conversation_steps.exs:1).
- Added Playwright/Cucumber steps covering all eight browser scenarios, including navigation, custom groups, composition, not-found behavior, and remembered selection in [group_conversation_steps.js](/workspace/memba/acceptance-tests/features/step_definitions/group_conversation_steps.js:1).
- Extended the acceptance command helper to send to an explicit audience group and allowed email assertions to inspect web-created Admin messages.
- Made the shared four-member prerequisite self-contained in [membership_steps.exs](/workspace/memba/web/test/features/step_definitions/membership_steps.exs:57).
- Removed feature-level `@todo-domain` and `@todo-ui` from [group_conversations.feature](/workspace/memba/acceptance-tests/features/group_conversations.feature:1).
- Narrowed the two browser-local persistence scenarios with `@not-domain`; the other six scenarios run at both layers.
- Updated acceptance configuration coverage to require all eight iteration-058 scenarios to be free of runner-debt tags in [cucumber_config.test.js](/workspace/memba/acceptance-tests/test/cucumber_config.test.js:82).

Validation passed:

- Domain Cucumber suite: 110 tests, 0 failures.
- Iteration-058 browser Cucumber: 8 scenarios, 50 steps, all passing.
- Browser acceptance configuration: 7 tests, all passing.
- JavaScript syntax checks: passed.
- `mix format --check-formatted`: passed.
- Full `PATH="$PWD/bin:$PATH" dev check`: exited successfully.
- `git diff --check`: passed.

The only change after full `dev check` was the non-executable todo check-off. No tasks were split, added, reordered, or otherwise checked off.

Exact check-off in [todo.md](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:24):

```markdown
- [x] 022 Implement the planned Cucumber step support, remove/narrow runner-debt tags as each runner becomes executable, and run `dev check`.
```

ADR conformance:

- ADR 0003 and 0010: the same shared feature executes through Elixir domain/application steps and cucumber-js/Playwright browser steps.
- ADR 0013: browser steps exercise user-visible Phoenix behavior through the established acceptance harness.
- ADR 0015 and 0023: group selection is exercised through the LiveView’s canonical group URLs; browser-local remembered selection is kept in the browser layer.
- The two persistence-only scenarios use `@not-domain`, accurately narrowing runner intent rather than leaving temporary runner debt.