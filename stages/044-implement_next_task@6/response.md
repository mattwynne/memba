Implemented the next unchecked iteration task.

1. **Selected todo line**

   `- [ ] 006 Make the @iteration-039 scenarios executable (domain steps first, then browser), removing/narrowing @todo-* as each runner can run them.`

2. **Changes made for task 006 only**

   - Removed temporary `@todo-domain @todo-ui` tags from `acceptance-tests/features/club_message_replies.feature`, leaving `@iteration-039`.
   - Added Elixir/domain Cucumber steps in `web/test/features/step_definitions/messaging_steps.exs` for:
     - reply posting;
     - conversation reply visibility;
     - reply ordering;
     - reply email fan-out excluding author;
     - non-member reply rejection.
   - Added browser Cucumber step definitions in `acceptance-tests/features/step_definitions/member_message_steps.js`.
   - Added browser support helpers in:
     - `acceptance-tests/features/support/member_message.js`
     - `acceptance-tests/features/support/member_harness.js`
   - Checked off only task 006 in `todo.md`.
   - Staged the selected-task diff for Fabro checkpointing; no unstaged diff remains.

3. **Focused validation commands/results**

   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/features/step_definitions/messaging_steps.exs`
     - Passed.
   - `node --check acceptance-tests/features/step_definitions/member_message_steps.js`
     - Passed.
   - `node --check acceptance-tests/features/support/member_message.js`
     - Passed.
   - `node --check acceptance-tests/features/support/member_harness.js`
     - Passed.
   - Direct domain run:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/features/domain_cucumber_acceptance_test.exs`
     - Failed due sandbox Postgres socket mismatch (`PGHOST=/tmp/devenv/postgres` vs runtime socket); no code/test failure.
   - Rerun with explicit reason inside devenv shell:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/features/domain_cucumber_acceptance_test.exs`
     - Passed: `69 tests, 0 failures`.
   - Targeted browser acceptance:
     - `PATH="$PWD/bin:$PATH" dev acceptance --tags @iteration-039`
     - Passed: `4 scenarios (4 passed), 38 steps (38 passed)`.
   - Full quality gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `848 tests, 0 failures`; acceptance `86 scenarios (86 passed), 531 steps (531 passed)`.

4. **Exact todo check-off made**

   Changed:

   `- [ ] 006 Make the @iteration-039 scenarios executable ...`

   to:

   `- [x] 006 Make the @iteration-039 scenarios executable ...`

   Task 007 remains unchecked.

5. **Todo splits/additions/reordering**

   None.

6. **ADR conformance evidence**

   - ADR 0003: kept one shared feature file executing at both domain and browser/application layers.
   - ADR 0010: added Elixir/domain step definitions under `web/test/features/step_definitions/` while preserving shared feature files under `acceptance-tests/features/`.
   - ADR 0013: browser acceptance steps drive member-visible Phoenix/LiveView behavior through the existing Playwright/Cucumber support helpers instead of duplicating separate feature specs.