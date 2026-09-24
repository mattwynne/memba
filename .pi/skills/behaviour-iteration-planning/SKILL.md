---
name: behaviour-iteration-planning
description: Plan a behaviour-changing iteration through adversarial example mapping, Gherkin, collaborative domain modelling, Matt-approved ADRs, plan assembly, publication, and validation.
---

# Behaviour-Changing Iteration Planning

## Overview

Starting from the intake supplied by `iteration-planning`, turn an intended behaviour change into a published, validated implementation plan. Challenge and agree behaviour before modelling it; agree the model before recording consequential ADRs.

<HARD-GATE>
Do NOT implement the iteration directly in the local checkout. Do NOT edit application code, migrations, step definitions, or UI. Planning may edit only iteration-planning artifacts in that iteration's `docs/iterations/` folder, acceptance feature files/scenarios that are part of planning, `docs/problem-domain-terms.md` for vocabulary changes Matt explicitly agrees, and ADRs plus `docs/adr/README.md` that record architecture decisions Matt explicitly made during the modelling session. It may also maintain the live `planning-progress` report in session/thread storage outside the repository. Feature files and the agreed ADRs are seeds for implementation; step definitions and executable test plumbing are implementation. Never create or accept a consequential ADR autonomously. This skill's terminal state is a committed, pushed and validated behaviour plan; a question returned to Matt; or a clear planning, publication or validation blocker. Fabro launch belongs to `iteration-delivery`.
</HARD-GATE>

## Checklist

Create a task for each item and complete them in order. Use `planning-progress` to update and present the live HTML map after every item, decision checkpoint, rework loop, blocker, and new artifact.

1. **Open the progress map** — initialize the complete behaviour-planning flow, mark targeted context as current, and link artifacts as they appear.
2. **Explore targeted context** — now that intake has identified the behaviour, inspect only the relevant existing behaviour, code, plans, accepted ADRs, problem notes and designs.
3. **Clarify intake** — ask Matt one question at a time only where the routed problem, outcome, beneficiary or boundary remains unclear.
4. **Example map and slice** — use `bdd-discovery` to map rules, examples, questions and deferred stories. Aggressively look for holes and unnecessary rules; split or defer scope before choosing architecture.
5. **Review and agree the map** — run `ensemble-review` with the Example-map brief below. Present agreements, disagreements, simpler alternatives and questions to Matt. Revise until Matt agrees the behaviour and deferrals.
6. **Formulate features, names, and UX** — use `bdd-formulation` and `domain-vocabulary` for shared scenarios and problem-domain names; invoke `ux-design` for visible surfaces. Matt explicitly agrees any lexicon addition, replacement, changed meaning, and material UX decision. If `ux-design` returns a blocking environment handoff, stop before drafting, publishing, or validating the plan.
7. **Review and agree features** — run `ensemble-review` with the Formulated-feature brief below. Return policy gaps to discovery, formulation defects to `bdd-formulation`, naming issues to `domain-vocabulary`, and design issues to `ux-design`. Matt agrees the reviewed scenarios, vocabulary, and design coverage before modelling.
8. **Model the domain** — use `domain-modelling` in the current conversation. If modelling exposes an unnecessary or unclear rule, return to example mapping. If commands, events, or invariants reveal a more natural problem-domain noun or verb, return to `bdd-formulation` and `domain-vocabulary`; after Matt's decision, repeat the formulated-feature ensemble and agreement checkpoint before revising the model.
9. **Review and agree the model** — run `ensemble-review` with the Domain-model brief below. Resolve findings through `domain-modelling` and vocabulary findings through the formulation loop, then obtain Matt's agreement.
10. **Resolve architecture decisions** — use `record-architectural-decisions` for consequential choices emerging from the agreed model. That shared skill owns ADR collaboration, its caller-supplied ensemble brief, publication, and Matt's explicit acceptance.
11. **Assemble the plan** — compose the agreed features, vocabulary, design, domain model, ADRs, scope/deferrals and validation without introducing new decisions.
12. **Check consistency** — run `ensemble-review` with the Final-plan brief below. Return substantive issues to the owning skill and repeat that ingredient's review and Matt-agreement checkpoint. No separate plan-approval ceremony is required.
13. **Publish and validate** — write the iteration artifacts and indexes, run targeted planning checks, commit and push, then run `bin/dev fabro validate-plan <plan_path>`. Route substantive findings back through their owning skill and checkpoint.
14. **Return the result** — mark the progress map complete or blocked, then give `iteration-planning` the validated plan path and commit, or the exact question/blocker. Do not launch delivery.

