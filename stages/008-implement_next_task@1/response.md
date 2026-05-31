Implemented the next unchecked task.

1. **Selected todo line**
   - `009 Verify that operator_email_deliverability.feature is excluded only from the browser run and remains covered by the domain runner.`

2. **Changes made**
   - Added a focused browser config test in `acceptance-tests/test/cucumber_config.test.js` proving:
     - default browser config still uses `not @todo-web`;
     - browser-included shared features are exactly:
       - `homepage.feature`
       - `member_message_deliverability.feature`
     - browser-excluded shared feature is exactly:
       - `operator_email_deliverability.feature`
   - Strengthened `web/test/features/cucumber_configuration_test.exs` to prove the domain Cucumber configuration still discovers the `@todo-web` operator feature while having no Cucumber tag filter.
   - Did **not** edit any `.feature` files.

3. **Focused validation run**
   - `cd acceptance-tests && node --test test/cucumber_config.test.js`
     - Passed: `3 tests, 0 failures`
   - Domain Cucumber config/runtime test inside dev shell:
     - `mix test test/features/cucumber_configuration_test.exs`
     - Passed: `4 tests, 0 failures`
   - `git diff --check`
     - Passed.
   - Note: an initial direct `bin/mix test ...` attempt hit a devenv Postgres readiness/environment issue, so I reran the focused Elixir test inside a fresh dev shell with an isolated Postgres port; that passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 009 Verify that ...`
   - to:
     - `- [x] 009 Verify that ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0003 and ADR 0010 require shared feature files to remain the behavioural source and be runnable at both domain and browser/application layers.
   - This task keeps shared `.feature` files untouched, verifies the browser-only `@todo-web` partition, and verifies the domain Cucumber runner remains unfiltered and still covers the operator feature.
   - ADR 0013 was not directly affected; no Phoenix web test style changes were made.