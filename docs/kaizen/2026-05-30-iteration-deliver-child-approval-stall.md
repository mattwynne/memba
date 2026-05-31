# Problem: Iteration deliver stalled waiting for child-run approval

Date: 2026-05-30

## Context

We tried to deliver iteration `006-browser-cucumber-automation` using the project-local `iteration-deliver` skill.

Plan path:

- `docs/iterations/006-browser-cucumber-automation/plan.md`

Commands run from a clean `main...origin/main` checkout:

```bash
fabro validate .fabro/workflows/iteration-deliver/workflow.toml
fabro run .fabro/workflows/iteration-deliver/workflow.toml -I plan_path=docs/iterations/006-browser-cucumber-automation/plan.md -I mode=deliver
```

The workflow validation succeeded.

Parent deliver run:

- Run ID: `01KSWXA0F631SH0DNS9DZQFA0T`
- URL: `https://fabro.home.wynne.family/runs/01KSWXA0F631SH0DNS9DZQFA0T`

Validation child run:

- Run ID: `01KSWXBXPRGMFDBN2N74V344PQ`
- URL: `https://fabro.home.wynne.family/runs/01KSWXBXPRGMFDBN2N74V344PQ`

## What happened

The parent deliver run created the validation child run, but the child entered `run.pending` with reason `approval_required`.

The parent agent attempted to approve the child run via Fabro tooling. The first attempt included a reason and failed with:

```text
reason is only valid for action deny
```

The second attempt omitted the reason and failed with:

```text
Run approval must be performed by a user through the API, CLI, web UI, or human MCP server.
```

The parent then asked for external approval and blocked on human input. No answer was supplied before the watchdog timeout. The parent failed after 1800 seconds of inactivity with:

```text
stall watchdog: node "orchestrate" had no activity for 1800s
```

Implementation did not start.

## Observations

- The `iteration-deliver` workflow is intended to run one parent workflow with child runs for validation, implementation, and review.
- The validation child was configured with automatic approval in the run settings, but still entered `approval_required`.
- The parent worker could request the child start, but could not approve the child after it became pending.
- The parent surfaced the blocker only after spending time attempting approval internally.
- The final parent status was `run.failed` due to watchdog timeout, not a domain-specific status such as `validation:failed` or `validation:not-ready`.
- A local attempt to inspect the parent with incorrect commands (`fabro run show`, `fabro status`) failed because those subcommands do not exist; useful commands were `fabro inspect` and `fabro events`.
- The child run remained pending, so there was no validation result to decide whether the plan was ready.

## Why this matters

This creates avoidable delivery waste before any product work begins. A supposedly unattended parent workflow can stall indefinitely on a child approval gate, then fail by timeout rather than by a clear recoverable workflow status. The operator must manually inspect events, identify the child run, and decide whether to approve, resume, or restart delivery.

For future iterations, this risks losing the single-piece-flow delivery path and makes it unclear whether the correct recovery is approving the child, resuming the parent, rerunning delivery, or changing workflow approval settings.

## Open questions

- Why did a child run with automatic approval still require user approval?
- Should parent workflows be allowed to approve their own child runs, or should child runs be created in a state that cannot require user approval?
- Should `iteration-deliver` detect `approval_required` immediately and fail with an explicit recoverable status instead of waiting for the watchdog?
- What is the safe retry procedure after this state: approve the pending child and resume the parent, or start a fresh deliver run?

## Resolution

Date: 2026-05-31

Root cause: The `iteration-deliver` parent workflow created child Fabro runs that could enter `approval_required`; worker agents could not approve those child runs, so the parent stalled until the watchdog failed it.

Fix applied:

- `.fabro/workflows/iteration-deliver/`: removed the parent/child-run delivery workflow.
- `.pi/skills/iteration-deliver/SKILL.md`: removed the project-local skill that launched the stalled parent workflow.
- `bin/dev`: delivery now runs validation, implementation, and review directly from the user-controlled CLI boundary with `bin/dev fabro deliver ...`, keeping approval at the user-run command boundary.
- Commit `3f1d466`: simplified Fabro delivery orchestration and deleted the workflow path that produced this approval stall.

Validation:

- Read-only status check confirmed current `HEAD` no longer contains `.fabro/workflows/iteration-deliver` or `.pi/skills/iteration-deliver`.
- Read-only status check confirmed `.fabro/workflows/README.md` and `bin/dev` describe/directly run the replacement delivery flow.

Remaining follow-up:

- None for this note.

