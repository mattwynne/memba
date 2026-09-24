---
name: ensemble-review
description: Run a read-only role-based review, independently where delegation is available, of an example map, domain model/ADR proposal, or complete iteration plan during collaborative planning.
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

- mode: `example-map`, `domain-model-adr`, or `final-plan`;
- the artifact or exact paths to inspect;
- the intended product outcome and known scope boundaries;
- unresolved questions already identified.

## Review roles

Run these roles independently and in parallel where possible:

1. **Simplicity and scope challenger** — find assumptions that can be removed, weaker adequate rules, independent slices, and work that can be deferred without losing the intended outcome.
2. **Counterexample challenger** — find missing actors, states, transitions, timings, failures, retries, and examples that contradict or leave the model ambiguous.
3. **Coherence challenger** — check vocabulary and internal consistency. In domain-model/ADR mode, focus on concepts, invariants, commands, events, lifecycle, responsibility and context boundaries. In final-plan mode, check that features, design, domain model, ADRs, scope and validation agree.

Give every reviewer the same source context plus its role. Instruct it not to edit files and to distinguish observed gaps from optional ideas.

## Mode focus

### Example map

Challenge the value and necessity of important rules, not only the completeness of examples within them. Look for conflated preference, eligibility, timing, side effect and failure policies. Treat questions and deferred stories as successful outputs.

### Domain model and ADR

Check that the model implements only the agreed behaviour. Identify accidental complexity, missing invariants, unclear ownership, commands/events that do not use business language, and consequential choices that need Matt. ADR candidates should emerge from the model; reviewers must not authoritatively select them.

### Final plan

Check traceability and consistency across the agreed examples, UI design, domain model, accepted ADRs, implementation boundaries and validation. Do not introduce new product or architecture decisions at this stage; route discoveries back to the appropriate earlier planning step.

## Synthesis

The parent reads all reports and presents a concise synthesis to Matt:

- agreements;
- disagreements;
- high-confidence holes or contradictions;
- simpler alternatives and possible deferrals;
- questions requiring Matt;
- which earlier planning step to revisit, if any.

Do not average away disagreement or silently choose a reviewer recommendation. Planning proceeds only after Matt resolves consequential findings or explicitly removes/defers them from this iteration.
