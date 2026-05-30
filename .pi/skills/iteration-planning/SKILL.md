---
name: iteration-planning
description: Interview Matt about the next product/dev iteration, turn the discussion into a focused iteration plan, and launch the project's Fabro iteration-deliver workflow. Use when planning the next iteration, shaping work before implementation, or preparing a plan for delivery.
---

# Iteration Planning Interview

## Overview

Help Matt turn an early idea for the next iteration into an implementation-ready iteration plan. Interview him through natural collaborative dialogue, write the plan down, and launch Fabro's `iteration-deliver` workflow.

<HARD-GATE>
Do NOT implement the iteration directly in the local checkout. Do NOT edit application code, migrations, step definitions, UI, or production docs except for iteration-planning artifacts in that iteration's `docs/iterations/` folder and acceptance feature files/scenarios when they are part of planning. Feature files are domain modelling and acceptance criteria; step definitions and executable test plumbing are implementation. This skill's terminal state is either a launched `iteration-deliver` run handed off after validation starts/succeeds, a revised plan after a validation NOT READY stop, or a clear explanation of why delivery submission was blocked.
</HARD-GATE>

## Checklist

Create a task for each item and complete them in order:

1. **Explore project context** — read relevant project docs, current plans, ADRs, recent commits, and code only as needed to understand the iteration.
2. **Interview Matt** — ask clarifying questions one at a time about goal, scope, acceptance criteria, business decisions, implementation shape, and validation.
3. **Size and slice** — decide whether the work is one shippable slice or several. If it is more than one, split it into separate iteration plans before going further (see Sizing and Slicing).
4. **Present draft plan sections and feature scenarios** — get Matt's approval or corrections before writing the final plan. If acceptance feature files/scenarios are drafted or changed, explicitly invite Matt to review them as domain language before calling the plan done.
5. **Write the iteration plan** — create an iteration folder at `docs/iterations/<iteration-number>-<topic>/` and save the plan as `plan.md` inside it. Add supporting planning artifacts there too, such as a manual demo/test script when useful. Draft or update acceptance feature files/scenarios when they clarify the domain behaviour for the iteration. Maintain `docs/iterations/README.md` as an index.
6. **Publish planning artifacts** — commit and push the plan, iteration index, supporting planning artifacts, acceptance feature files, and any workflow/skill changes needed for validation before running Fabro, so Fabro's clone-based remote sandbox can see them. Do not commit or push unrelated changes.
7. **Submit to Fabro** — run the `iteration-deliver` workflow against the saved plan.
8. **Handle Fabro feedback** — monitor only the validation stage. If deliver stops with `validation:not-ready`, summarize blockers and interview/revise/resubmit unless Matt stops. If validation is READY and implementation has been handed off, report the deliver run URL/ID and stop.

## Process Flow

```dot
digraph iteration_planning {
    "Explore project context" [shape=box];
    "Interview Matt" [shape=box];
    "Size and slice" [shape=box];
    "Present draft plan" [shape=box];
    "Matt approves draft?" [shape=diamond];
    "Write plan file" [shape=box];
    "Commit planning artifacts" [shape=box];
    "Launch iteration-deliver" [shape=box];
    "Validation ready?" [shape=diamond];
    "Revise plan" [shape=box];
    "Stop: delivery handed off" [shape=doublecircle];

    "Explore project context" -> "Interview Matt";
    "Interview Matt" -> "Size and slice";
    "Size and slice" -> "Present draft plan";
    "Present draft plan" -> "Matt approves draft?";
    "Matt approves draft?" -> "Interview Matt" [label="no / unclear"];
    "Matt approves draft?" -> "Write plan file" [label="yes"];
    "Write plan file" -> "Commit planning artifacts";
    "Commit planning artifacts" -> "Launch iteration-deliver";
    "Launch iteration-deliver" -> "Validation ready?";
    "Validation ready?" -> "Stop: delivery handed off" [label="yes"];
    "Validation ready?" -> "Revise plan" [label="no"];
    "Revise plan" -> "Launch iteration-deliver";
}
```

## Supplementary BDD Skills

When an iteration changes acceptance tests or introduces non-obvious user/domain behaviour, consider using the project-local `bdd-discovery` and `bdd-formulation` skills during planning.

Use `bdd-discovery` before writing Gherkin when the behaviour, rules, examples, questions, or slice boundaries need collaborative exploration.

Use `bdd-formulation` when drafting or reviewing Gherkin scenarios so feature files remain domain modelling artifacts rather than test scripts.

Do not force these skills for purely technical, obvious, or infrastructure-only iterations where acceptance scenarios would add little value.

## Interview Guidance

Ask only one question per message. Prefer multiple choice when it lowers effort, but use open questions when needed.

Cover these topics:

