Blocked on task 009; I did **not** make changes or check it off.

1. **Selected todo line**
   - `009 Verify that operator_email_deliverability.feature is excluded only from the browser run and remains covered by the domain runner.`

2. **What I found**
   - `acceptance-tests/cucumber.js` has:
     - `tags: "not @todo-web"`
   - But `acceptance-tests/features/operator_email_deliverability.feature` is currently **not tagged** with `@todo-web`.
   - Because it is untagged, the browser Cucumber default run still selects it.

3. **Validation commands run**
   - `cd acceptance-tests && npm test -- --dry-run --format summary`
     - Exit code: `0`
     - Result: dry-run selected **11 scenarios**, including the 3 operator scenarios.
     - The operator scenarios appeared as undefined browser scenarios, confirming they are **not excluded**.
   - `cd web && mix test test/features/cucumber_configuration_test.exs`
     - Failed before verification due missing local Postgres socket:
       - `/tmp/devenv/postgres/.s.PGSQL.5432: no such file or directory`

4. **Todo check-off**
   - None. I did **not** change:
     - `- [ ] 009 ...`
   - The task is not complete.

5. **Todo splits/additions/reordering**
   - None.

6. **ADR / rule conformance**
   - ADR 0003 and ADR 0010 require shared feature files to remain the common acceptance source across domain and browser layers.
   - The plan expects the operator scenarios to be excluded from the browser run by `@todo-web`.
   - However, the binding rule says: **“Never edit acceptance feature files (`*.feature`). If a feature file appears wrong, stale, or insufficient, stop and report the issue.”**
   - Since satisfying task 009 appears to require adding `@todo-web` to `operator_email_deliverability.feature`, I stopped rather than editing the feature file or silently replacing the tag-based partition with a weaker path-based exclusion.