## Caller-Owned Ensemble Briefs

Every brief below also includes:

- **Known questions:** the artifact's current open questions, or `None`.
- **Constraints:** the agreed outcome, boundaries and non-goals; read-only review; no product-policy, architecture, vocabulary or acceptance decisions; Matt is decision owner.

Use the named feedback route in each brief. `ensemble-review` only discovers the diverse panel and synthesizes its reports.

### Example-map brief

- **Subject/artifact:** the current story, rules, examples, questions, and deferred stories.
- **Focus:** (1) value/scope simplification, (2) counterexamples and missing states/timings, (3) coherence of rules, examples, and problem-domain language.
- **Rubric:** Is each retained rule necessary now? What can be weakened, split, or deferred? Which actors, boundaries, reversals, failures, or rule interactions are missing? Do examples actually distinguish the rules?
- **Feedback route:** `bdd-discovery` and Matt.

### Formulated-feature brief

- **Subject/artifact:** agreed map, formulated scenarios, vocabulary record and applicable design references.
- **Focus:** (1) fidelity to agreed policy, (2) concrete counterexamples, temporal boundaries and BRIEF quality, (3) naming/design coherence.
- **Rubric:** Does each scenario express exactly one agreed rule without adding or losing policy? Are examples concrete and stakeholder-readable? Do they expose when decisions become fixed, significant orderings, temporary states, persistence/resumption/expiry, and effects on past versus future work where relevant? Do nouns and verbs match `docs/problem-domain-terms.md` and avoid solution language? Does visible behaviour have design coverage?
- **Feedback route:** policy gaps to `bdd-discovery`; scenario defects to `bdd-formulation`; naming proposals to `domain-vocabulary`; design gaps to `ux-design`; decisions to Matt.

### Domain-model brief

- **Subject/artifact:** agreed scenarios/vocabulary, draft domain model, current constraints and deferrals.
- **Focus:** (1) simplicity and accidental complexity, (2) invariants/lifecycle/temporal counterexamples, (3) language, ownership and traceability.
- **Rubric:** Does the model implement only agreed behaviour? Are lifecycle, commands, events, invariants, authorization and responsibility boundaries coherent? Does it reuse canonical problem-domain language while separating solution terms? Which consequential choices need Matt and perhaps an ADR?
- **Feedback route:** `domain-modelling`; naming conflicts through `bdd-formulation` plus `domain-vocabulary`; policy issues through `bdd-discovery`; decisions to Matt.

### Final-plan brief

- **Subject/artifact:** all agreed ingredients and assembled plan.
- **Focus:** (1) scope/implementation boundary consistency, (2) missing validation and failure evidence, (3) end-to-end traceability and vocabulary coherence.
- **Rubric:** Does the plan compose the agreed map, scenarios, vocabulary, design, model, accepted ADRs, implementation boundaries and validation without a new decision or contradiction? Can implementation proceed without inventing policy, names, or consequential architecture?
- **Feedback route:** the specialist owning each affected ingredient; repeat that ingredient's ensemble and Matt checkpoint.

## Process Flow

