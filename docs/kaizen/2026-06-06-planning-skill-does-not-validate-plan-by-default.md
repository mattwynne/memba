# Problem: Planning skill does not validate plans by default

Date: 2026-06-06

## Context

Matt observed that the project-local `iteration-planning` skill should submit an iteration plan for validation and attend to the feedback once it comes back.

Current standard work lives in `.pi/skills/iteration-planning/SKILL.md`. The skill writes and publishes iteration plans under `docs/iterations/`, then hands off the delivery command to Matt.

## Expected standard

Before an iteration plan is treated as ready for delivery, the planning workflow should submit the plan to the available validation mechanism and revise the plan in response to validation feedback.

The validation loop should be part of the planning workflow, not an optional afterthought, so known plan gaps are found before delivery starts.

## What happened

The current `iteration-planning` skill only runs early validation when Matt explicitly asks for it:

- Checklist step 8 says to run `bin/dev fabro validate-plan <plan_path>` only if Matt explicitly asks for early plan validation before delivery.
- The handoff section says `bin/dev fabro deliver <plan_path>` validates the plan as part of delivery, but by then the planning skill has already handed control back to Matt.
- The documented terminal state includes a revised plan after optional validation feedback, which makes validation a discretionary branch rather than the normal planning standard.

This means a plan can be committed, pushed, and handed off without the planning skill first submitting it for validation and responding to the validator's feedback.

## Impact

Quality risk and avoidable rework. Delivery may start with defects that the validator could have found while the planning context was still active. Feedback then arrives later in the Fabro delivery path, where it may interrupt implementation, require manual recovery, or force Matt to re-engage planning decisions that could have been resolved before handoff.

## What allowed it to happen

The planning workflow has a weak validation gate. It treats plan validation as optional and user-triggered rather than as a required readiness check before handoff.

The handoff depends on `bin/dev fabro deliver` to validate, but the planning skill's responsibility ends before it has attended to validation feedback. That creates an ownership gap between planning and delivery.

## Observations

- The abnormality is in delivery machinery, not product behaviour.
- The skill already knows the validation command: `bin/dev fabro validate-plan <plan_path>`.
- The skill already documents how to respond when validation reports `NOT READY`, but only under the early-validation branch.
- Because validation is optional, the workflow can publish a plan that has never been validated in the context where it was authored.

## Why this matters

Iteration planning is supposed to produce implementation-ready work. If validation feedback is deferred until delivery, plan defects are discovered after more process has accumulated around them. That increases delay, context switching, and the chance that implementation agents compensate for unclear plans instead of returning them for repair.

## Open questions

- Should every planning run validate before handoff, or only plans that meet certain criteria such as behaviour-facing work or changed acceptance features?
- If validation is asynchronous or slow, what status should the planning skill report while waiting, and what retry/recovery path should it document?
- Should validation happen before or after pushing the planning commit, given Fabro's clone-based remote sandbox requirement?

## Possible prevention ideas

- Make `bin/dev fabro validate-plan <plan_path>` a normal required planning step before the delivery handoff.
- Move the existing `NOT READY` response loop into the main workflow rather than the optional early-validation branch.
- Update the terminal state and process-flow diagram so a plan cannot be called ready until validation feedback has been handled or validation is explicitly unavailable with a recorded reason.
