Implemented task 001 and left the exact staged state passing the full quality gate.

1. Selected todo

   `001 Implement the existing iteration-059 Gherkin steps and confirm unfinished steps remain excluded until executable. Keep the later-invitee ordinary example as regression coverage.`

2. Changes made

   - Added domain Cucumber plumbing for empty clubs, concurrent invitation acceptance, Admin-count assertions, ordinary-member identification, whole-member removal, removal errors, and active-member assertions in [membership_administration_steps.exs](/workspace/memba/web/test/features/step_definitions/membership_administration_steps.exs).
   - Added corresponding browser-backed steps and Playwright support for the four UI-relevant scenarios in [membership_administration_steps.js](/workspace/memba/acceptance-tests/features/step_definitions/membership_administration_steps.js) and [membership_administration.js](/workspace/memba/acceptance-tests/features/support/membership_administration.js).
   - Added tests proving every iteration-059 step has exactly one appropriate definition, unfinished scenarios remain excluded by runner-debt tags, and the existing later-invitee ordinary-member scenario remains selected.
   - Preserved all `@todo-domain`, `@todo-ui`, and `@not-ui` tags. No acceptance feature files or application behavior were changed.

3. Validation

   - Focused Elixir configuration/step tests: 10 tests, 0 failures.
   - Full domain Cucumber regression: 115 tests, 0 failures.
   - Targeted “Robin invites Dana” domain regression: 1 test passed, 109 excluded.
   - Browser configuration and dry-run plumbing tests: 10 tests, 0 failures; all four browser-backed iteration-059 scenarios had unambiguous definitions.
   - Elixir formatting and `git diff --check`: passed.
   - Full `PATH="$PWD/bin:$PATH" dev check`: passed on the exact staged state, including ExUnit and browser acceptance.

4. Todo check-off

   Changed only:

   `- [x] 001 Implement the existing iteration-059 Gherkin steps and confirm unfinished steps remain excluded until executable. Keep the later-invitee ordinary example as regression coverage.`

5. Todo changes

   No tasks were split, added, removed, or reordered.

6. ADR conformance

   - ADR 0003: the shared scenarios now have domain and browser plumbing where each execution layer is meaningful.
   - ADR 0010: domain definitions remain under `web/test/features/step_definitions` and execute the shared feature vocabulary.
   - ADR 0013: browser-backed removal steps use Playwright against the Staff UI rather than bypassing the web application.
   - The domain-only concurrent scenario remains `@not-ui`, preserving the plan’s explicit runner boundary.