```dot
digraph behaviour_iteration_planning {
  rankdir=TB;
  node [shape=box, style="rounded"];

  intake [label="Routed behaviour-change intake"];
  progress [label="planning-progress\nlive HTML map"];
  context [label="Targeted context exploration"];
  map [label="bdd-discovery\nexample map · slice · defer"];
  map_review [label="ensemble-review\ncaller-owned map brief"];
  behaviour [shape=diamond, label="Matt agrees behaviour?"];
  formulate [label="bdd-formulation + domain-vocabulary + ux-design"];
  vocabulary [shape=diamond, label="Matt agrees vocabulary changes?"];
  gherkin_review [label="ensemble-review\ncaller-owned feature brief"];
  features [shape=diamond, label="Matt agrees features?"];
  model [label="domain-modelling"];
  model_review [label="ensemble-review\ncaller-owned model brief"];
  model_agreed [shape=diamond, label="Matt agrees model?"];
  adr [label="record-architectural-decisions\ncollaborate + review"];
  adr_accept [shape=diamond, label="Matt accepts ADRs?"];
  assemble [label="Assemble plan from agreed ingredients"];
  final_review [label="ensemble-review\ncaller-owned final-plan brief"];
  consistent [shape=diamond, label="Plan consistent?"];
  publish [label="Publish and validate plan"];
  validated [shape=diamond, label="Validation ready?"];
  validation_route [shape=diamond, label="Which ingredient owns\nthe validation finding?"];
  result [shape=doublecircle, label="Return validated plan\nto iteration-planning"];
  blocker [shape=doublecircle, label="Return question or blocker"];

  intake -> progress -> context -> map -> map_review -> behaviour;
  behaviour -> map [label="no", style=dashed];
  behaviour -> formulate [label="yes"];
  formulate -> vocabulary;
  vocabulary -> formulate [label="no", style=dashed];
  vocabulary -> gherkin_review [label="yes / none proposed"];
  gherkin_review -> features;
  features -> formulate [label="no", style=dashed];
  features -> model [label="yes"];
  model -> formulate [label="better problem-domain term", style=dashed];
  model -> model_review [label="language coherent"];
  model_review -> model_agreed;
  model_agreed -> model [label="no", style=dashed];
  model_agreed -> adr [label="yes / if required"];
  adr -> adr_accept;
  adr_accept -> adr [label="no", style=dashed];
  adr_accept -> assemble [label="yes"];
  model_agreed -> assemble [label="yes / no ADR", style=dotted];
  assemble -> final_review -> consistent;
  consistent -> publish [label="yes"];
  consistent -> map [label="behaviour issue", style=dashed];
  consistent -> formulate [label="feature issue", style=dashed];
  consistent -> model [label="model issue", style=dashed];
  consistent -> adr [label="ADR issue", style=dashed];
  publish -> validated;
  validated -> result [label="yes"];
  validated -> blocker [label="blocked"];
  validated -> validation_route [label="substantive finding"];
  validation_route -> map [label="behaviour/scope", style=dashed];
  validation_route -> formulate [label="scenario/vocabulary/UX", style=dashed];
  validation_route -> model [label="model", style=dashed];
  validation_route -> adr [label="architecture decision", style=dashed];
}
```

A changed ingredient must repeat its ensemble and Matt-agreement/acceptance checkpoint.

## BDD Scenario Heuristics

Do not treat BDD as optional polish for behaviour-facing work. Make an explicit BDD decision during planning and write it into `## Acceptance Scenarios / Feature Files`.

Default to drafting or updating Gherkin when any of these are true:

- The iteration changes who can do what, when, or under which policy.
- The behaviour is visible to a customer, member, club operator, staff user, or support/operator persona.
- The plan contains business rules, permissions, lifecycle states, eligibility, routing, notification, pricing, privacy, or safety/trust implications.
- The examples would help Matt spot a misunderstanding before implementation.
- The behaviour needs edge-case examples to explain it clearly, such as unknown/expired/duplicate/unauthorised/error cases.
- Future agents or collaborators would benefit from stakeholder-readable executable documentation.

Use `bdd-discovery` before writing Gherkin when the rules, examples, vocabulary, questions, or slice boundaries are not yet obvious. Signals include multiple actors, several rules in one idea, policy exceptions, uncertainty about expected outcomes, or examples that reveal the iteration may need slicing.

Use `bdd-formulation` when drafting or reviewing Gherkin scenarios so feature files remain domain modelling artifacts rather than test scripts.

