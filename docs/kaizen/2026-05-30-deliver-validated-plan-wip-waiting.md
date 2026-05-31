# Problem: deliver command should handle validated plans and WIP waiting explicitly

Date: 2026-05-30

## Context

We were reasoning about what would happen if Matt ran:

```bash
bin/dev fabro deliver docs/iterations/007-deliveries-overview/plan.md
```

Iteration `007-deliveries-overview` is already `validated` in `docs/iterations/README.md`, while another iteration was occupying the implementation WIP slot.

## What happened

The current delivery script shape was unclear enough that we had to reason it through in conversation:

- `bin/dev fabro deliver` was expected to run plan validation unconditionally before reserving the WIP slot.
- Matt pointed out that a plan already in `validated` status should not need to be validated again.
- Matt also pointed out that validation can still be useful while the implementation WIP slot is occupied, so checking WIP first would be too conservative for not-yet-validated plans.
- We identified a better intended flow: validate only when needed, then wait for the implementation WIP slot to become free before marking the selected iteration `implementing`.

## Observations

- Plan validation and implementation WIP reservation are separate gates with different concurrency rules.
- A `validated` plan represents a reusable validation result; re-running validation before every delivery is avoidable waste.
- A `ready` plan can still be validated while another iteration is implementing.
- The delivery helper does not yet expose an explicit wait/poll mode for the implementation WIP slot.
- Polling should observe iteration status rather than touching Fabro child runs or deleting branches. A safe poll can inspect `origin/main:docs/iterations/README.md` until active statuses clear.
- Once the slot is free, the helper should sync safely, re-check status, mark the plan `implementing`, commit, and push without forcing.

## Why this matters

Without explicit validated-plan and WIP-wait behaviour, operators may waste time re-validating already validated plans, or may have to manually watch for the WIP slot to clear and rerun delivery at the right moment. That makes the delivery handoff less deterministic and increases the chance of stale local status or accidental duplicate work.

## Open questions

- Should `bin/dev fabro deliver` wait by default after successful validation, or require an explicit `--wait` option?
- What poll interval is appropriate by default?
- Should the polling loop watch only `origin/main`, or also report local divergence before starting the final status transition?
- How should the command report the active iteration while waiting?

## Resolution

Date: 2026-05-30

Root cause: `bin/dev fabro deliver` treated validation and implementation reservation as one linear sequence: it always re-ran validation before checking WIP, and had no explicit waiting mode for the single implementation slot. That ignored the lifecycle meaning of `validated` and left operators to manually retry delivery at the right time.

Fix applied:

- `bin/dev`: delivery now reads the plan status, skips validation for `validated` plans, validates only `ready` plans, rejects other statuses, and waits by default for the implementation WIP slot to clear before marking the iteration `implementing`.
- `bin/dev`: added `--no-wait` for fail-fast WIP checks and `--poll-interval seconds` for the default wait loop.
- `bin/dev`: the wait loop polls `origin/main:docs/iterations/README.md`, reports active iterations, and only mutates local files after the slot is clear.
- `.fabro/workflows/README.md`: documented validated-plan reuse, WIP waiting, `--no-wait`, and poll interval behaviour.

Validation:

- `bash -n bin/dev` — passed.
- `bin/dev fabro deliver --help` — passed after adding top-level deliver help handling.
- `bin/dev fabro deliver docs/iterations/007-deliveries-overview/plan.md --no-wait` — clean-worktree fail-fast smoke passed after commit; it skipped validation for the already validated plan and reported iteration 006 occupying the WIP slot.

Remaining follow-up:

- None known.
