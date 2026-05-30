# Kaizen: allow plan review ahead of implementation while enforcing implementation WIP limit

Date: 2026-05-29

## Context

While iteration 005 was still in progress, we planned iteration 006:

```text
docs/iterations/006-deliveries-overview/plan.md
```

We initially held back from launching `iteration-deliver` because the previous iteration had not completed. That was correct for implementation, but unnecessarily blocked plan review. Matt clarified:

> we can review the plan, just not implement it.

So we ran plan validation only:

```bash
fabro run .fabro/workflows/plan-validation/workflow.toml \
  -I plan_path=docs/iterations/006-deliveries-overview/plan.md
```

Run:

```text
01KSVT16Z5WP3SSAT0E8WSFJFC
```

Web UI:

```text
https://fabro.home.wynne.family/runs/01KSVT16Z5WP3SSAT0E8WSFJFC
```

The CLI timed out locally after 120 seconds, but the Fabro run completed successfully:

```text
status: succeeded
final_git_commit_sha: dc42b56f0ef36783b2b648b64c8292044fbfafb7
files_changed: 0
```

The plan was judged READY without edits.

## Problem

The current iteration flow conflates two separate WIP limits:

1. **Planning/review WIP** — it is useful to draft and validate the next plan while the current implementation is still running.
2. **Implementation WIP** — only one iteration should be actively implemented at a time, to avoid overlapping product changes, branch/main contention, and review confusion.

`iteration-deliver` currently combines validation, implementation, review, and merged-status finalization in one auto-continuing workflow. That is convenient once an iteration is allowed to start implementation, but too coarse when the desired action is "review this next plan now, but do not implement until the current iteration is done."

## Desired behaviour

Support a lifecycle where the next iteration can be validated early, while implementation remains single-piece-flow:

```text
Iteration N:    implementing / reviewing / finalizing
Iteration N+1:  draft -> plan-validation READY, then waits
```

When iteration N is complete, iteration N+1 can be handed to `iteration-deliver` or a delivery-resume command to start implementation from its already-reviewed READY plan.

## Proposed change

Add an explicit pre-implementation holding state and/or command shape:

- `plan-validation` remains runnable independently and marks/report the plan as READY.
- `iteration-deliver` should either:
  - refuse to proceed past validation when another iteration is active, or
  - accept an input such as `mode=validate_only` / `hold_before_implementation=true`.
- A later command starts implementation only when the implementation WIP limit is clear.

Possible states in `docs/iterations/README.md` / plan front matter:

```text
draft -> ready -> validated -> implementing -> merged
```

or, if we want fewer states:

```text
ready      = human-approved plan, not necessarily machine-validated
validated  = plan-validation READY, waiting for implementation WIP slot
```

## WIP rule

Enforce a single active implementation slot:

- At most one iteration may be in `implementing`, `ready-for-review`, or equivalent active-delivery state.
- Any number of future plans may be `draft`, `ready`, or `validated`, provided they do not edit application code during planning.
- Starting implementation for a validated plan checks the index/current run state and refuses if another iteration is active.

## Why this helps

- Keeps planning momentum while an implementation run is still underway.
- Lets plan validation feedback arrive earlier, while Matt still has context.
- Avoids the ambiguity of launching full `iteration-deliver` just to get validation.
- Preserves the important single-piece-flow discipline for implementation and review.

## Follow-up ideas

- Add a `bin/dev iteration-validate-plan <plan_path>` wrapper for the standalone validation command.
- Add `bin/dev iteration-start <plan_path>` or an `iteration-deliver` mode that requires the plan to be validated and the implementation slot to be free.
- Teach `iteration-planning` to run standalone validation when another iteration is active, then stop after reporting READY rather than launching full delivery.
- Make the WIP check deterministic by reading `docs/iterations/README.md` and/or Fabro active runs before implementation starts.

## Resolution

Date: 2026-05-29

Root cause: the delivery workflow had only one command shape (`iteration-deliver`) for validation plus implementation/review/finalization, and it had no explicit implementation WIP reservation/check before starting the implementation child.

Fix applied:

- `.fabro/workflows/iteration-deliver/workflow.toml`: added a `mode` input with `deliver` and `validate_only` modes.
- `.fabro/workflows/iteration-deliver/prompts/orchestrate.md`: taught the parent orchestrator to stop after validation in `validate_only` mode, and to check/reserve the implementation WIP slot before creating the implementation child in delivery mode.
- `.fabro/workflows/scripts/iteration_status.py`: added a deterministic status helper that reads `docs/iterations/README.md`, detects active implementation statuses, and updates the selected plan/index status.
- `.fabro/workflows/plan-validation/scripts/publish_ready.sh`: changed successful validation to mark plans `validated` rather than `ready`, making the pre-implementation holding state explicit.
- `.fabro/workflows/iteration-implementation/workflow.fabro`: added a direct-run WIP gate so the manual implementation escape hatch refuses to start when another iteration is active.
- `bin/dev`: added `iteration-validate-plan` and `iteration-start` wrappers.
- `.pi/skills/iteration-*`: updated iteration planning/delivery/implementation instructions to recognise `validated` and the validate-only flow.
- `.fabro/workflows/README.md` and `docs/iterations/README.md`: documented the split between parallel plan validation and single-piece-flow implementation.

Validation:

- `fabro validate .fabro/workflows/iteration-deliver/workflow.toml` — passed.
- `fabro validate .fabro/workflows/plan-validation/workflow.toml` — passed with existing goal-gate retry warnings.
- `fabro validate .fabro/workflows/iteration-implementation/workflow.toml` — passed with existing-style goal-gate retry warnings, plus the new WIP-blocked gate warning.
- `python3 -m py_compile .fabro/workflows/scripts/iteration_status.py` — passed.
- `.fabro/workflows/scripts/iteration_status.py check-clear docs/iterations/005-browser-acceptance-harness/plan.md` — passed; the implementation WIP slot was clear.
- `dev check` — failed in the pre-existing Cucumber configuration test because `web/test/features/cucumber_configuration_test.exs` expects operator feature text (`Alice and Bob are people`, `Alice and Bob are members of Kootenay Mountaineering Club`) that is no longer present in `acceptance-tests/features/operator_email_deliverability.feature`. The kaizen fix did not change acceptance feature files or web tests.

Remaining follow-up:

- Repair the existing Cucumber configuration test / operator feature drift separately so `dev check` is green again.
