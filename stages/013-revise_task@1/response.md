Revised task 024 and addressed every independent-review finding. The task remains unchecked for independent acceptance.

Selected task:

`- [ ] 024 Implement the iteration-062 custom-group conversation scenarios at the domain and browser layers.`

Changes made:

- In [custom_group_conversation_steps.exs](/workspace/memba/web/test/features/step_definitions/custom_group_conversation_steps.exs:215), unauthorized website replies now assert `{:error, :not_current_member}`, while unauthorized email replies assert a rejected result with `rejection_reason: "not_current_member"`. This prevents unrelated errors or accidental root conversations from satisfying the scenario.
- Carol’s email reply now references Carol’s own outbound delivery Message-ID through recipient-specific lookup at [custom_group_conversation_steps.exs](/workspace/memba/web/test/features/step_definitions/custom_group_conversation_steps.exs:242).
- The domain “stopped following” setup now proves the complete `not following → following → not following` transition and exercises both public follow commands at [custom_group_conversation_steps.exs](/workspace/memba/web/test/features/step_definitions/custom_group_conversation_steps.exs:653).
- The browser layer now performs and asserts the same transition through the UI at [custom_group_conversations.js](/workspace/memba/acceptance-tests/features/support/custom_group_conversations.js:391).

Focused validation:

- `PATH="$PWD/bin:$PATH" dev test test/features/custom_group_conversation_steps_test.exs test/features/domain_cucumber_runner_test.exs --trace`
  - 20 tests, 0 failures.
  - All 13 expanded custom-group conversation scenarios passed at the domain layer.
- Exact-feature browser run:
  - 13 scenarios passed, 125 steps passed.
- Final-state browser rerun of the revised scenario:
  - `dev acceptance --config <exact-feature-config> --name "Carol stops following but can still read Board's agenda"`
  - 1 scenario passed, 10 steps passed.
- `node --test test/custom_group_conversation_step_definitions.test.js test/cucumber_config.test.js`
  - 14 tests passed.
- Elixir formatting, JavaScript syntax, and `git diff --check` passed.

An initial `dev acceptance features/custom_group_conversations.feature` invocation unexpectedly merged the default feature paths and began the entire browser suite. It reached the 600-second tool limit without a final status; I terminated the orphaned Phoenix process and reran with an exact-feature configuration successfully.

No todo lines were split, added, reordered, or checked. Full `dev check` remains part of task 025, as required by the plan. The exact selected line remains unchanged at [todo.md](/workspace/memba/docs/iterations/062-create-custom-groups/todo.md:26):

`- [ ] 024 Implement the iteration-062 custom-group conversation scenarios at the domain and browser layers.`

ADR conformance:

- ADR 0003 and ADR 0010: the same shared Cucumber feature executes at both domain and Playwright/browser layers.
- ADR 0007: the domain steps use the public Membership and Messaging APIs without crossing bounded-context storage boundaries.
- ADR 0022: browser negative assertions continue using the project’s synchronized server-command and delivery-fact infrastructure rather than arbitrary sleeps.