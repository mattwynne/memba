Implemented task 025’s lifecycle scenarios at both acceptance layers. The implementation is complete and focused validation passes, but the required full `dev check` remains unverified because it exceeded the sandbox’s hard 600-second command limit while browser scenarios were still progressing successfully.

Selected task:

`- [ ] 025 Implement the iteration-062 custom-group lifecycle scenarios at the domain and browser layers, then run dev check on the exact delivery state.`

Changes made:

- Enabled only iteration 062’s two lifecycle scenarios in [custom_group_lifecycle.feature](/workspace/memba/acceptance-tests/features/custom_group_lifecycle.feature:1), preserving the `@todo-domain` and `@todo-ui` tags for iterations 063 and 064.
- Added domain lifecycle steps in [custom_group_lifecycle_steps.exs](/workspace/memba/web/test/features/step_definitions/custom_group_lifecycle_steps.exs:1), proving:
  - club departure removes Board and Trips memberships;
  - follows in both groups are cleared;
  - read and reply access ends;
  - future conversations and replies produce no Carol delivery records or provider handoffs;
  - rejoining KMC restores Everyone only;
  - custom memberships, follows, and access remain ended.
- Added browser/Playwright plumbing in:
  - [custom_group_lifecycle_steps.js](/workspace/memba/acceptance-tests/features/step_definitions/custom_group_lifecycle_steps.js:1)
  - [custom_group_lifecycle.js](/workspace/memba/acceptance-tests/features/support/custom_group_lifecycle.js:1)
- Browser coverage additionally verifies inaccessible conversation URLs and visible private-group access guidance after rejoining.
- Added scenario-selection and executable-plumbing regressions in:
  - [custom_group_lifecycle_steps_test.exs](/workspace/memba/web/test/features/custom_group_lifecycle_steps_test.exs:1)
  - [domain_cucumber_runner_test.exs](/workspace/memba/web/test/features/domain_cucumber_runner_test.exs:116)
  - [custom_group_lifecycle_step_definitions.test.js](/workspace/memba/acceptance-tests/test/custom_group_lifecycle_step_definitions.test.js:1)
  - [cucumber_config.test.js](/workspace/memba/acceptance-tests/test/cucumber_config.test.js:227)
- Narrowed the custom-group creation “belongs to club” step pattern to club names, preventing it from incorrectly capturing lifecycle statements such as “Carol should belong to Everyone.”

Validation:

- Focused domain tests: 10 tests, 0 failures.
- Browser step dry-run/configuration: 15 tests passed; both scenarios and all 25 steps are uniquely defined.
- Real Playwright lifecycle selection: 2 scenarios, 25 steps passed.
- `dev check --quick`: 1,410 tests, 0 failures.
- Elixir formatting, JavaScript syntax checks, and `git diff --check`: passed.
- Full `dev check`: reached the hard 600-second tool timeout while the browser suite was still running. No final exit status was available, so this is not being reported as a pass. The orphaned acceptance Phoenix process was identified and terminated afterward.

No todo lines were split, added, reordered, or checked off. The exact line remains:

`- [ ] 025 Implement the iteration-062 custom-group lifecycle scenarios at the domain and browser layers, then run dev check on the exact delivery state.`

ADR conformance:

- ADRs 0003 and 0010: the same shared lifecycle feature executes at domain and browser layers.
- ADR 0007: lifecycle actions and assertions cross Membership/Messaging only through public APIs; no projector-owned side effects were introduced.
- ADRs 0013 and 0015: Playwright exercises actual member-facing LiveView routes, inaccessible conversation links, and access-guidance rendering.
- ADR 0024: club departure and reactivation use the Club-owned public membership lifecycle, preserving the established consistency boundary.