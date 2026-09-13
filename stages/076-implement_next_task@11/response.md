Implemented task 011 and left it unchecked for independent review.

1. Selected todo line

`- [ ] 011 Arrange an idempotent Membership-to-Messaging policy for clearing affected follows, using public APIs and existing unfollow commands; do not put cross-context side effects in projectors.`

2. Changes made

- Added [clear_removed_group_member_follows.ex](/workspace/memba/web/lib/memba/membership/policies/clear_removed_group_member_follows.ex:1):
  - subscribes to Membership events as a strongly consistent Commanded handler;
  - starts from origin for historical repair;
  - reacts to custom `GroupMemberRemoved` facts;
  - finds affected conversations through Messaging’s public query API;
  - dispatches the existing idempotent `unfollow_conversation/2` operation;
  - waits for the conversation-follow projector and propagates failures so the handler can retry.
- Registered the policy in [application.ex](/workspace/memba/web/lib/memba/application.ex:35).
- Included it in event-sourced reset/restart bookkeeping in [event_sourced_case.ex](/workspace/memba/web/test/support/event_sourced_case.ex:29) and [dev_test_support_controller.ex](/workspace/memba/web/lib/memba_web/controllers/dev_test_support_controller.ex:31).
- Added [clear_removed_group_member_follows_policy_test.exs](/workspace/memba/web/test/memba/membership/clear_removed_group_member_follows_policy_test.exs:1), proving:
  - origin replay and strong-consistency configuration;
  - club departure clears the departing member’s custom-group conversation follow;
  - repeated handling emits only one `ConversationUnfollowed` fact.
- No projectors or acceptance feature files were changed.

3. Validation

- Initial TDD run: 3 tests failed before the policy existed.
- Focused policy test: 3 tests, 0 failures.
- Combined policy, supervision, and follow regression suite: 16 tests, 0 failures.
- Reset-controller regression plus policy test: 9 tests, 0 failures.
- `dev check --quick`: 1,318 tests, 0 failures.
- Formatter check for all touched Elixir files: passed.
- `git diff --check`: passed.

4. Todo state

Still unchecked and ready for independent validation:

`- [ ] 011 Arrange an idempotent Membership-to-Messaging policy for clearing affected follows, using public APIs and existing unfollow commands; do not put cross-context side effects in projectors.`

5. Todo changes

None. No tasks were split, added, removed, reordered, or checked.

6. ADR conformance

- ADR 0002: follow changes remain commands and event-sourced facts; retries are handled by aggregate idempotency.
- ADR 0007: the cross-context policy uses the public `Memba.Messaging` API and does not access Messaging projections directly.
- ADR 0009: no side effects were added to Ecto projectors.
- ADR 0024: Membership’s Club lifecycle remains the source of the `GroupMemberRemoved` fact; the policy only coordinates its downstream Messaging consequence.