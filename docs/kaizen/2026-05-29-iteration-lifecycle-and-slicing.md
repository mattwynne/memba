# Idea: keep iterations small by sizing and slicing during planning

Date: 2026-05-29
Status: done (skill change); rest parked

## Problem

The original `001-member-message-deliverability` plan was an 18-task iteration
that built the whole event-sourced stack, two contexts, and all delivery
statuses and views at once. `iteration-implementation` repeatedly failed on
it. We hand-split it into four shippable iterations (001 foundation, 002
membership, 003 messaging, 004 statuses + views), which worked — but nothing
in the planning flow had discerned the size up front.

## What we changed (done)

Added a **Sizing and Slicing** habit to the `iteration-planning` skill
(`.pi/skills/iteration-planning/SKILL.md`):

- An iteration should be one shippable slice: one behaviour rule, or one piece
  of engineering.
- Classify the work as behaviour-facing or technical/engineering.
- Behaviour-facing: each Rule from example mapping is a seam → its own slice,
  with that rule's examples as the slice's acceptance scenarios. Technical:
  slice by capability.
- Foundation-first: enabling architecture that behaviour depends on becomes
  its own earlier technical iteration.
- Split a too-big plan into several plans before marking it ready; replace the
  original (no epic doc); number sequentially before any is implemented.
- Replaced the old vague "propose 2-3 slices" checklist step and section, and
  pointed at the 001→004 split as the worked example.

This is deliberately just prose guidance in the skill, not new machinery.

## Parked — do NOT build yet

This started as a much larger design (a full iteration lifecycle with verdicts,
a conductor, and gates). That was over-complex — the same disease we were
trying to cure. Parking these until a real pain demands them:

- A formal `TOO BIG` verdict in the `plan-validation` workflow (distinct from
  `NOT READY`).
- A `Kind:` (behaviour / technical) field in the plan format so a sizer could
  apply the right threshold automatically.
- An intake time-check gate ("do you have time to plan this now?") that defers
  a goal as a stub plan with `Status: captured`.
- A thin top-level `iteration` conductor skill that runs plan → implement →
  review with human gates between phases.

The good ideas worth keeping (rules-as-seams, behaviour-vs-technical,
foundation-first, slice-before-numbers-are-spent) now live as a few sentences
in the skill. They did not need a subsystem.

## Related notes

- `2026-05-28-extract-iteration-review-workflow.md`
- `2026-05-28-resumable-iteration-implementation.md`
