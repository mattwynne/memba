Implemented task 024 and left it unchecked for independent review:

`- [ ] 024 Implement the iteration-062 custom-group conversation scenarios at the domain and browser layers.`

Changes made:

- Enabled the shared iteration-062 conversation feature for both acceptance runners by removing its runner-debt tags in [custom_group_conversations.feature](/workspace/memba/acceptance-tests/features/custom_group_conversations.feature:1).
- Added domain Cucumber coverage and scenario-selection tests in [custom_group_conversation_steps.exs](/workspace/memba/web/test/features/step_definitions/custom_group_conversation_steps.exs:1), [custom_group_conversation_steps_test.exs](/workspace/memba/web/test/features/custom_group_conversation_steps_test.exs:1), and [domain_cucumber_runner_test.exs](/workspace/memba/web/test/features/domain_cucumber_runner_test.exs:87).
- Added browser Cucumber step definitions, browser/HTTP fixtures, and executable-plumbing tests in [custom_group_conversation_steps.js](/workspace/memba/acceptance-tests/features/step_definitions/custom_group_conversation_steps.js:1), [custom_group_conversations.js](/workspace/memba/acceptance-tests/features/support/custom_group_conversations.js:1), and [custom_group_conversation_step_definitions.test.js](/workspace/memba/acceptance-tests/test/custom_group_conversation_step_definitions.test.js:1).
- Updated browser-runner inventory assertions in [cucumber_config.test.js](/workspace/memba/acceptance-tests/test/cucumber_config.test.js:197).
- Fixed the recovered candidate’s reply-email assertion to expect the club sender identity, `Kootenay Mountaineering Club via Memba`, rather than the group name.

Focused validation passed:

- Domain Cucumber:
  `PATH="$PWD/bin:$PATH" dev test test/features/custom_group_conversation_steps_test.exs test/features/domain_cucumber_runner_test.exs --trace`
  — 20 tests, 0 failures; all 13 expanded conversation scenarios passed.
- Browser Cucumber using an exact-feature temporary configuration:
  — 13 scenarios passed, 125 steps passed.
- Browser configuration and dry-run plumbing:
  `node --test test/custom_group_conversation_step_definitions.test.js test/cucumber_config.test.js`
  — 14 tests passed.
- Elixir formatting check passed for all touched domain test files.
- `git diff --check` passed.

No todo lines were split, added, reordered, or checked. Task 025 and all later iteration-063/064 tags remain pending. Full `dev check` was intentionally left for task 025 as requested.

This follows ADR 0003 and ADR 0010 by executing the same feature at domain and browser layers, and ADR 0007 by exercising Membership and Messaging through their existing public context APIs with fake/local email delivery boundaries. The selected line remains unchanged at [todo.md](/workspace/memba/docs/iterations/062-create-custom-groups/todo.md:26).