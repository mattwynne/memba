---
name: iteration-delivery
description: Choose domain-only BDD implementation or full iteration delivery for a published ready or validated plan, then ask for explicit launch approval and run the guarded Fabro command.
---

# Iteration Delivery Launch

This skill owns the boundary between planning and implementation. It does not plan, revise, or implement locally. Choose the appropriate workflow, explain its scope, and use the guarded delivery command only after Matt explicitly approves this plan and mode.

## Required Input

Require:

- exact `docs/iterations/NNN-topic/plan.md` path;
- pushed commit containing the planning artifacts;
- plan/index status `ready` or evidence that the same published plan is already `validated`;
- agreed acceptance features, any remaining UI/journey/technical obligations, and known delivery blockers or active WIP.

If the plan is not published as `ready` or `validated`, return to the appropriate planning skill. Do not repair it here. Unresolved product, domain-model, architecture or UX decisions belong to planning, not an implementation agent.

## Choose the Workflow

Read the plan and its acceptance features. Make a recommendation; do not make Matt discover the available workflows.

### Domain-only BDD implementation — recommend for suitable domain work

Prefer this for a small, clearly agreed domain-focused iteration with pending domain declarations, settled decisions and little new UI/journey dependence. The approved rules must be expressible through eligible, locally pickable `@todo` Scenario, Scenario Outline or Examples declarations tagged for this iteration. Do not choose it for inherited-only TODOs or declarations whose selector names are ambiguous; see the workflow's known limits.

Use:

```bash
bin/dev fabro deliver docs/iterations/NNN-topic/plan.md --domain-only
```

This starts [the plan-level BDD workflow](../../../.fabro/workflows/bdd-plan-implementation/README.md): select one domain declaration, implement it, pass the graph-owned full `dev check`, then select again against the changed code. The historical three-scenario rehearsal supports trying this on suitable real work; it is not a reliability guarantee. Its selector made benign-looking read-only history queries, so literal snapshot-only compliance was not demonstrated. That recorded limit is not a practical launch blocker or a reason to buy another historical rehearsal.

**This is implementation, not full delivery.** It does not implement pending browser journeys, complete unrelated technical/UI work, independently review the result, merge product code, deploy, or mark the iteration merged. Explain any remaining obligations in the approval question. If a larger plan needs a separate domain phase, recommend this only with explicit agreement that those obligations remain afterwards. Do not silently substitute a domain phase for the whole plan.

### Full iteration delivery — for the other agreed work

Use the existing command for technical/refactoring work, UI/journey-led work, or a plan whose agreed scope needs the full implementation/finalization path:

```bash
bin/dev fabro deliver docs/iterations/NNN-topic/plan.md
```

This remains the existing `iteration-implementation` workflow. Unlike domain-only mode, it includes its publication/finalization path: it can mark the iteration merged and push product code directly to main, followed by detached post-merge review. Make that consequence explicit before approval. Do not use it merely to bypass unsuitable or blocked domain work. If neither route fits, return the concrete planning question rather than launching a best guess.

## Ask Before Launch

Show the exact command and explain why the selected mode fits.

- Domain-only: **“Do you want me to validate this plan and, if it passes, implement its domain scenarios with this command? I’ll leave the result for review and separate merge approval, with [named remaining obligations, if any] still outstanding.”**
- Full delivery: **“Do you want me to validate this plan and, if it passes, deliver it with this command, including its automatic publication to main?”**

Planning completion, publication, validation-only success, feature agreement, domain-model agreement, ADR acceptance, and approval of a different plan or mode are not launch approval.

- If Matt explicitly approves, run the shown command and report the run ID/status or exact failure. Both modes retain clean-main, validation, validated-status, predecessor and WIP controls. Domain-only mode additionally requires published HEAD and binds the public pending report to the requested plan and source SHA before creating a run.
- Already `validated` plans still need explicit launch approval. Never invoke the BDD graph directly from this skill to skip the guards.
- For validation-only, use `bin/dev fabro validate-plan docs/iterations/NNN-topic/plan.md`, not either implementation command.
- For no, later, no answer, or an unresolved scope choice, stop without launching.

## Report and Handoff

Domain-only launch returns a detached run ID, not a passing implementation result. Monitor with `fabro wait RUN_ID --no-upgrade-check` or `fabro inspect RUN_ID --json --no-upgrade-check`. A wait timeout is not proof of run failure. On completion, retain the final checkpoint/branch, check results, pending-domain and pending-journey reports, and remaining plan obligations. Keep the iteration `implementing`; report the candidate for review. Completion of domain declarations alone never means the iteration is delivered. Do not automatically invoke ordinary delivery, a healer, merge or deployment afterwards.

Full delivery retains its existing publication and detached post-merge review behavior; report those outcomes separately rather than implying review gated publication.

## Launch Boundaries

- Do not edit planning artifacts, product code, workflows or tests. The approved command owns validation and lifecycle reservation metadata.
- Do not start another plan, switch modes, or bypass ordering/WIP controls after a refusal.
- Do not retry, rescue, push product code, merge, remove or resume a run without separate authorization.
- Preserve exact validation feedback, delivery questions and failures; return them to the owning planning skill or Matt rather than repairing them here.
- An uncertain acknowledgement may hide a live run. Inspect before any retry; do not assume no run exists or free its WIP reservation. Domain-only mode preserves the reservation in this case. A proven pre-launch pending-admission failure can release its own reservation.
- Never use `fabro rm` without explicit approval as a last resort. Do not use `fabro sandbox cp` after a terminal run on stock 0.389: it can restart the stopped container. Read the workflow's [operations guide](../../../.fabro/workflows/bdd-plan-implementation/OPERATIONS.md) before collecting sandbox evidence.
- If the service is unavailable, report the exact failure and whether launch is known or uncertain. Never call the iteration delivered from a launch acknowledgement.
