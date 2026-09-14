Revised task 024 to close the browser false-positive identified by independent review.

Selected task:

`- [ ] 024 Implement the iteration-062 custom-group conversation scenarios at the domain and browser layers.`

Changes made:

- Unauthorized email replies now await the authoritative inbound processing result in [custom_group_conversations.js](/workspace/memba/acceptance-tests/features/support/custom_group_conversations.js:255).
- The browser fixture asserts the reply was rejected specifically with `not_current_member`, produced no message, and left the complete Board conversation ID set unchanged.
- Exported the existing inbound-result synchronization helper from [member_message.js](/workspace/memba/acceptance-tests/features/support/member_message.js:4255).
- Added regression tests in [custom_group_conversation_step_definitions.test.js](/workspace/memba/acceptance-tests/test/custom_group_conversation_step_definitions.test.js:9) proving:
  - an accepted root message cannot masquerade as a rejected reply;
  - even a recorded rejection cannot pass if a separate conversation appeared.
- Followed TDD: the new tests initially failed because the assertion did not exist, then passed after implementation.

Focused validation passed:

- `node --test test/custom_group_conversation_step_definitions.test.js test/cucumber_config.test.js`
  - 16 tests passed; browser plumbing found all 13 scenarios and 125 steps.
- `dev acceptance --name "^Sending Board an email does not let Eve or Dan reply to it$" --format progress`
  - 4 scenarios passed, 36 steps passed, including both unauthorized email-reply examples.
- `dev test test/features/custom_group_conversation_steps_test.exs test/features/domain_cucumber_runner_test.exs --trace`
  - 20 tests passed; all 13 expanded domain conversation scenarios passed.
- JavaScript syntax checks and `git diff --check` passed.

No todo tasks were split, added, reordered, or checked. Full `dev check` remains explicitly owned by task 025.

The exact line remains unchanged and ready for independent review:

`- [ ] 024 Implement the iteration-062 custom-group conversation scenarios at the domain and browser layers.`

ADR conformance remains intact: ADRs 0003 and 0010 are satisfied through the shared domain/browser Cucumber scenarios; ADR 0007 is respected by using public Membership/Messaging APIs; ADR 0022 is respected by awaiting the authoritative projected inbound result before making negative assertions.