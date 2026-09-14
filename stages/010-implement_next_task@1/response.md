Implemented task 024’s domain and browser acceptance coverage, including a fix discovered during focused browser validation.

Selected task:

`- [ ] 024 Implement the iteration-062 custom-group conversation scenarios at the domain and browser layers.`

Changes made:

- Enabled the iteration-062 scenarios in [custom_group_conversations.feature](/workspace/memba/acceptance-tests/features/custom_group_conversations.feature:1) for both acceptance layers.
- Added domain Cucumber steps covering all 13 expanded examples in [custom_group_conversation_steps.exs](/workspace/memba/web/test/features/step_definitions/custom_group_conversation_steps.exs:1).
- Added browser step definitions and Playwright/server-boundary helpers in:
  - [custom_group_conversation_steps.js](/workspace/memba/acceptance-tests/features/step_definitions/custom_group_conversation_steps.js:1)
  - [custom_group_conversations.js](/workspace/memba/acceptance-tests/features/support/custom_group_conversations.js:1)
- Added runner-selection and step-plumbing regressions in:
  - [custom_group_conversation_steps_test.exs](/workspace/memba/web/test/features/custom_group_conversation_steps_test.exs:1)
  - [domain_cucumber_runner_test.exs](/workspace/memba/web/test/features/domain_cucumber_runner_test.exs:89)
  - [custom_group_conversation_step_definitions.test.js](/workspace/memba/acceptance-tests/test/custom_group_conversation_step_definitions.test.js:1)
  - [cucumber_config.test.js](/workspace/memba/acceptance-tests/test/cucumber_config.test.js)
- Fixed the browser reply-email assertion to expect the actual club sender identity, `Kootenay Mountaineering Club via Memba`, rather than `Board via Memba`.
- Formatted the new Elixir step definitions.

Focused validation:

- Initial browser run: 11 of 13 scenarios passed; two reply-delivery scenarios exposed the sender-identity assertion defect.
- Focused rerun of those two scenarios after the fix: 2 scenarios, 23 steps passed.
- Full task-024 browser selection: all 13 expanded conversation scenarios passed.
- `PATH="$PWD/bin:$PATH" dev test test/features/custom_group_conversation_steps_test.exs test/features/domain_cucumber_runner_test.exs`: 20 tests passed.
- `npm run test:config`: 72 tests passed.
- `mix format --check-formatted ...`: passed.
- `git diff --check`: passed.

The full `dev check` was not run because task 025 explicitly owns the final lifecycle scenarios and exact-state full gate.

No todo tasks were split, added, or reordered. The selected line remains unchanged and ready for independent review:

`- [ ] 024 Implement the iteration-062 custom-group conversation scenarios at the domain and browser layers.`

ADR conformance:

- ADR 0003 and ADR 0010: the same shared feature now executes at both domain and browser layers.
- ADR 0007: scenario plumbing uses Membership and Messaging through their existing public boundaries; no production cross-context coupling was added.
- ADR 0004/0005: tests verify existing message aggregate, recipient-resolution, following, and delivery behavior without changing those models.
- ADR 0013/0015: whole-application scenarios exercise the established LiveView application through Cucumber/Playwright and browser-visible outcomes.