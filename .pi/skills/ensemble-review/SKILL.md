---
name: ensemble-review
description: Run a read-only role-based review, independently where delegation is available, of a behaviour map, technical scope, Gherkin, domain model, technical design, ADR, or complete iteration plan.
---

# Ensemble Review

Use this skill only when a parent planning session delegates a specific artifact and review mode. The parent remains responsible for the planning conversation and all decisions with Matt.

## Contract

- Review only; do not edit repository files or the supplied artifact.
- Preserve the product goal while looking for unnecessary rules, missing examples, incoherent modelling, and avoidable scope.
- Raise questions, alternatives, disagreements, and evidence. Do not decide product policy or architecture for Matt.
- Do not turn a reviewer suggestion into accepted scope. Return findings to the parent, which discusses consequential choices with Matt.
- Prefer three independent reviewers when the available harness supports child threads or subagents. In BB, use BB child threads. If independent delegation is unavailable, perform the roles sequentially and say that the result is not independent ensemble evidence.

## Inputs

The parent must provide:

- mode: `example-map`, `technical-scope`, `gherkin`, `domain-model`, `technical-design`, `adr`, or `final-plan`;
- the artifact or exact paths to inspect;
- the intended product outcome and known scope boundaries;
- unresolved questions already identified.

## Review roles

Run these roles independently and in parallel where possible:

1. **Simplicity and scope challenger** — find assumptions that can be removed, weaker adequate rules, independent slices, and work that can be deferred without losing the intended outcome.
2. **Counterexample challenger** — find missing actors, states, transitions, timings, failures, retries, and examples that contradict or leave the model ambiguous.
3. **Coherence challenger** — check vocabulary, traceability and internal consistency. In Gherkin mode, check fidelity to the agreed map. In domain-model mode, focus on concepts, invariants, commands, events, lifecycle, responsibility and context boundaries. In ADR mode, check fidelity to the agreed model, alternatives and consequences. In final-plan mode, check that features, design, domain model, ADRs, scope and validation agree.

Give every reviewer the same source context plus its role. Instruct it not to edit files and to distinguish observed gaps from optional ideas.

## Mode focus

### Example map

Challenge the value and necessity of important rules, not only the completeness of examples within them. Look for conflated preference, eligibility, timing, side effect and failure policies. Treat questions and deferred stories as successful outputs.

### Technical scope

Challenge whether the iteration names one useful engineering capability, preserves observable behaviour, has concrete proof, and defers adjacent cleanup. Expose hidden product changes instead of treating them as refactoring.

### Gherkin

Check that each scenario expresses an agreed rule in stakeholder language, covers the important examples and does not add or lose policy during formulation. Route product questions back to example mapping rather than answering them in scenario prose.

### Domain model

Check that the model implements only the agreed behaviour or technical capability and preserves the stated non-regression contract. Identify accidental complexity, missing invariants, unclear ownership, commands/events that do not use business language, and consequential choices that need Matt. ADR candidates should emerge from the model; reviewers must not authoritatively select them.

### Technical design

Check that responsibilities, interfaces, data flow, migration/compatibility, operations and proof are sufficient for the agreed technical capability without broadening scope or changing behaviour. Identify accidental complexity and consequential choices requiring Matt.

### ADR

Check that the draft records a consequential choice from the agreed domain model or technical design, represents viable alternatives fairly, states consequences plainly, and does not introduce new product behaviour or architecture that Matt has not considered. Findings return to ADR collaboration before Matt accepts the record.

### Final plan

For a behaviour plan, check traceability and consistency across the agreed examples, UI design, domain model, accepted ADRs, implementation boundaries and validation. For a technical plan, check the agreed capability, behaviour-preservation contract, technical/domain model, accepted ADRs, migration and operational boundaries, implementation scope and proof. Do not introduce new product or architecture decisions at this stage; route discoveries back to the appropriate earlier planning step.

## Synthesis

The parent reads all reports and presents a concise synthesis to Matt:

- agreements;
- disagreements;
- high-confidence holes or contradictions;
- simpler alternatives and possible deferrals;
- questions requiring Matt;
- which earlier planning step to revisit, if any.

Do not average away disagreement or silently choose a reviewer recommendation. Planning proceeds only after Matt resolves consequential findings or explicitly removes/defers them from this iteration.
