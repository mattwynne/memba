You are validating an iteration plan before implementation.

Use the plan text from the preceding `Read Iteration Plan` stage.

Assess acceptance criteria and unresolved business decisions.

Check:

1. Are acceptance criteria concrete, clear, complete, and testable?
2. Do they cover happy paths, important edge cases, permissions, error states, and data/state changes where relevant?
3. Can a reviewer use them to decide objectively whether the work is done?
4. Are user-visible behaviours specified precisely enough?
5. Does the plan classify the iteration as behaviour-facing or technical/engineering?
6. For behaviour-facing or domain-policy changes, does the plan include an `## Acceptance Scenarios / Feature Files` section naming the shared Cucumber feature file(s)/scenarios that will express the rules, or an explicit rationale for why Gherkin would not add useful stakeholder-readable examples? Treat a missing or empty BDD decision as a readiness gap, even when lower-level tests are listed.
7. Are any product, policy, copy, workflow, or domain decisions still unresolved?
8. If the plan expects edits to shared acceptance `.feature` files, does it include a `## Allowed acceptance feature changes` section naming each exact file, the allowed kind of change, the reason, and how coverage is preserved or intentionally changed? Feature files are locked unless this explicit permission exists.

Return a concise Markdown report with:

- Verdict: PASS, WARN, or FAIL
- Strong criteria: criteria that are already objective and useful
- Weak or missing criteria: exact improvements needed
- BDD scenario decision: feature files/scenarios named, explicit no-Gherkin rationale, or missing
- Missing scenarios: behaviours or edge cases not covered
- Open business decisions: decisions that must be made before implementation
- Suggested acceptance criteria: concrete criteria to add or rewrite
