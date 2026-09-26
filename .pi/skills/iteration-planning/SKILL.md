---
name: iteration-planning
description: Start planning a product or engineering iteration, classify it as behaviour-changing or technical/refactoring, and route into the appropriate specialist planning skill.
---

# Iteration Planning Router

Use this skill as the single entry point for iteration planning. Keep this layer thin: understand the product context, establish what Matt wants to change, classify the work, invoke the specialist skill, then hand a published ready plan to `iteration-delivery`.

Before interviewing, make a short, read-only context pass so questions are informed rather than generic. Read the current product direction in `docs/iterations/roadmap.md`, the iteration history in `docs/iterations/README.md`, the canonical language in `docs/problem-domain-terms.md`, and `docs/problems/README.md` plus current problem records relevant to Matt's opening request. Inspect relevant recent or related iteration plans and acceptance features when they clarify what has already been tried or agreed. Summarize the likely context and uncertainties internally; do not infer Matt's present intent from repository history.

Do not write the plan, formulate scenarios, model the domain, author ADRs, run Fabro validation, or launch Fabro in this router; those responsibilities belong to lower-level skills. Keep this context pass targeted: broad implementation exploration belongs to the selected specialist.

## Intake

With that context, ask Matt one focused question at a time until you know:

- the problem or opportunity;
- the intended outcome;
- who or what benefits;
- whether success changes observable product/domain behaviour.

This is a short routing interview, not detailed discovery.

## Classification

Choose exactly one route:

- **Behaviour-changing** — changes what a customer, member, staff user, operator, integration, or other domain actor can observe; changes a business rule, policy, permission, lifecycle outcome, notification meaning, or externally visible result. Invoke `behaviour-iteration-planning`.
- **Technical/refactoring** — preserves agreed observable behaviour while changing internal structure, tooling, dependencies, performance, operability, migration machinery, or engineering capability. Invoke `technical-iteration-planning`.

If classification is unclear, ask Matt. Do not inspect implementation and infer the product classification silently. If a proposed technical iteration changes business behaviour, route it as behaviour-changing.

Pass the specialist the context summary, intake summary, relevant source links, and Matt's wording. The specialist performs deeper targeted context exploration.

## Completion

The selected specialist returns either:

- a published ready plan path and pushed commit;
- an already validated plan path and pushed commit when Matt explicitly chose validation-only before launch;
- a question or decision for Matt; or
- a precise planning, publication, or optional-validation blocker.

For a published ready or validated plan, invoke `iteration-delivery`. That skill owns the single explicit launch decision and the Fabro command. Planning, publication, or validation-only success does not imply launch approval.

## Process Flow

```dot
digraph iteration_planning {
  rankdir=TB;
  node [shape=box, style="rounded"];

  start [label="Matt brings a problem or opportunity"];
  context [label="Read product direction · problems\npast iterations · canonical language"];
  intake [label="Context-informed interview\nproblem · outcome · beneficiary"];
  classify [shape=diamond, label="Changes observable\nbehaviour?"];
  behaviour [label="behaviour-iteration-planning"];
  technical [label="technical-iteration-planning"];
  result [shape=diamond, label="Published ready or\nvalidated plan?"];
  blocked [label="Return question or blocker to Matt"];
  delivery [label="iteration-delivery\nasks: validate and, if it passes, implement?"];
  stop [shape=doublecircle, label="Stop, validation-only, or implement\nonly with explicit approval"];

  start -> context -> intake -> classify;
  classify -> behaviour [label="yes"];
  classify -> technical [label="no"];
  behaviour -> result;
  technical -> result;
  result -> blocked [label="no"];
  blocked -> behaviour [label="behaviour route", style=dashed];
  blocked -> technical [label="technical route", style=dashed];
  result -> delivery [label="yes"];
  delivery -> stop;
}
```
