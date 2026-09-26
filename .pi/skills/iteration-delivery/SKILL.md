---
name: iteration-delivery
description: Present a published ready or validated iteration plan for explicit approval, then use Fabro deliver to validate if needed and implement.
---

# Iteration Delivery Launch

This skill owns the boundary between planning and implementation. It does not plan, revise, or implement locally. It uses the existing Fabro delivery command only after Matt gives one explicit approval for this plan.

## Required Input

Require:

- exact `docs/iterations/NNN-topic/plan.md` path;
- pushed commit containing the planning artifacts;
- plan/index status `ready` or evidence that the same published plan is already `validated`;
- any known delivery blocker or active WIP status.

If the plan is not published as `ready` or `validated`, return to the appropriate planning skill. Do not repair it here.

## Ask Before Delivery

Show Matt the exact command:

```bash
bin/dev fabro deliver docs/iterations/NNN-topic/plan.md
```

Ask: **“Do you want me to validate this plan and, if it passes, implement it with this command?”**

Planning completion, publication, validation-only success, feature agreement, domain-model agreement, or ADR acceptance is not launch approval.

- If Matt says yes explicitly, run the command and report the initial run ID/status or exact failure. `bin/dev fabro deliver` owns the clean-main check, validation for `ready` plans, validated-status check, predecessor/WIP controls, and implementation launch.
- If the plan is already `validated`, still require explicit approval before running `bin/dev fabro deliver`; do not infer approval from the earlier validation.
- If Matt chooses validation-only, do not run `bin/dev fabro deliver`. Use or hand off `bin/dev fabro validate-plan docs/iterations/NNN-topic/plan.md` only for that validation-only request.
- If Matt says no, later, validation-only, or does not answer, stop without launching implementation.

## Launch Boundaries

- Do not edit planning artifacts, product code, workflow files or tests.
- Do not start a different plan or bypass iteration ordering/WIP controls.
- Do not retry, rescue, push, merge, remove or resume a run unless Matt separately authorizes that action.
- Never use `fabro rm` without Matt's explicit approval as a last resort.
- If Fabro returns validation issues, delivery questions, predecessor/WIP blockers, or any other failure before implementation starts, preserve the exact feedback and return it to the owning planning skill or Matt. Do not autonomously make consequential changes or auto-retry.
- If Fabro is unavailable or fails before creating a run, report the exact error and the same safe retry command; do not call the iteration delivered.

## Process Flow

```dot
digraph iteration_delivery {
  rankdir=TB;
  node [shape=box, style="rounded"];

  input [label="Published ready or validated plan"];
  verify [shape=diamond, label="Evidence complete?"];
  return [label="Return to owning planning skill\nwith blocker or question"];
  ask [label="Show deliver command and ask:\nvalidate and, if it passes, implement?"];
  approve [shape=diamond, label="Matt's response?"];
  validation_only [label="Optional validation-only:\nvalidate-plan, no implementation"];
  stop [shape=doublecircle, label="Stop; no implementation launch"];
  run [label="Run bin/dev fabro deliver <plan>"];
  deliver_checks [label="Fabro checks clean main, validates ready plan,\nchecks validated status + predecessors/WIP"];
  issue [label="Preserve Fabro feedback;\nreturn to owning planning skill/Matt"];
  report [shape=doublecircle, label="Report run ID/status or exact failure"];

  input -> verify;
  verify -> return [label="no"];
  verify -> ask [label="yes"];
  ask -> approve;
  approve -> validation_only [label="validation-only"];
  validation_only -> stop;
  approve -> stop [label="no / later / no answer"];
  approve -> run [label="yes"];
  run -> deliver_checks;
  deliver_checks -> issue [label="issues or blockers"];
  deliver_checks -> report [label="implementation starts or command fails"];
}
```
