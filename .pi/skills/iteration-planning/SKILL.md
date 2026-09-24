---
name: iteration-planning
description: Start planning a product or engineering iteration, classify it as behaviour-changing or technical/refactoring, and route into the appropriate specialist planning skill.
---

# Iteration Planning Router

Use this skill as the single entry point for iteration planning. Keep this layer thin: establish what Matt wants to change, classify the work, invoke the specialist skill, then hand a validated plan to `iteration-delivery`.

Do not explore the repository before the initial interview establishes the problem. Do not write the plan, formulate scenarios, model the domain, author ADRs, validate the plan, or launch Fabro in this router; those responsibilities belong to lower-level skills.

## Intake

Ask Matt one focused question at a time until you know:

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

Pass the specialist the intake summary and Matt's wording. The specialist initializes `planning-progress` with its complete flow, then performs targeted context exploration.

## Completion

The selected specialist returns either:

- a published, validated plan path and commit;
- a question or decision for Matt; or
- a precise planning/validation blocker.

For a validated plan, invoke `iteration-delivery`. That skill owns the explicit launch decision and any Fabro command. Planning does not imply launch approval.

## Process Flow

```dot
digraph iteration_planning {
  rankdir=TB;
  node [shape=box, style="rounded"];

  start [label="Matt brings a problem or opportunity"];
  intake [label="Quick intake interview\nproblem · outcome · beneficiary"];
  classify [shape=diamond, label="Changes observable\nbehaviour?"];
  behaviour [label="behaviour-iteration-planning"];
  technical [label="technical-iteration-planning"];
  result [shape=diamond, label="Published and\nvalidated plan?"];
  blocked [label="Return question or blocker to Matt"];
  delivery [label="iteration-delivery\nasks whether to launch Fabro"];
  stop [shape=doublecircle, label="Stop or launch only\nwith explicit approval"];

  start -> intake -> classify;
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
