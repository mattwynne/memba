---
name: technical-iteration-planning
description: Plan a technical or refactoring iteration that preserves observable behaviour, with explicit capability, constraints, architecture decisions, proof, publication, and validation.
---

# Technical / Refactoring Iteration Planning

Starting from the intake supplied by `iteration-planning`, produce a focused, published and validated engineering plan without importing the behaviour-planning ceremony.

<HARD-GATE>
Do not implement the iteration or launch delivery. Do not edit application code, tests, migrations, dependencies or workflow machinery while planning. Planning may edit iteration artifacts and ADRs plus `docs/adr/README.md` only when Matt explicitly accepts the decisions. Return the validated plan to `iteration-planning`; `iteration-delivery` owns Fabro launch.
</HARD-GATE>

## Flow

1. **Explore targeted context** — after routing has identified the engineering problem, inspect relevant code, tests, tooling, ADRs, problems and operational evidence.
2. **Clarify the capability** — with Matt, define the current limitation, desired engineering capability, behaviour that must remain unchanged, beneficiaries, constraints and observable proof.
3. **Slice and defer** — map technical prerequisites, risks, questions and independently useful capabilities. Keep one engineering capability per iteration; defer adjacent cleanup.
4. **Review and agree scope** — run `ensemble-review` in `technical-scope` mode. Present simpler approaches, hidden behaviour changes, missing evidence and deferrals to Matt. Revise until he agrees the capability and boundaries.
5. **Model architecture only where needed** — if the work changes domain concepts, commands, events, invariants or ownership, use `domain-modelling`; otherwise document affected responsibilities, interfaces, data flow and operational boundaries directly. Do not invent product behaviour.
6. **Review and agree architecture** — run `ensemble-review` in `domain-model` mode for domain changes or `technical-design` mode otherwise. Resolve findings with Matt.
7. **Draft, review and accept ADRs** — for consequential choices, draft ADRs from the agreed architecture, run `ensemble-review` in `adr` mode, revise with Matt, update `docs/adr/README.md`, and obtain explicit acceptance.
8. **Assemble the plan** — compose the agreed capability, non-regression contract, technical design, ADRs, implementation boundaries and validation without introducing new decisions.
9. **Check consistency** — run `ensemble-review` in `final-plan` mode. Return substantive findings to the owning step and repeat its review/Matt-agreement checkpoint.
10. **Publish and validate** — update the iteration index, run appropriate planning checks, commit and push, then run `bin/dev fabro validate-plan <plan_path>`. Route substantive findings back through the owning step.
11. **Return the result** — give `iteration-planning` the validated plan path and commit, or the exact question/blocker. Do not launch delivery.

## Process Flow

```dot
digraph technical_iteration_planning {
  rankdir=TB;
  node [shape=box, style="rounded"];

  intake [label="Routed technical/refactoring intake"];
  context [label="Targeted context and evidence"];
  capability [label="Define capability + non-regression contract"];
  scope_review [label="ensemble-review\ntechnical-scope mode"];
  scope [shape=diamond, label="Matt agrees scope?"];
  design [label="Model technical/domain design as needed"];
  design_review [label="ensemble-review\ntechnical-design or domain-model"];
  design_agreed [shape=diamond, label="Matt agrees design?"];
  adr [label="Draft required ADRs"];
  adr_review [label="ensemble-review\nadr mode"];
  adr_accept [shape=diamond, label="Matt accepts ADRs?"];
  assemble [label="Assemble plan from agreed ingredients"];
  final_review [label="ensemble-review\nfinal-plan consistency"];
  consistent [shape=diamond, label="Plan consistent?"];
  publish [label="Publish and validate plan"];
  validated [shape=diamond, label="Validation ready?"];
  result [shape=doublecircle, label="Return validated plan\nto iteration-planning"];
  blocker [shape=doublecircle, label="Return question or blocker"];

  intake -> context -> capability -> scope_review -> scope;
  scope -> capability [label="no", style=dashed];
  scope -> design [label="yes"];
  design -> design_review -> design_agreed;
  design_agreed -> design [label="no", style=dashed];
  design_agreed -> adr [label="yes / if required"];
  adr -> adr_review -> adr_accept;
  adr_accept -> adr [label="no", style=dashed];
  adr_accept -> assemble [label="yes"];
  design_agreed -> assemble [label="yes / no ADR", style=dotted];
  assemble -> final_review -> consistent;
  consistent -> publish [label="yes"];
  consistent -> capability [label="scope issue", style=dashed];
  consistent -> design [label="design issue", style=dashed];
  consistent -> adr [label="ADR issue", style=dashed];
  publish -> validated;
  validated -> result [label="yes"];
  validated -> blocker [label="blocked"];
  validated -> capability [label="substantive issue", style=dashed];
}
```

