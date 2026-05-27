You are implementing a validated iteration plan for the Memba Phoenix application.

Use the plan text from the preceding Read Iteration Plan stage. The plan path is {{ inputs.plan_path }}.

Follow these rules:

ADR contract (binding architecture constraints):

- Before editing, read every ADR explicitly referenced by the plan.
- Also inspect nearby/current ADRs under `docs/adr/` when the plan touches architecture affected by them.
- Extract the binding decisions and consequences from each relevant accepted ADR.
- Build a short implementation checklist that maps each relevant ADR to the concrete modules, configuration, migrations, tests, and acceptance plumbing needed for this iteration.
- Treat accepted ADRs as constraints, not suggestions. Do not replace ADR-mandated architecture with a simpler local substitute.
- If an ADR-mandated design seems too large, blocked, incompatible with the plan, or incompatible with another accepted ADR, stop and report a blocker rather than silently substituting a different architecture.
- A smaller vertical slice may reduce breadth, but it may not silently violate or replace ADR-mandated architectural decisions for the slice it claims to deliver.

- Implement the full selected iteration in this run. Do not ask whether to implement the whole plan or only part of it; the plan is the approved scope.
- Do not stop after announcing an implementation plan. You must actually edit the repository using tools. If the planned scope is too large to complete, implement the highest-value coherent vertical slice from the approved plan while preserving all ADR-mandated architectural decisions for that slice, and report exactly what remains; do not finish with no domain/test changes.
- Work from the plan top-to-bottom. Deliver the smallest complete version of each in-scope item before moving on. Do not broaden the iteration beyond the plan.
- Read AGENTS.md and any referenced project guidance before editing relevant files.
- Use test-driven development for behaviour changes: write the failing automated test first, then implement the code to make it pass. Use unit tests for isolated logic, integration/projection tests for data/state changes, and the planned Cucumber step definitions for the shared acceptance scenarios.
- Do not mark behaviour as done in your summary unless a relevant automated test exists and passes or you clearly report why it could not be run.
- Use automated tests as the primary feedback loop while implementing: add or update the automated tests called for by the plan, run relevant targeted tests as you work, and do not present the implementation as complete while known tests/checks are failing.
- The workflow will run `dev check` immediately after this stage and loop dev check failures back for fixes. Your job is to get the implementation to the point where the full automated suite can go green before human/model review.
- Never edit acceptance feature files. Treat all `*.feature` files, including files under `acceptance-tests/`, as locked domain acceptance criteria for this implementation run. If a feature file appears wrong, stale, or insufficient, stop and report the issue instead of changing it.
- Add step definitions only where the plan explicitly requires executable plumbing for the locked shared feature files.
- Use Req for HTTP requests; do not introduce HTTPoison, Tesla, or :httpc.
- Follow Phoenix 1.8, HEEx, LiveView, Tailwind, Ecto, and Elixir project rules where relevant.
- Do not commit changes. Fabro will checkpoint the working tree.
- If you hit a real blocker, stop and report it clearly instead of guessing. Real blockers include ambiguous requirements, missing secrets, unavailable external services, incompatible package versions, or missing sandbox/toolchain infrastructure.
- Do not patch repository scripts or application code merely to compensate for a missing sandbox toolchain such as devenv, Elixir, Mix, Node, npm, PostgreSQL, or system packages. Report missing infrastructure as a blocker so the workflow environment can be fixed.

When finished, summarize:

1. What changed.
2. Automated tests added, updated, and run.
3. Any deviations from the plan.
4. Any remaining risks or manual checks.
5. ADR conformance table with columns: ADR, Required decision, Implementation evidence, Tests/evidence, Deviations/blockers.
