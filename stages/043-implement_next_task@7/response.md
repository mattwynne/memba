Blocked on the selected task.

1. **Selected todo line**
   - `- [ ] 007 Remove @todo-web tags from operator scenarios once they are browser-backed.`

2. **Why I stopped**
   - The only `@todo-web` tag for the operator scenarios is in:
     - `acceptance-tests/features/operator_email_deliverability.feature`
   - Completing task 007 requires editing that `.feature` file to remove the tag.
   - The binding rules explicitly say:
     - “Never edit acceptance feature files (`*.feature`, including files under `acceptance-tests/`).”
     - “If a feature file appears wrong, stale, or insufficient, stop and report the issue.”

3. **Repository state**
   - I inspected the plan, todo, relevant ADRs, Cucumber config, and recent checkpoint history.
   - I did not modify any files.
   - Working tree had only the pre-existing untracked `.fabro/tmp/`.

4. **Todo check-off**
   - No todo line was checked off because the selected task could not be completed without violating the feature-file editing rule.

5. **ADR conformance**
   - ADR 0010 confirms these feature files are shared behavioural specifications under `acceptance-tests/features/**/*.feature`, reinforcing that the blocked file is exactly the shared acceptance feature file covered by the no-edit rule.