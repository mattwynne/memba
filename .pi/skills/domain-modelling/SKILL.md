---
name: domain-modelling
description: Collaboratively model agreed behaviour or a technical capability with Matt before implementation, covering concepts, invariants, commands, events, lifecycle, ownership, and responsibility boundaries.
---

# Domain Modelling

Use this skill only after behaviour-facing examples have been formulated and agreed, or after a technical capability and its observable proof have been agreed. The calling specialist planning skill owns sequencing and publication.

## Purpose

Turn agreed behaviour or an agreed technical capability into an explicit domain model with Matt. The output becomes the iteration plan's `## Domain Model` section and may identify consequential decisions that need ADRs.

This is collaborative modelling, not autonomous architecture design and not implementation.

## Inputs

Read:

- the agreed example map or technical capability map;
- formulated feature scenarios and their vocabulary record when applicable;
- `docs/problem-domain-terms.md`, consulted through `domain-vocabulary`;
- relevant current code and clearly separated solution-domain terminology;
- existing accepted ADRs and reference guidance;
- explicit scope deferrals.

Do not reopen agreed product behaviour merely to suit the current implementation. If modelling reveals an unnecessary, contradictory or prohibitively expensive rule, return that evidence to the parent so it can revisit discovery with Matt.

## Session

Work through one focused question at a time with Matt to develop and record a draft model:

1. **Concepts and language** — entities, value concepts, nouns, and verbs the business recognizes; reuse the canonical problem-domain vocabulary and label solution-domain terms separately.
2. **Lifecycle and state** — relevant states and permitted transitions.
3. **Invariants and policies** — what must always be true and when each decision is made.
4. **Commands** — intent, actor, target, authorization and owning boundary.
5. **Events** — immutable business facts and the information they must carry.
6. **Ownership** — aggregate/context responsibility, collaborators, and consistency boundaries.
7. **Temporal examples** — important orderings, retries or concurrency cases that clarify the model.
8. **Change from today** — concepts retained, added, changed or retired.
9. **Deferrals** — modelling concerns explicitly outside this iteration.
10. **ADR candidates** — consequential architecture choices that need a separate decision record.

Use business language before framework language. Commands and events should express the agreed model, not implementation plumbing.

If a command, event, invariant, or lifecycle discussion reveals that a different problem-domain noun or verb is more natural than the formulated wording, do not silently choose either term. Return the concrete evidence to `bdd-formulation` and `domain-vocabulary` for Matt's decision. When he agrees a change, update `docs/problem-domain-terms.md` and the scenarios first, repeat their caller-defined ensemble review and Matt-agreement checkpoint, and only then revise this model. Keep solution-domain names available for technical design without adding them to the problem-domain lexicon.

## Decision boundary

- Matt decides the domain model and consequential responsibility boundaries.
- Do not write or accept an ADR inside this skill. Return ADR candidates to the planning session for drafting, ensemble review and Matt's explicit acceptance.
- Do not edit application code, tests, migrations or implementation workflow files.
- Do not conceal an unresolved choice inside `Open Technical Decisions`; remove it from the iteration or resolve it with Matt before implementation.

## Output

Return a concise proposed `## Domain Model` section containing:

- canonical problem-domain concepts and vocabulary;
- separately labelled solution-domain terms;
- lifecycle/state changes;
- invariants and decision points;
- commands and events;
- actors and authorization;
- context/aggregate ownership and collaborators;
- important temporal examples;
- changes from the existing model;
- explicit deferrals;
- unresolved questions, if any;
- ADR candidates, if any.

The calling planning skill submits this output to `ensemble-review` with an explicit domain-model subject, artifact, focus, rubric, questions, constraints, and feedback route. It discusses findings with Matt, revises through this skill as needed, and only then obtains Matt's agreement on the model.
