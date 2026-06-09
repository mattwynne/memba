# Problem: implementation workflow left completed iteration marked implementing

Date: 2026-06-06

## Context

Matt tried to deliver the next validated iteration:

```bash
bin/dev fabro deliver docs/iterations/024-email-template-designs/plan.md
```

Before starting delivery, the command fast-forwarded `main` from `02f82b95` to `67de007f`. That pulled in the completed work for iteration 023, `Public copy pass for older community members`.

Relevant paths:

- `docs/iterations/023-copy-review-for-older-club-members/plan.md`
- `docs/iterations/024-email-template-designs/plan.md`
- `docs/iterations/README.md`
- `bin/dev fabro deliver`

## Expected standard

When an implementation/review workflow finishes and publishes an iteration's work to `main`, the lifecycle metadata should reflect that the predecessor iteration is complete. A subsequent delivery should not be blocked by an earlier iteration whose work has already landed.

For iteration sequencing, `bin/dev fabro deliver <plan>` should see earlier completed iterations as `merged` or otherwise non-blocking.

## What happened

After the fast-forward, iteration 023 had implementation artifacts and product/code changes on `main`, but its status was still `implementing`:

```text
| 023 | 2026-06-06 | implementing | Public copy pass for older community members | [plan](023-copy-review-for-older-club-members/plan.md) |
| 024 | 2026-06-06 | validated | Transactional email template redesign | [plan](024-email-template-designs/plan.md) |
```

The delivery command then refused to start iteration 024:

```text
== Plan already validated; skipping validation ==
== Checking predecessor iterations ==
Iteration delivery is blocked by earlier iteration(s) that are not merged:
- 023 Public copy pass for older community members (implementing) docs/iterations/023-copy-review-for-older-club-members/plan.md
Deliver earlier iterations first, or add an explicit workflow-supported override if this iteration is intentionally independent.
```

Command exited with code 1.

## Impact

This blocked delivery of iteration 024 even though iteration 023's work appeared to have been published to `main`. The operator now needs to inspect and repair lifecycle status before normal sequential delivery can continue.

The failure also creates uncertainty about the true state of iteration 023: the code is present, but the workflow metadata says the iteration is still active.

## What allowed it to happen

The delivery/review lifecycle appears to allow implementation artifacts to be published to `main` without also marking the completed iteration as `merged` in the iteration index and plan. The predecessor gate in `bin/dev fabro deliver` correctly enforces sequencing, but it trusts stale lifecycle metadata.

This suggests a missing or weak finalization guard in the implementation/review workflow: publishing work and finalizing iteration status are not treated as one atomic standard-work outcome.

## Observations

- The fast-forward output included iteration 023 implementation outputs, including:
  - `docs/iterations/023-copy-review-for-older-club-members/implementation-notes.md`
  - `docs/iterations/023-copy-review-for-older-club-members/replacement-copy-draft.md`
  - `docs/iterations/023-copy-review-for-older-club-members/test-copy-inventory.md`
  - `docs/iterations/023-copy-review-for-older-club-members/todo.md`
  - public/member-facing copy changes and matching tests.
- The latest local `main` commit after the fast-forward was `67de007f iteration 023: Public copy pass for older community members`.
- `docs/iterations/README.md` still listed iteration 023 as `implementing`.
- `docs/iterations/023-copy-review-for-older-club-members/plan.md` still listed `Status: implementing`.
- Iteration 024 had already been validated, but could not proceed because predecessor lifecycle metadata was stale.
- A related older kaizen note exists for failed delivery leaving stale `implementing` status: `docs/kaizen/2026-05-31-deliver-leaves-stale-implementing-status.md`. This observation is different: the work was published, but final lifecycle completion still did not happen.

## Why this matters

Sequential iteration delivery depends on lifecycle status being trustworthy. If a workflow can publish completed work without marking the iteration merged, the next delivery is blocked and operators must manually reconcile state. That adds delay, creates avoidable context switching, and risks unsafe manual status edits if the actual completion state is unclear.

## Open questions

- Did the iteration 023 implementation/review workflow finish successfully, or did it publish implementation work but fail before the finalization step?
- Which workflow step is responsible for marking an implemented iteration `merged`?
- Does the finalization step update both `docs/iterations/README.md` and the individual `plan.md`?
- Is there a guard that prevents publishing implementation work unless lifecycle finalization also succeeds?
- Should `bin/dev fabro deliver` detect this specific state and offer a safe repair or review command?

## Possible prevention ideas

- Make workflow finalization mark the iteration `merged` before or atomically with publishing the implementation result to `main`.
- Add a post-publish guard that fails loudly if a commit for an iteration has landed while its status remains `implementing`.
- Add a recovery command that verifies an iteration's implementation artifacts and review status before safely marking it `merged`.
- Have the predecessor gate distinguish "earlier iteration appears published but still marked implementing" from "earlier iteration is genuinely active" and point to the exact recovery path.

## Resolution

Date: 2026-06-09

Root cause: the iteration implementation publish step could squash and push the product implementation without including the lifecycle transition to `merged`, leaving `docs/iterations/README.md` and the selected `plan.md` stale after the implementation landed.

Fix applied:

- `.fabro/workflows/iteration-implementation/scripts/publish_to_main.sh`: now marks the selected plan and iteration index `merged` before staging and squashing the implementation, so the status metadata is included in the same trunk commit as the product artifact.
- `.fabro/workflows/iteration-implementation/scripts/test_publish_to_main.sh`: asserts that the published commit leaves both the plan status and iteration index row marked `merged`.

Validation:

- Existing evidence: commit `5ef01326` (`Fix iteration implementation publish finalization`) introduced and tested this prevention.
- No command rerun for this backfill; this change only records the already-applied resolution.

Remaining follow-up:

- None for this specific stale-status failure mode.
