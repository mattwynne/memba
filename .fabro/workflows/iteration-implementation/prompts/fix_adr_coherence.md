Fix the ADR coherence violations identified by the preceding ADR Coherence Gate for {{ inputs.plan_path }}.

Use only the gate's repair brief, the plan, the cited ADRs, and current repository state. Stay within the approved iteration scope.

Rules:

- Fix only the ADR violations identified by the ADR gate.
- Do not reinterpret, weaken, or ignore accepted ADRs.
- Do not replace ADR-mandated architecture with simpler local substitutes.
- Add or update automated tests proving the ADR-relevant behaviour, wiring, or structure.
- Acceptance feature files (`*.feature`, including files under `acceptance-tests/`) are locked unless the plan has a `## Allowed acceptance feature changes` section naming the exact file and allowed kind of change. If the plan permits a feature edit, make only that explicit edit and preserve/validate the coverage promised by the plan.
- If a fix requires changing feature files beyond explicit plan permission, changing ADRs, changing the iteration plan, or making a product/architecture decision, stop and request human input.
- Do not add unrelated cleanup or new product behaviour.
- Do not skip or weaken existing validation.
- Do not commit changes.
- **Sandbox/runtime boundary**: If the ADR violation or failure appears caused by sandbox/toolchain/runtime incoherence (stale `/env` paths, unwritable caches, missing tools, broken services, stale process-compose state), stop and report a sandbox blocker. Do not patch `bin/dev`, application scripts, product code, dependencies, or tests merely to compensate for sandbox runtime defects.
- **If no changes were needed**: If after reviewing the violations you determine that no code/config/test changes are required, state that explicitly and provide clear justification for why the ADR violations do not require changes.

When finished, summarize:

1. Each ADR violation from the gate.
2. The concrete code/config/test changes made for each violation (or an explicit statement that no changes were needed with justification).
3. Files changed (grouped by violation addressed).
4. The automated tests added or updated to prove ADR coherence.
5. Tests run and their results.
6. Any remaining ADR blockers or human questions.

Include a violation-to-fix mapping showing which files/modules/tests address each ADR violation.
