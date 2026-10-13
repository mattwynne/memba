# Problem: adapter review churn required repeated human gates

Date: 2026-10-03

## Context

Iteration [067](../iterations/067-live-projection-queries/plan.md) is delivering a committed-read-model adapter, query consumers, and a reusable live-query package through the [iteration implementation workflow](../../.fabro/workflows/iteration-implementation/workflow.fabro). The intended arrangement is bounded planner/worker/reviewer tasks with independently accepted checkpoints, a human gate for consequential decisions or genuinely repeated failure, and final quality/publication gates. Related but separate observations concern [just-in-time planner handoffs](2026-09-14-just-in-time-delivery-planner.md), [late BDD feedback](2026-10-03-bdd-scenario-feedback-arrives-after-implementation.md), and [a worker timeout](2026-09-30-reviewed-candidate-stranded-by-worker-timeout.md).

## Expected standard

An actionable technical finding on an unchanged approved contract should be repairable and independently re-reviewed without repeatedly requiring Matt to authorize the same kind of repair. Human input remains necessary when a business example or architectural constraint changes the plan. Checked tasks, checkpoint provenance, the clean-tree and planner guards, independent review, and final `dev check`/publication gates must remain intact.

## What happened

Task 008A covers the adapter's actual event/projector families and query invalidation mapping. Four independent reviews of the preserved task-008A candidate returned `revise`, each after a worker reported focused tests passing. The first found missing-scope and no-op/coverage gaps; Matt identified the claimed club-without-person Membership fallback as an **invalid** input rather than a business case and the plan/matrix were corrected. Later reviews found recognized malformed no-op events were ignored before validation, then broad `{:conversation, conversation_id}` invalidation on follow changes, broad `{:person, person_id}` invalidation on membership/group-membership changes, and consumer fallback interests with no producer. A reported focused 30-test adapter run passed, but did not prove that unrelated queries were not reread. The last run, `01M41JBGVZ7CRH93KA4VT0T6QJ`, reached `task_discussion` at 19:31 UTC; Matt replied “Repair as planned,” and the clarification stop preserved the candidate. Task 008A remains unchecked and no 067 application code has been published to `main`.

Three task-008A human discussions were reached across the run chain: the first was caused by an **incorrect iteration-wide** revision count (four revisions on different tasks), subsequently repaired to count by task; later discussions were genuine per-task threshold stops, though each surfaced a distinct, actionable technical gap. The discussion path records guidance, then deliberately stops; resuming from a clean pushed checkpoint requires another branch/run and a new planner visit. A separate continuation run `01M41BW0XN9S1VPCTQRXPMB79T` stopped before a worker because the planner emitted `prepared_revision` rather than the allowed `prepared` status; the fail-closed guard worked, and prompt/schema coverage was corrected on `main` (`035b5fce6`). These are separate mechanisms, not evidence that the reviewer or guard should be weakened.

## Impact

Matt had to respond repeatedly to a technical repair loop; each stop required operator inspection and guarded continuation. The full 067 quality gates have not run, so this is repeated delivery friction and uncompleted work, not a customer-facing incident. Passing state/render assertions masked unnecessary rereads; the independent reviews prevented premature acceptance.

## Investigation — 2026-10-03

**Current versus target condition:** Four `revise` verdicts on one broad adapter task and repeated human gates versus reviewable tasks with one outcome, clear exclusions, focused positive/negative proof, and bounded worker/reviewer cost. For this particular task the proof is event-to-query dependency mapping and the *absence* of unrelated rereads. Zero human contacts is not the target: Matt's impossible/invalid Membership distinction genuinely changed the approved plan and needed his decision.

**Evidence-supported causes and escape path:**

- The accepted matrix included speculative fallbacks for partial synthetic notifications rather than only actual current/legacy event shapes. Matt's clarification removed that false contract. The adapter and two already-accepted consumers still had over-broad or inert interest keys; changing the adapter alone exposed producer/consumer mismatches.
- Task 008A treated eleven projector families, legacy recovery, malformed event contracts, no-op events, scoped interests, and consumer compatibility as one completion boundary. Work and tests advanced by narrow review finding. Focused passing tests measured output or state, not the *number and scope* of query refreshes. The reviewer checked more of the full boundary on later passes. This explains serial rework; the record does not establish that a separate readiness reviewer or a larger prompt would have caught it earlier.
- Plan validation's [scope](../../.fabro/workflows/plan-validation/prompts/scope.md) and [implementation](../../.fabro/workflows/plan-validation/prompts/implementation.md) reviewers ask whether the **iteration** is a smallest useful slice and its steps are clear, not whether each step fits a bounded worker/reviewer visit. The just-in-time [delivery planner](../../.fabro/workflows/iteration-implementation/prompts/delivery_planner.md) is explicitly empowered to split pending lines and prepare one bounded packet, but supplies no concrete packet-size test. It split the broad 008 work into 008A–008E and still left all adapter families in 008A. This is a planning/handoff scale gap across domains, not a special rule about projector events.
- The escalation code originally counted all iteration revisions, then was corrected to count only the selected task. Even with the correction, a fixed per-task count does not distinguish repeated failure of the *same* finding from distinct, bounded technical findings. The workflow turns every human clarification, including “repair as planned,” into a terminal stop, requiring manual checkpoint recovery. This is a deliberate safety boundary, not a publication defect.
- The separate `prepared_revision` failure came from a planner-output shape that the prompt/schema did not constrain, even though the deterministic guard did. Typed schema validation now rejects that status earlier. This explains a wasted pre-worker continuation but not adapter review churn.

