Task 024 is revised and ready for independent review:

`- [ ] 024 Implement the iteration-062 custom-group conversation scenarios at the domain and browser layers.`

The existing candidate continues to execute all 13 expanded custom-group conversation examples at both domain and browser layers. This revision specifically addresses the validator’s findings:

- [custom_group_conversation_steps.exs](/workspace/memba/web/test/features/step_definitions/custom_group_conversation_steps.exs:233) now selects Carol’s recipient-specific outbound Message-ID for her legitimate email reply.
- The domain “has stopped following” step now establishes following, verifies it, performs the unfollow command, and verifies the resulting unfollowed state.
- [custom_group_conversations.js](/workspace/memba/acceptance-tests/features/support/custom_group_conversations.js:391) now exercises the same true-to-false transition through the browser UI and verifies both projected states. The scenario can no longer pass without invoking unfollow.

Focused validation passed:

- `PATH="$PWD/bin:$PATH" dev test test/features/custom_group_conversation_steps_test.exs test/features/domain_cucumber_runner_test.exs`
  - 20 tests, 0 failures.
- `npm run test:config`
  - 72 tests passed.
- Strengthened stop-follow browser scenario:
  - 1 scenario, 10 steps passed.
- Complete task-024 browser selection:
  - 13 scenarios, 125 steps passed.
- `devenv shell -- bin/mix format --check-formatted test/features/step_definitions/custom_group_conversation_steps.exs`
  - Passed.
- `node --check features/support/custom_group_conversations.js`
  - Passed.
- `git diff --check`
  - Passed.

Two preliminary browser invocations were invalid because they ran outside the project’s devenv lifecycle—one also overlapped another environment startup—and lost the acceptance-server RPC connection. The isolated devenv-backed reruns above passed.

No todo items were split, added, reordered, or checked off. Full `dev check` remains part of task 025, as required by the iteration plan.

ADR conformance remains intact: ADRs 0003/0010 are satisfied by executing the shared feature at both acceptance layers; ADRs 0004/0005 preserve recipient-specific message-delivery semantics; ADR 0007 keeps all setup and assertions behind public Membership/Messaging APIs; and ADRs 0013/0015 are reflected in browser-visible LiveView interaction for follow/unfollow behavior.