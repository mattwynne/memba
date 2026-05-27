Fix the ADR coherence violations identified by the preceding ADR Coherence Gate for {{ inputs.plan_path }}.

Use only the gate's repair brief, the plan, the cited ADRs, and current repository state. Stay within the approved iteration scope.

Rules:

- Fix only the ADR violations identified by the ADR gate.
- Do not reinterpret, weaken, or ignore accepted ADRs.
- Do not replace ADR-mandated architecture with simpler local substitutes.
- Add or update automated tests proving the ADR-relevant behaviour, wiring, or structure.
- Never edit acceptance feature files (`*.feature`, including files under `acceptance-tests/`). Treat them as locked acceptance criteria.
- If a fix requires changing feature files, changing ADRs, changing the iteration plan, or making a product/architecture decision, stop and request human input.
- Do not add unrelated cleanup or new product behaviour.
- Do not skip or weaken existing validation.
- Do not commit changes.

When finished, summarize:

1. Each ADR violation from the gate.
2. The concrete code/config/test changes made for each violation.
3. The automated tests added or updated to prove ADR coherence.
4. Any remaining ADR blockers or human questions.