**Simplification check:** Do not add invented event variants, a second readiness model, more blanket fallbacks, or more tiny handoff artifacts. Keep the current independent review and final gates. First reduce the size of the semantic assumption: map only real projector publications to the specific query dependencies they can change. Then provide focused positive and negative refresh-count proof across consumers. An open member-list BDD scenario proves its own update rule, not unrelated conversation/detail isolation.

**Options and recommendation:**

1. **Immediate 067 correction:** before another single-finding patch, trace all producer keys to query interests, remove inert or over-broad keys, reconcile the matrix, and add same-conversation/different-member and same-Person/different-club *refresh-count* tests; preserve valid club-wide/legacy convergence. Re-review the whole affected adapter/consumer boundary. This is a bounded repair of accepted scope, not acceptance or permission to publish.
2. **Prevention for future iterations (recommended first experiment):** at plan validation, ask whether the implementation steps can be decomposed into bounded, independently reviewable outcomes without inventing a missing business/architecture decision. Do **not** require the entire task list to be frozen then. At each just-in-time handoff, require the delivery planner to justify one worker-sized outcome, explicit exclusions, focused proof, and a credible time/review budget; split or replan an omnibus “all/every” step *before* worker dispatch while preserving its obligations and a later integration proof. For 008A specifically, that proof is real event-shape/dependency and unrelated-refresh tests, but other iterations need their own boundary. This changes the size of a handoff, not the number of reviewers or the final quality bar; a checklist based only on file count or arbitrary task count would not suffice.
3. **Human-attention policy (requires Matt's approval and workflow design):** escalate immediately for a policy/architecture conflict, same-finding no-progress, unsafe scope, or exceeded time/cost budget. Allow distinct actionable technical `revise` findings to continue automatically within a bounded *per-task* budget, with a durable checkpoint and full independent re-review; distinguish an explicit “repair as planned” reply from plan-changing guidance. A naive higher threshold merely hides churn, and removing human gates outright loses the architectural catch that mattered here.
4. **Do nothing:** preserves conservative stops but accepts repeated manual recovery for broad tasks; not recommended for this recurrence.

**Validation proposal:** On the next comparable iteration, record human interventions by reason (policy decision versus routine technical revision), revision findings per task, planner/worker/reviewer time and test setup cost, total end-to-end wall time, final-gate result, and any lost candidate or premature acceptance. Compare with 008A's four revise verdicts and three discussions; track the trade-off between fewer late findings and extra planner/reviewer invocations. Do not optimize task count alone. No experiment date or outcome is assumed.

**Matt's sizing constraint:** Smaller is not automatically better: every task pays a planner/review/test-setup cost. The goal is the smallest *coherent independently reviewable* unit that finishes with margin, not a task per file/event/step. Batch related changes sharing context and focused proof; make internal worker checkpoints cheap and review once per meaningful outcome. Split only when multiple outcomes/proofs compete for the time or review budget, and retain one integrated check. An arbitrary file-count or task-count limit would be counterproductive.

**Decision pending:** Matt has not selected a factory countermeasure. Repairing the present candidate and altering the future escalation/handoff workflow are separate decisions. This investigation does not change application or workflow code and does not accept 008A.

## Cross-workflow investigation — 2026-10-09

The earlier account ends after four revisions. Later run evidence records nine 008A revisions before independent acceptance; iteration 067 ultimately reached main through manual recovery, not autonomous Fabro completion. Its initial production deployment then failed during asset packaging after CI tests passed. These later facts do not change the historical acceptance state described above.

Matt requested a radically simpler unattended workflow rather than more packet-sizing or escalation patches. The [replacement proposal](../notes/2026-10-09-unattended-delivery-workflow.md) and [evidence inventory](../notes/2026-10-09-unattended-delivery-evidence.md) generalize this note's lesson: remove model-maintained task brokerage and operator-dependent continuation; use a scenario-first builder, independent review and a small deterministic controller for candidate preservation, bounded recovery, exact-artifact validation and verified deployment. Preserve genuine decision gates and all publication safety properties.

The investigation includes the existing `goal-directed-bdd` historical rehearsal; its successful continuation required prior manual recovery and does not prove whole-iteration autonomy. The recommendation is to prove the replacement's interruption/recovery and publication contract with an isolated walking skeleton before adding real agents or launching a delivery.

**Status remains Open; recommendation awaiting approval.** No factory code, run, delivery authorization or experiment status changed. The active post-merge healer experiment remains separate and occupies the ledger's experiment slot. This is a proposed replacement direction, not an approved second experiment or a claim of resolution.

## Additional observation: 2026-10-13 — 068 required operator takeover

### Expected and observed

The intended path was Plan → Implement → Focused checks → Independent review → Repair → Final checks → Accepted candidate, with one persistent builder workflow owning ordinary technical repair and current-main integration. Review findings are normal; parent-agent editing and manual stage handoffs outside that workflow are a failure of unattended completion.

The actual Fabro implementation run `01M4PD6HB4TPF9T2VVZQBYY837`, job `3b445881827e48b8bc7d75efee7e3d0c`, stopped with `Model visit budget exhausted`: ten coding-agent work visits, 351 tool operations, one process start and one provider recovery. A visit means a coding-agent run/resume, not necessarily a new SDK session or subscription quota. Ten was our runner-configured limit, not a Fabro-imposed limit. Candidate `0ab89a4e` was preserved **unaccepted**; no independent review ran. The original deadline, `2026-10-12T02:09:20.518459Z`, expired and was never renewed.

Historical offline bubblewrap gates repeatedly failed on unchanged source because of hostname/font/network dependencies. Later, the saved candidate passed the ordinary gate in normal Fabro Docker: 1,844 app tests, 19 package tests, seven journeys/114 steps. That validation wrapper then failed because `cmp` was missing; its separate packaging repair is recorded in the [missing-tool note](2026-05-31-iteration-implementation-python3-publish-failure.md). Neither result proves autonomous end-to-end completion.

Matt separately requested manual 068 completion. The parent integrated saved product into main `4910a5d9`, then `5645fb62`, accommodating owner API drift and iteration 070, and obtained actual-host tests. Three fresh Sol/high read-only source reviews rejected successive candidates:

- Review 1: focused untouched input could restore an old name (R1); inactive historical recipient names remained stale (R2).
- Review 2: remote raw-value acknowledgements could overwrite an unacknowledged dirty draft (R3); rejected untouched Save could leave browser text, server draft and confirmation inconsistent (R4).
- Review 3: an allowed 100-character unbroken Latin name pushed Edit outside an overflow-hidden card (R5). The 100-CJK and document-overflow checks missed the clipped control.

The parent repaired R1–R4 outside the intended workflow, retaining same-scenario connected-browser red/green evidence and committed-source receipts. Candidate `8d2e0432` passed the ordinary gate: 1,851 app tests, 19 package tests, eight journeys/121 steps; focused proof was 60 tests plus four Chromium tests at 390px/1320px. Ten actual responsive checks passed separately under a forced run, not the ordinary gate's skipped responsive pages. Review 3 still **rejected** it. Separately, complete config tests were 104 total/103 passed/one failed on a hard-coded lifecycle name; the relevant files were byte-identical to published main. This is not an all-green claim.

At this observation's cutoff, Matt explicitly approved one additional repair/review cycle at `2026-10-13T20:34:05Z`. Delegated R5 work was ongoing, not accepted or deployed. This new allowance did not renew either prior admission.

### Impact and system weakness

The work was preserved, but completion depended on operator recovery, integration, repairs and review scheduling. The product defects themselves are not factory kaizen findings; discovering and repairing them outside the intended workflow is the weakness. Green checks could not substitute for independent acceptance, and using the wrong test environment consumed effort without changing the candidate.

Uniquely versioned pinned images are now a completed foundation, not proof of this delivery loop. Normal-launcher/image-A-to-B proof remains unperformed. Selected attempts do not support a success-rate conclusion; even a later manual 068 shipment would not prove factory success.

### Open questions and possible prevention ideas

- Admit the correct normal test environment from the start, including network/font dependencies and checks that would otherwise be conditionally skipped.
- Keep independent review, bounded repair and current-main integration inside the persistent builder workflow, without parent editing or manual stage handoffs.
- Separate infrastructure, product work and review time in budget evidence; reserve review capacity and report the actual stop cause rather than simply increasing visits. Whether the existing cap was adequate for product work remains unknown.
- Preserve candidate-bound receipts and adversarial browser proof: focused inputs, delayed local changes, rejected-save consent and a visible, usable control—not only document overflow.

These are prevention ideas, not implemented fixes or changed experiment terms. The earlier investigation/proposal remains historical; this note stays **Open**. The separate post-merge healer retains its original five-qualifying-run requirement and October 19 review date.

Evidence: private local `/home/matt/.local/state/memba/fabro-proof/CURRENT.md`; `/home/matt/.local/state/memba/068-completion/HANDOFF.md`, `admission.json`, `independent-review-{1,2,3}-result.json`, and `extra-cycle-20261013/admission.json`. Raw private artifacts are not copied into the repository.
