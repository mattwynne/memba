Implemented task 022’s domain acceptance slice and left it unchecked for independent review.

1. Selected task

`- [ ] 022 Implement the iteration-062 custom-group creation scenarios at the domain layer.`

2. Changes made

- Activated all 13 domain-intended creation examples by removing only their `@todo-domain` debt tags in [custom_group_creation.feature](/workspace/memba/acceptance-tests/features/custom_group_creation.feature:11). The browser debt and browser-only `@not-domain` scenarios remain unchanged.
- Added domain Cucumber plumbing in [custom_group_creation_steps.exs](/workspace/memba/web/test/features/step_definitions/custom_group_creation_steps.exs:1), covering:
  - admin and ordinary-member fixtures;
  - authorized and unauthorized creation;
  - creator membership;
  - normalized name uniqueness and protected system names;
  - club-scoped names and slugs;
  - concurrent same-name creation;
  - collision suffixes and stored addresses;
  - inbound email routing by stored slug despite a different display name.
- Added focused execution of every activated creation scenario in [custom_group_creation_steps_test.exs](/workspace/memba/web/test/features/custom_group_creation_steps_test.exs:1).
- Added runner-selection coverage proving domain examples run while live-input examples remain browser-only in [domain_cucumber_runner_test.exs](/workspace/memba/web/test/features/domain_cucumber_runner_test.exs:75).

3. Validation

- Focused creation and runner tests:
  - `PATH="$PWD/bin:$PATH" dev test test/features/custom_group_creation_steps_test.exs test/features/domain_cucumber_runner_test.exs`
  - 19 tests, 0 failures.
- Complete domain Cucumber suite:
  - `PATH="$PWD/bin:$PATH" dev test test/features/domain_cucumber_acceptance_test.exs`
  - 137 scenarios, 0 failures.
- Acceptance configuration suite:
  - `npm run test:config`
  - 68 tests, 0 failures.
- Broad non-browser gate:
  - `PATH="$PWD/bin:$PATH" dev check --quick`
  - 1,376 tests, 0 failures.
- Formatting and whitespace checks passed:
  - `mix format --check-formatted ...`
  - `git diff --check`

4. Exact pending line

[The task remains unchecked](/workspace/memba/docs/iterations/062-create-custom-groups/todo.md:24):

`- [ ] 022 Implement the iteration-062 custom-group creation scenarios at the domain layer.`

5. Todo split

The previous task combined three feature suites, two acceptance layers, real-browser caret testing, and the final full gate. It was split into:

- 022: custom-group creation domain scenarios.
- 023: custom-group creation browser scenarios, including typing/caret coverage.
- 024: custom-group conversation scenarios at both layers.
- 025: custom-group lifecycle scenarios at both layers and final full `dev check`.

This preserves every requirement from the original line. The browser-inclusive full gate remains explicitly attached to task 025.

6. ADR conformance

- ADR 0003 and ADR 0010: the existing shared feature file now runs against Elixir domain/application step definitions without duplicating scenarios.
- ADR 0011: scenario operations allocate caller-generated typed identities.
- ADR 0024: user-facing creation goes through `Membership.create_custom_group/2`; the concurrency scenario proves the Club aggregate remains the authoritative consistency boundary.
- ADRs 0021 and 0022: fixture commands use strong consistency and assertions inspect committed projections without timing sleeps.