1. **Selected todo line**
   - `011 Verify the Elixir/domain acceptance path used by dev check still runs every shared scenario regardless of @todo-web tags.`

2. **Changes made**
   - Added Elixir Cucumber homepage step definitions:
     - `web/test/features/step_definitions/homepage_steps.exs`
   - Updated `web/test/features/cucumber_configuration_test.exs` to:
     - execute the shared `homepage.feature` scenario through the Elixir Cucumber runtime;
     - include homepage steps in step-definition discovery checks;
     - assert the Elixir acceptance coverage list matches every scenario found in the shared feature files;
     - assert `@todo-web` scenarios are still included in the Elixir acceptance path;
     - assert Elixir Cucumber config has no `:tags` filter, so the browser `not @todo-web` filter does not leak into the domain/Elixir runner.
   - Checked off todo item `011`.

3. **Focused validation**
   - `cd web && mix format --check-formatted test/features/cucumber_configuration_test.exs test/features/step_definitions/homepage_steps.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `112 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 011 Verify the Elixir/domain acceptance path used by dev check still runs every shared scenario regardless of @todo-web tags.`
   - To:
     - `- [x] 011 Verify the Elixir/domain acceptance path used by dev check still runs every shared scenario regardless of @todo-web tags.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0010 respected: shared feature files remain unchanged and continue to be the common acceptance source.
   - ADR 0003 respected: the Elixir acceptance path now explicitly covers the same shared scenarios, including browser-deferred `@todo-web` operator scenarios.
   - ADR 0013 unaffected: no change to the PhoenixTest strategy or LiveView test approach.