Implemented task 017 and left it unchecked for independent review.

1. Selected task

`- [ ] 017 Extend group queries/routing only where the existing generic paths need it.`

2. Changes made

Expanded the successful-creation integration test in [new_test.exs](/workspace/memba/web/test/memba_web/live/member_group_live/new_test.exs:303) to prove a newly created custom group works through the existing generic group infrastructure:

- The public active-groups query immediately returns Board with its creator, member count, and generated address.
- The public group lookup returns Board as a structurally custom group with `group_key: nil`.
- Creation navigates to the exact opaque-ID `/groups/:group_id/members` route.
- The generic group rail selects Board and links to its canonical conversation route.
- The generic header shows Board’s private-group metadata, member count, and email address.
- Conversations and Members tabs retain the created group ID.
- The ordinary Members list contains Robin as the sole creator member.
- The single-member promotional panel remains absent.

No production query or route changes were needed: the generic APIs and opaque-ID routes from iteration 058 already handle groups created through the new command.

3. Focused validation

- `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_group_live/new_test.exs`
  - 9 tests, 0 failures.
- `PATH="$PWD/bin:$PATH" dev acceptance --name "^A future named group is presented without a bespoke screen$" --format progress`
  - Browser harness: 1 scenario, 6 steps, all passing.
- `mix format --check-formatted test/memba_web/live/member_group_live/new_test.exs`
  - Passed.
- `git diff --check`
  - Passed.

4. Todo state

The selected line remains unchanged and unchecked in [todo.md](/workspace/memba/docs/iterations/062-create-custom-groups/todo.md:19):

`- [ ] 017 Extend group queries/routing only where the existing generic paths need it.`

5. Todo changes

None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

- ADR 0013: the creation-to-generic-route contract is covered with user-facing PhoenixTest assertions.
- ADR 0015: the resulting member surface remains the existing LiveView dashboard.
- ADR 0019: navigation remains on the canonical club host.
- ADR 0022: strong creation consistency makes the projected group and creator membership available before navigation.
- ADR 0023: the selected group and Members section are represented by the canonical opaque-ID URL.
- ADR 0024: no write authority moved into routing or queries; the Club aggregate remains the creation consistency boundary.