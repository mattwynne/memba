Task 014 is implemented and ready for independent review. I preserved the complete candidate from the prior failed Fabro checkpoint (`bd22d3f`) and found no corrective code changes necessary.

Changes for this task:

- Enabled the iteration-063 rules in [custom_group_membership.feature](/workspace/memba/acceptance-tests/features/custom_group_membership.feature:11) and [custom_group_lifecycle.feature](/workspace/memba/acceptance-tests/features/custom_group_lifecycle.feature:33), while leaving iteration-064 scenarios disabled.
- Added browser and domain step definitions covering:
  - Group-member additions.
  - Outside-admin add-other and self-add.
  - Duplicate idempotency and one welcome.
  - Ordinary outsider denial, including forged LiveView actions.
  - Pending, inactive, and cross-club target rejection.
  - Admin system-group bypass rejection.
  - Whole-history access, welcome links, and explicit re-add behavior.
- Added runner-selection coverage in [cucumber_config.test.js](/workspace/memba/acceptance-tests/test/cucumber_config.test.js:254).
- Added domain scenario execution coverage in [custom_group_membership_steps_test.exs](/workspace/memba/web/test/features/custom_group_membership_steps_test.exs:1) and extended [custom_group_lifecycle_steps_test.exs](/workspace/memba/web/test/features/custom_group_lifecycle_steps_test.exs:22).
- Narrowed existing generic direct-action patterns so the new admission steps resolve without ambiguity.

Focused validation passed:

- `PATH="$PWD/bin:$PATH" dev test test/features/custom_group_membership_steps_test.exs test/features/custom_group_lifecycle_steps_test.exs`
  - 16 tests, 0 failures.
- `node --test --test-name-pattern='iteration 063|default browser Cucumber profile' test/cucumber_config.test.js`
  - 4 tests passed.
- `PATH="$PWD/bin:$PATH" dev acceptance --tags '@iteration-063'`
  - 12 scenarios passed, 96 steps passed.
- `mix format --check-formatted` on all touched Elixir test and step-definition files passed.
- `git diff --check` passed, and the working tree remains clean.

No todo items were split, added, reordered, or checked. Full `dev check` was not run because that remains the separate explicit task 016.

ADR conformance:

- ADR 0003: the same feature scenarios execute at both the domain and Playwright browser layers.
- ADR 0010: domain step definitions remain under `web/test/features/step_definitions` and execute the shared feature files.
- ADR 0013: successful user-facing additions are exercised through the browser UI; forged authorization attempts are sent through the connected LiveView boundary.
- ADR 0024: domain steps call the public `Membership.add_custom_group_member/2` use case and do not mutate projections or system-group membership directly.

The exact selected line remains unchecked in [todo.md](/workspace/memba/docs/iterations/063-add-custom-group-members/todo.md:16):

```markdown
- [ ] 014 Implement the tagged admission/history scenarios, including outside-admin self-add, duplicate additions, inactive/cross-club targets and system-group bypass attempts.
```