When deciding not to add or change feature files for a behaviour-facing iteration, write a short rationale in the plan. A good rationale names the existing scenario that already covers the rule, or explains why the behaviour is too internal/obvious for a useful stakeholder example. `Covered by ExUnit/controller tests` is not sufficient by itself for business-facing behaviour.

## Interview Guidance

Ask only one question per message. Prefer multiple choice when it lowers effort, but use open questions when needed. When asking a multiple-choice question, use the `question` tool rather than writing A/B/C/D options in prose. Use normal chat only for open-ended questions or when the tool cannot express the choice clearly.

Before or during early brainstorming, inspect `docs/problems/README.md` and relevant `docs/problems/*.md` files. Use them to ask whether the iteration should resolve, partially address, or deliberately defer any captured problems. If Matt's idea resembles an unresolved or partially addressed problem, name that problem explicitly and ask how tightly the iteration should target it.

Cover these topics:

- **Goal** — what should be true after the iteration that is not true now?
- **Related problems** — which `docs/problems` notes does this iteration address, partially address, depend on, or leave unresolved?
- **Beneficiary** — who benefits: club admin, member, developer/operator, or another actor?
- **Smallest useful slice** — is this one rule or one piece of engineering, or several? (see Sizing and Slicing)
- **Scope boundaries** — what is explicitly out of scope?
- **Acceptance criteria** — concrete behaviours, examples, edge cases, permissions, and error states.
- **Business decisions** — domain, policy, copy, workflow, pricing, privacy, or support questions.
- **Technical shape** — likely modules, data, events/commands, integrations, UI, background work, and migration concerns.
- **UX design** — does this iteration alter a visible surface, state, interaction, content journey, or email? If so, invoke `ux-design` and use its design record.
- **Validation** — automated tests, acceptance tests, shared Cucumber scenarios, manual demo, stakeholder review, or operational checks.

Intake clarification stops when there is enough shared context to begin example mapping. Discovery and modelling continue until the plan can be written without an implementor inventing material product, domain-model or architecture decisions.

## Sizing and Slicing

An iteration should be **one shippable slice**: either one behaviour rule, or
one piece of engineering. Before drafting the plan, check the size and split
if needed.

- **Find the seams.** For behaviour-facing work, each Rule from example
  mapping is normally its own shippable slice, with that rule's examples as
  the slice's acceptance scenarios.
- **Foundation first.** When behaviour needs architecture that does not exist
  yet (e.g. an event store before the first message can be sent), make that
  enabling architecture its own earlier technical iteration.
- **Split when it is more than one slice.** If the work spans several rules or
  bundles new architecture with behaviour, write it as several iteration
  plans, each independently shippable, rather than one big plan. A good slice
  leaves the build green with strictly more scenarios passing — while preserving a safe, coherent product state.

If you split a plan, replace it with the child plans (no parent/epic doc) and
number them sequentially before any of them is implemented.

Worked example: the original "member message deliverability" plan bundled the
whole event-sourced stack, two contexts, and all delivery statuses into 18
tasks, and repeatedly failed to implement. It was split into four shippable
iterations — `001` event-sourced foundation (technical), then `002`
membership, `003` messaging, `004` statuses and views (one rule each). See
`docs/iterations/`.

## Plan Format

Write the plan as Markdown with these sections:

```markdown
# <Iteration title>

Date: YYYY-MM-DD
Status: draft | ready | needs-revision

## Goal

## Background / Context

## Related Problems

List relevant `docs/problems` notes. For each one, state whether this iteration is expected to resolve it, partially address it, depend on it, or leave it unresolved. If none are relevant, write `None known.`

## Scope

### In scope

### Out of scope

## Iteration Type

Behaviour-facing. Identify the user-observable rule or policy changed.

## Acceptance Scenarios / Feature Files

State the BDD decision: `Required`, `Useful but not required`, or `Not useful for this slice`. For behaviour-facing iterations, name the shared Cucumber feature file(s) and scenarios that will express the business rules, or state why Gherkin would not add useful stakeholder-readable examples for this slice. If implementation is allowed to edit `.feature` files, also include a separate `## Allowed acceptance feature changes` section naming each exact file, the allowed kind of change, the reason, and how coverage is preserved or intentionally changed.