- **Goal** — what should be true after the iteration that is not true now?
- **Beneficiary** — who benefits: club admin, member, developer/operator, or another actor?
- **Smallest useful slice** — is this one rule or one piece of engineering, or several? (see Sizing and Slicing)
- **Scope boundaries** — what is explicitly out of scope?
- **Acceptance criteria** — concrete behaviours, examples, edge cases, permissions, and error states.
- **Business decisions** — domain, policy, copy, workflow, pricing, privacy, or support questions.
- **Technical shape** — likely modules, data, events/commands, integrations, UI, background work, and migration concerns.
- **Validation** — automated tests, acceptance tests, shared Cucumber scenarios, manual demo, stakeholder review, or operational checks.

Stop interviewing when you can write a plan that an engineer could start without inventing material product or technical decisions.

## Sizing and Slicing

An iteration should be **one shippable slice**: either one behaviour rule, or
one piece of engineering. Before drafting the plan, check the size and split
if needed.

- **Classify the work.** Is it behaviour-facing (changes what a user can
  observe) or technical/engineering (enables or restructures, with no new
  user-observable behaviour)?
- **Find the seams.** For behaviour-facing work, each Rule from example
  mapping is normally its own shippable slice, with that rule's examples as
  the slice's acceptance scenarios. For technical work, slice by capability.
- **Foundation first.** When behaviour needs architecture that does not exist
  yet (e.g. an event store before the first message can be sent), make that
  enabling architecture its own earlier technical iteration.
- **Split when it is more than one slice.** If the work spans several rules or
  bundles new architecture with behaviour, write it as several iteration
  plans, each independently shippable, rather than one big plan. A good slice
  leaves the build green with strictly more scenarios passing — or, for a
  technical slice, the same scenarios but a proven capability.

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

## Scope

### In scope

### Out of scope

## Acceptance Criteria

## Open Business Decisions

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
- Create one folder per iteration using the next sequential zero-padded iteration number and a lowercase hyphenated topic slug.
- Determine the next number by inspecting existing `docs/iterations/NNN-*` folders; start at `001` if none exist.
- Save the plan as `plan.md` inside that folder.
- Put supporting planning artifacts for the same iteration in the same folder, such as `manual-demo-script.md` or `validation-notes.md`.
- Draft or update shared Cucumber feature files/scenarios when they clarify the iteration's domain behaviour. Consider using `bdd-discovery` first if the rules/examples are unclear, and `bdd-formulation` when writing or reviewing the Gherkin. Keep scenarios abstract from test infrastructure: no CSS selectors, route names, button-click choreography, database setup, or adapter configuration.
- When feature files/scenarios are created or changed, show Matt the feature file path and a concise summary of the scenarios, and explicitly ask him to review the language/examples before treating the plan as final.
- Do not implement step definitions, fixtures, app code, migrations, UI, or test adapters during planning.
- Add or update the index entry in `docs/iterations/README.md` with the iteration number, title/topic, plan link, date, status, and any acceptance feature files changed.
- Example: `docs/iterations/001-member-import/plan.md`.
- Commit and push the plan, iteration index, supporting planning artifacts, and acceptance feature files before running Fabro validation so the clone-based remote sandbox can see them.
- Include workflow/skill changes in that commit only when they are needed for planning or validation.
- Do not commit or push unrelated changes or implementation work.

## Submitting to Fabro

Submit the saved plan with the project's `iteration-deliver` workflow after committing and pushing the planning artifacts. The workflow starts with plan validation, and only a READY verdict flows onward to implementation and post-merge review. The workflow runs in clone-based remote sandboxes; pushed artifacts are required so Fabro can read newly-created plans and acceptance feature files.

```bash
fabro run .fabro/workflows/iteration-deliver/workflow.toml -I plan_path=docs/iterations/NNN-topic/plan.md
```

If Matt wants a validate-only check, run `plan-validation` manually instead:

```bash
fabro run .fabro/workflows/plan-validation/workflow.toml -I plan_path=docs/iterations/NNN-topic/plan.md
```

If the local Fabro server is unavailable or the command fails before creating a run:

1. Report the exact error.
2. Do not treat the plan as validated.
3. Tell Matt the plan file path and the exact command to retry.

If deliver stops at `validation:not-ready`:

1. Summarize the blocking gaps.
2. Ask Matt one question at a time to resolve them.
3. Edit, commit, and push the plan.
4. Re-run `iteration-deliver`.

If deliver reports validation READY / starts implementation:

1. Report the plan path and deliver run ID/URL.
2. Explain that implementation, review, and merged-status finalization continue unattended in child runs.
3. Stop monitoring unless Matt explicitly asks you to inspect the delivery run.

## Key Principles

- One question at a time.
- One iteration is one slice: one rule, or one piece of engineering. Split anything bigger.
- Make business decisions explicit.
- Make technical decisions explicit enough to start.
- Make acceptance criteria testable.
- Make validation observable.
- Do not implement locally during this skill; `iteration-deliver` owns any implementation it starts after validation.
