Fix the plan conformance violations identified by the preceding Plan Conformance Gate for {{ inputs.plan_path }}.

Use only the gate's repair brief, the plan text, and current repository state. Stay within the approved iteration scope.

Rules:

- Fix only the explicit plan-conformance gaps identified by the gate.
- Do not reinterpret explicit requirements as optional or implementation strategy.
- Do not omit, weaken, or substitute plan-mandated architecture, tests, configurations, or deliverables.
- Add or update automated tests proving each plan requirement is satisfied.
- Add code, configuration, migrations, or modules needed to satisfy each explicit plan requirement.
- Never edit acceptance feature files (`*.feature`, including files under `acceptance-tests/`). Treat them as locked acceptance criteria.
- If a fix requires changing feature files, changing the plan, or making a product/architecture decision, stop and request human input.
- If the repair brief is too large, ambiguous, conflicting, or requires a decision beyond the plan scope, stop and request human input.
- Do not add unrelated cleanup or new product behaviour beyond the plan requirements.
- Do not skip or weaken existing validation.
- Do not commit changes.
- **Sandbox/runtime boundary**: If the plan violation or failure appears caused by sandbox/toolchain/runtime incoherence (stale `/env` paths, unwritable caches, missing tools, broken services, stale process-compose state), stop and report a sandbox blocker. Do not patch `bin/dev`, application scripts, product code, dependencies, or tests merely to compensate for sandbox runtime defects.

When finished, summarize:

1. Each plan requirement gap from the gate.
2. The concrete code/config/test/migration changes made for each requirement.
3. The automated tests added or updated to prove plan conformance.
4. Tests run and their results.
5. Any remaining plan gaps or human questions.

Include a requirement-to-fix mapping showing which files/modules/tests address each explicit plan requirement.