## Designs

Use the `ux-design` output. List each affected surface and state with exact design paths, agreed decisions, slice omissions, accessibility/responsive considerations, and any required handoff or fast-follow. Write `No design needed` with the skill's reason only when nothing visible changes.

## Acceptance Criteria

## Open Business Decisions

## Domain Vocabulary

List canonical terms reused, Matt-agreed additions/changes recorded in `docs/problem-domain-terms.md`, deliberately separate solution-domain terms, and unresolved naming questions.

## Domain Model

Document the agreed concepts and vocabulary, lifecycle/state changes, invariants, commands, events, actors, aggregate/context ownership, responsibility boundaries, important temporal examples, changes from the current model, and deliberately deferred modelling questions.

## Architecture Decisions

Link the accepted ADRs produced or confirmed during planning. State `None required` when the agreed model introduces no consequential architecture decision. Never use this section to defer an ADR decision to implementation.

## Implementation Plan

## Open Technical Decisions

## New Capability

What we expect to be able to do once this is done that we could not do before.

## Validation Plan

How we will validate that we have been successful.

## Risks / Follow-ups
```

Keep plans focused. If a section has no open decisions, write `None known.` rather than omitting it.

## Writing the Plan

- Create `docs/iterations/` if it does not exist.
- Maintain `docs/iterations/README.md` as the iteration index.
- Read `docs/problems/README.md` if it exists, plus any relevant `docs/problems/*.md` notes. If the directory exists but no README exists, inspect the problem files directly.
- Include a `## Related Problems` section in the plan. Link each relevant problem note and say whether the iteration should resolve it, partially address it, depend on it, or intentionally leave it unresolved. If there are no relevant captured problems, write `None known.`
- Include `## Domain Vocabulary`, `## Domain Model`, and `## Architecture Decisions`. Vocabulary changes must be agreed by Matt and recorded in `docs/problem-domain-terms.md`; the model records decisions agreed during modelling and is not a placeholder for the implementor. Link every required accepted ADR, and do not mark a consequential architecture decision resolved unless Matt participated in and accepted it through `record-architectural-decisions`.
- Create one folder per iteration using the next sequential zero-padded iteration number and a lowercase hyphenated topic slug.
- Determine the next number by inspecting existing `docs/iterations/NNN-*` folders; start at `001` if none exist.
- Save the plan as `plan.md` inside that folder.
- Put supporting planning artifacts for the same iteration in the same folder, such as `manual-demo-script.md` or `validation-notes.md`.
- Classify the iteration as behaviour-facing and fill in `## Acceptance Scenarios / Feature Files` with a BDD decision of `Required`, `Useful but not required`, or `Not useful for this slice`, plus either the feature file(s)/scenario summaries that express the business rules or an explicit rationale for why Gherkin would not add useful stakeholder-readable examples. Do not rely on low-level ExUnit/controller tests as a substitute for this BDD decision.
- Apply the BDD scenario heuristics above before deciding. If two or more “default to Gherkin” signals apply, draft scenarios unless Matt explicitly decides otherwise.
- Draft or update shared Cucumber feature files/scenarios when they clarify the iteration's domain behaviour. Use `bdd-discovery` first if the rules/examples are unclear, and `bdd-formulation` when writing or reviewing the Gherkin. Keep scenarios abstract from test infrastructure: no CSS selectors, route names, button-click choreography, database setup, or adapter configuration.
- Include the `## Designs` record returned by `ux-design`. Do not duplicate or weaken that skill's source, environment, handoff, review, or Matt-decision boundaries.
- Tag every scenario created or changed during planning with the iteration tag `@iteration-NNN`, where `NNN` is the zero-padded iteration number. If every scenario in a new or changed feature belongs to that iteration, a feature-level `@iteration-NNN` tag is acceptable. Do not remove older iteration tags from existing scenarios; multiple iteration tags are allowed and useful when a scenario evolves across iterations.
- Preserve a green mainline while planning. Existing executable scenarios should keep passing. If planning deliberately rewrites or adds scenarios that describe future behaviour and would fail before implementation catches up, tag each affected scenario with the project’s runner-debt tags: `@todo-domain` when domain support is pending, and `@todo-ui` when browser support is pending. If every scenario in a changed feature has the same pending runner support, feature-level tags are acceptable. Prefer scenario-level tags when only part of a feature is unfinished. Do not leave untagged future-facing scenarios that make `dev check` fail.
- When feature files/scenarios are created or changed, show Matt the feature file path, which scenarios are tagged with `@iteration-NNN`, which have `@todo-domain` and/or `@todo-ui`, and a concise summary of the scenarios. Explicitly ask him to review the language/examples before treating the plan as final.
- Before publishing, run `dev check` whenever acceptance feature files changed, as required by project guidance. For docs-only planning with no acceptance changes, use targeted structural checks where useful and do not run `dev check`. If the full check fails because a future-facing scenario is unimplemented, add or narrow the relevant `@todo-domain` and/or `@todo-ui` tags rather than editing step definitions or app code. If the project does not configure those tags to exclude the pending scenario from the relevant runner, stop and report that the planning change would make the build red instead of committing it.
- Do not implement step definitions, fixtures, app code, migrations, UI, or test adapters during planning.
- Add or update the index entry in `docs/iterations/README.md` with the iteration number, title/topic, plan link, date, status, and any acceptance feature files changed.
- Do not update Fabro workflow code or problem-note status files during ordinary iteration planning. The relevant problems belong in the plan's `## Related Problems` section. Only edit `docs/problems/*.md` or `docs/problems/README.md` if Matt explicitly asks for problem-note maintenance as part of the planning task.
- Example: `docs/iterations/001-member-import/plan.md`.
- Commit and push the plan, iteration index, supporting planning artifacts, acceptance feature files, Matt-agreed `docs/problem-domain-terms.md` changes, ADRs explicitly accepted by Matt, and `docs/adr/README.md` before running Fabro validation so the clone-based remote sandbox can see them. Do this only after the acceptance files are either still executable and green, or carry the relevant `@todo-domain` and/or `@todo-ui` tags and are excluded from the planning-time checks. Then run `bin/dev fabro validate-plan <plan_path>`, route feedback through the owning planning step, and return the validated plan.
- Include workflow/skill changes in that commit only when they are needed for planning or validation.
- Do not commit or push unrelated changes or implementation work.

## Validating the Published Plan

After committing and pushing the planning artifacts, run:

```bash
bin/dev fabro validate-plan docs/iterations/NNN-topic/plan.md
```

If validation reports `NOT READY`, return each substantive issue to its owning skill, repeat that ingredient's ensemble and Matt-agreement/acceptance checkpoint, update and publish the affected planning artifacts, and rerun validation. Validation must not invent product or architecture decisions.

When complete, return the plan path, pushed commit, validation result, related problems, changed feature files/tags, accepted ADRs, and any unresolved blocker to `iteration-planning`. Do not run `bin/dev fabro deliver`; `iteration-delivery` owns that boundary.

## Key Principles

- One question at a time.
- Example-map and defer before modelling; agree formulated features and vocabulary before modelling; model before invoking `record-architectural-decisions`; accept ADRs before implementation.
- Compose planning from the `bdd-discovery`, `bdd-formulation`, `domain-vocabulary`, `ux-design`, `domain-modelling`, `record-architectural-decisions`, and `ensemble-review` skills rather than duplicating their specialist procedures.
- Ensemble reviewers challenge and advise; Matt agrees behaviour, formulated features, domain models and ADRs. The assembled plan needs no separate approval ceremony.
- One iteration is one slice: one rule, or one piece of engineering. Split anything bigger.
- Make business decisions explicit.
- Document the agreed domain model systematically rather than leaving commands, events, invariants or ownership for implementation to invent.
- Make technical decisions explicit enough to start.
- Make acceptance criteria testable.
- Make validation observable.
- If a person sees it, invoke `ux-design` and carry its agreed design record into the plan.
- Do not implement or launch delivery in this skill; return the validated plan to `iteration-planning`.
