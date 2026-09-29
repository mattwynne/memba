# Problem: deliver is blocked by its own run-ID pointers

Date: 2026-09-29

## Context

After publishing [iteration 067](../iterations/067-live-projection-queries/plan.md) on `main` at `613158301` and passing `bin/dev check`, Matt approved `bin/dev fabro deliver docs/iterations/067-live-projection-queries/plan.md`.

## Expected standard

Delivery should require an unambiguous published source state, protect unrelated local changes, and retain previous Fabro run IDs for recovery without requiring manual cleanup before the next run.

## What happened

The command stopped before validation or implementation with:

```text
Delivery requires a clean working tree before it marks the iteration implementing.
?? .fabro/tmp/
```

Only two prior wrapper-created files were present there: `iteration-implementation-run-id` (modified 2026-09-27) and `code-review-run-id` (modified 2026-09-28). Neither belongs to the new iteration's source. No 067 run was created by this attempt. The files remain untouched.

## Impact

Delivery is blocked until the operator preserves, moves, or otherwise handles the prior run pointers. The gate gives the same error for wrapper-generated recovery metadata as it would for genuinely unrelated work.

## What allowed it to happen

The delivery preflight uses an unqualified `git status --short` cleanliness check, while the same wrapper writes recovery pointers under an unignored, untracked directory in the checkout. The risk being guarded against is real; the wrapper's own outputs are not separated from that risk.

## Observations

- `bin/dev` writes `.fabro/tmp/iteration-implementation-run-id` when implementation starts and `.fabro/tmp/code-review-run-id` after review launch; the pointers contain Fabro run IDs, not run history.
- The predecessor [stream-timeout kaizen](2026-06-23-fabro-deliver-stream-timeout-ambiguous.md) deliberately introduced the implementation pointer to make remote runs recoverable. This new failure is a different boundary: a later deliver's clean-tree gate.
- `git check-ignore` confirms the pointers are not ignored. No attempt has been made to remove or move them; the safe immediate workaround is pending Matt's decision.

## Why this matters

A successful delivery can leave exactly the artifacts that prevent the next delivery from starting, despite a clean tracked source tree. Removing them casually would weaken recovery; bypassing the entire clean-tree gate would weaken source safety.

## Open questions

- Are any other launcher-generated files left under `.fabro/tmp/` in normal local delivery paths?
- Which repository-independent pointer location best supports worktrees and the existing recovery instructions?

## Investigation

Date: 2026-09-29

**Current versus target condition.** A committed, pushed, checked plan could not reach validation because two recovery pointers from prior runs made `git status --short` nonempty. The target is to retain both clean-source protection and run recovery across successive deliveries, with no manual move/delete step.

**Evidence and causal mechanism.** `_fabro_deliver` in [`bin/dev`](../../bin/dev) checks `git status --short` before pulling or validating (`~1756–1762`), with no path classification. The same script writes an implementation run ID at `~1838–1839` and a code-review run ID at `~2072–2073` under `.fabro/tmp/`. Those exact two files are currently untracked and not ignored; their modification dates predate the 067 launch. The 067 attempt stopped at the cleanliness gate and created no run. The earlier [run-recovery fix](2026-06-23-fabro-deliver-stream-timeout-ambiguous.md) explains why the implementation pointer was introduced. This is a producer/consumer location conflict in the launcher, not a Fabro validation result or an application defect. No evidence suggests the previous runs' contents are needed in this checkout; their IDs remain useful for recovery.

**Why the gate caught it, and why it is not enough.** The clean-tree check intentionally prevents local uncommitted changes or untracked files from contaminating the published-source delivery and subsequent pull/status commit. It detects the wrapper's own pointers too, but gives no distinction between those and user work. The pointer files persist after successful runs, so a later delivery can be blocked by normal wrapper operation. Whether there are other local launcher outputs beyond these two is unverified.

**Options.**

1. **Immediate correction, not prevention:** preserve the two files outside the checkout, confirm a clean status, and retry only with separate delivery authorization. Keeps recoverability but repeats next time.
2. **Simpler prevention if recovery remains adequate:** stop writing local run-ID pointers entirely; rely on durable Fabro run discovery and the launcher output. Verify discovery of a detached run after its output is lost first; the installed CLI lacks the documented `fabro runs list` command.
3. **If that test fails:** write only the launcher-owned recovery pointers to a worktree-aware Git metadata/state location outside the working tree. Keep workflow-internal `.fabro/tmp` scratch files separate.
4. **Less preferred:** ignore or exempt exactly the launcher-owned pointers from the cleanliness gate. This risks masking unexpected contents; previous `.fabro/tmp` ignore/checkpoint failures argue against ignoring the whole directory. Never relax the gate for arbitrary untracked files.

**Recommendation and validation.** First test whether an operator can identify a detached run from the current Fabro server/UI without saved terminal output; do not rely on future CLI documentation. If yes, prefer option 2: remove the redundant pointer writes, confirm a clean-tree preflight after an earlier run and that unrelated untracked work still blocks it, then observe the next authorized delivery. If no, test option 3 in an ordinary and linked worktree while retaining recoverability. Tests must not launch a real implementation merely to exercise preflight. This investigation changes no launcher or workflow code.

**Simplicity challenge (2026-09-29).** The local pointer files may be unnecessary if Fabro's durable run list offers dependable recovery when terminal output is lost. Stop writing them entirely would remove the producer/gate conflict while keeping the clean-tree safeguard. However, the installed `fabro 0.316.0-nightly.0` CLI does **not** support `fabro runs list` (`unrecognized subcommand 'runs'`), despite that command appearing in checked-in later-version documentation. `fabro run list --help` treats `list` as a workflow path. The Fabro web UI may provide run discovery, but its adequacy for finding a specific detached run after output loss has not been verified here. Before choosing either pointer removal or relocation, test recovery from the current server/UI and consider how to distinguish concurrent runs. If reliable discovery exists, prefer no local pointers; otherwise the worktree-aware Git metadata option remains a smaller safe change than weakening the gate.

**Decision pending.** Matt has not approved moving the current two pointers or retrying 067, nor chosen the permanent countermeasure. Leave the delivery blocked until he decides those separately.