## Writing the Plan

Inspect existing `docs/iterations/NNN-*` folders and use the next sequential zero-padded number, starting at `001`. Create `docs/iterations/NNN-lowercase-topic/plan.md`; keep supporting planning artifacts in the same folder. Do not edit implementation, test, migration, dependency or workflow files.

Use these exact sections unless an existing validated template requires additional metadata:

- **Title / Status** — iteration number and topic; status `Planned`.
- **Context** — evidence for the current engineering limitation and why it matters now.
- **Goal / New Capability** — the engineering outcome, not a list of tasks.
- **Iteration Type** — `Technical/engineering`, with why no new observable behaviour is intended.
- **Behaviour Preservation Contract** — observable behaviour, public interfaces and existing acceptance scenarios that must remain unchanged.
- **Scope** — one technical capability and its implementation boundary.
- **Out of Scope** — explicit deferrals, especially adjacent cleanup and product changes.
- **Related Problems** — inspect `docs/problems/README.md` and relevant notes; link each and state whether the iteration resolves, partially addresses, depends on or leaves it unresolved. Write `None known.` when appropriate; do not change problem-note status unless Matt asks.
- **Acceptance Scenarios / Feature Files** — normally `Not applicable`, with a reason and links to existing scenarios that protect unchanged behaviour where useful. A needed new product scenario means returning to the router for behaviour planning.
- **Designs** — `No design needed` with a reason. If the work changes a visible surface, return to the router to reconsider classification.
- **Technical Model** — responsibilities, interfaces, data flow, lifecycle, compatibility, migration, rollback and operational boundaries. Use `## Domain Model` instead when domain concepts, commands, events, invariants or ownership change.
- **Architecture Decisions** — links to every required Matt-accepted ADR, or `None required` with a reason. Do not defer a consequential choice to implementation.
- **Implementation Plan** — ordered, bounded steps, naming likely areas without prescribing speculative machinery.
- **Validation Plan** — focused proof of the capability, non-regression evidence, migration/rollback and operational checks where relevant, and `dev check` as the final project gate for implementation.
- **Risks / Follow-ups** — concrete failure modes, mitigations and deferred work.

The plan must be specific enough to implement without inventing product policy or consequential architecture. Do not include story points or time estimates unless Matt asks.

## Publishing and Validation

1. Maintain `docs/iterations/README.md` with number, title, plan link, date and `Planned` status.
2. Create or update ADRs only after Matt's explicit acceptance, and maintain `docs/adr/README.md`.
3. Run structural checks appropriate to the changed planning artifacts, including `git diff --check`. These are docs/skill-only planning edits, so do not run `dev check` unless executable examples or scripts were also changed.
4. Commit only agreed planning artifacts; do not include unrelated or implementation work.
5. Push the commit so clone-based validation sees the exact plan state.
6. Run:

   ```bash
   bin/dev fabro validate-plan docs/iterations/NNN-topic/plan.md
   ```

7. If validation finds a substantive issue, return it to scope, technical design/domain modelling, or ADR collaboration as appropriate; repeat that step's ensemble and Matt-agreement checkpoint, republish, and rerun validation. Validation may not introduce product behaviour or silently broaden the technical capability.
8. Return the plan path, pushed commit, validation result, related problems, accepted ADRs and any unresolved blocker to `iteration-planning`. Do not ask about or launch delivery here.

## Principles

- Preserve behaviour unless Matt reclassifies the work as behaviour-changing.
- One iteration is one engineering capability.
- Evidence and constraints precede implementation design.
- Prefer explicit deferral over opportunistic cleanup.
- Matt agrees consequential technical design and accepts ADRs; reviewers advise.
- The assembled plan needs no separate approval ceremony.
- Do not implement or launch delivery in this skill.
