# Problem: worker timeout stranded a ready-for-review candidate

Date: 2026-09-30

## Context

Iteration [067](../iterations/067-live-projection-queries/plan.md) resumed from its accepted task-005 checkpoint in Fabro run [`01M3RCMKB0QE3KXT99PMFV8E8B`](https://fabro.home.wynne.family/runs/01M3RCMKB0QE3KXT99PMFV8E8B). The just-in-time planner prepared task 006: migrate conversation detail to the provisional live-query binding, prove message/author/follow/delivery/access invalidations and transient state, and freeze the extraction contract. Tasks 001, 003, 004 and 005 had been accepted; 006 was still pending.

Related but distinct observations: [timeouts with weak diagnostics](2026-07-13-implementation-timeout-lacks-progress-diagnostics.md), [a timeout masking a failing test](2026-09-03-iteration-workflow-timeout-masks-test-failure.md), and [test feedback cost in implementation loops](2026-09-14-test-feedback-cost-outgrew-implementation-loop.md). Here the unusual failure was **after** a worker-result artifact reported passing focused checks but **before** independent review could start.

## Expected standard

A bounded worker should return `ready_for_review`, `replan`, or `human_blocked` with a durable `.delivery/latest-worker-result.json`. A successful worker stage routes that artifact through `route_worker_result` and then to independent `validate_task` for review. A timeout must not accept a task on the strength of a self-reported result; it should preserve the candidate and make safe review/recovery possible.

## What happened

Fabro's `implement_next_task` started at 06:31:23 UTC and failed at 07:11:23 UTC with `handler timed out after 2400000ms`. The agent was still active near the deadline, rather than stuck in one long-running test: events show repeated edit/test cycles, a final 36-test group with zero failures at 07:08:15, an edit to `.delivery/latest-worker-result.json` at 07:09:53, checks of that file around 07:10:32–07:10:53, and a completed plan update at 07:11:06. An LLM call began at 07:11:06, first output arrived at 07:11:18, and the stage timed out five seconds later. The run-branch checkpoint preserved code and a `ready_for_review` result listing 11 changed paths, four successful focused validation commands, and no unresolved items. These are **worker claims and partial run evidence**, not independent acceptance or a full quality gate.

The failure edge in `.fabro/workflows/iteration-implementation/workflow.fabro` sends `implement_next_task` to `route_worker_result` only when the stage succeeds; a failed stage instead goes to `task_stopped`. The checkpoint's latest review remains the task-005 acceptance. Task 006 remains unchecked, no `validate_task` review of it ran, and no 067 application work was published to main. The preserved candidate is on `origin/fabro/run/01M3RCMKB0QE3KXT99PMFV8E8B`.

## Impact

A potentially useful candidate cannot take the normal review path without explicit recovery, so the implementation WIP slot remains occupied while an operator inspects the checkpoint. Retrying the whole worker may repeat nearly forty minutes of work or risk overwriting its preserved candidate; silently checking off task 006 would bypass independent review. There is no evidence here that the candidate is correct or publishable.

## What allowed it to happen

The planner's task-006 packet included fresh authorization, conversation composition, exact invalidation matching, two independently committed delivery contributors, follow state, LiveView migration, transient UI preservation, and generic-contract freeze in one 40-minute worker visit. The worker prompt allows `replan` for excessive scope, but this worker pursued the full packet and used almost the whole visit iterating on focused tests and writing evidence. That is a plausible sizing/budget contributor, not proof that any individual requirement was unnecessary.

The immediate routing mechanism is certain: the stage timeout preempts the success-only worker-result route even when a JSON file exists. This is a useful fail-closed acceptance boundary, but there is no automatic, provenance-checked path from a timed-out worker's preserved result and code to **independent review**. The result itself is self-reported; file presence alone must never be treated as acceptance.

## Investigation — 2026-09-30

**Evidence checked:** `fabro events 01M3RCMKB0QE3KXT99PMFV8E8B --json`, run-branch `.delivery/current-worker-packet.json` and `.delivery/latest-worker-result.json`, `todo.md`, the latest review, worker prompt, workflow edges, and `delivery_planner_state.py` result routing. Focused test output in the event stream supports the worker's reported passing *subset*, but the full validation commands, entire checkpoint diff, and behaviour have not yet been independently re-run or reviewed. No provider outage or single hung shell command was established. The exact reasons the worker did not finish its final response before the deadline remain unknown.

**Target condition:** A task that reaches a valid, checkpointed handoff gets an independent review without repeating its whole implementation, while an incomplete or stale handoff remains unaccepted and all final gates still run. A future planner/worker should either finish a sensibly bounded packet with time to hand off, or return `replan` with preserved partial work before the deadline.

**Simplification check:** The worker result is already the intended structured handoff; adding another progress document or trusting final prose does not solve the boundary. Do not loosen the clean-tree, planner, review, or final quality gates; do not simply increase every worker's timeout. Instead, first reuse the existing checkpoint **only after** checking packet identity, candidate diff, result provenance, and focused validation, then submit it to the existing independent review under an explicitly approved recovery procedure. If no safe continuation route exists, stop and design one rather than treating the artifact as a verdict.

**Options and trade-offs:**

1. **Immediate correction (recommended):** inspect the saved task-006 diff and validation against the packet; with Matt's approval, continue from the preserved checkpoint into independent review without marking 006 complete. This conserves work but needs a demonstrated safe resume path and human oversight.
2. **Prevention (recommended separately):** before another similarly wide task, have the planner split genuinely independent vertical proofs/contract freeze into smaller pending packets while preserving the approved acceptance scope; require early `replan` when a worker cannot finish with handoff margin. This reduces wall-clock exposure but must not fragment proofs so far that cross-projector convergence is lost. Compare future worker durations, replan frequency, and review defects against this run.
3. **Detection/containment:** evaluate a deterministic timeout-recovery path that checks artifact schema, packet identity, post-write worktree/checkpoint consistency, and focused-validation provenance, then **only** queues independent review. Test absent/stale/tampered result and post-result code changes to ensure they remain stopped. This is more machinery; defer unless manual recovery or repeat incidents justify it.
4. **Do nothing / extend timeout:** cheap operationally, but leaves useful candidates stranded or allows larger visits without solving the handoff boundary. Not recommended as the primary correction.

**Decision pending:** Matt has not approved a task-006 recovery or any workflow change. First verify the candidate and a safe review entrypoint; if it cannot be proven, request a recovery design decision. Keep 006 unchecked until independent review accepts it, then complete remaining tasks and final checks. No countermeasure was implemented by this investigation.
