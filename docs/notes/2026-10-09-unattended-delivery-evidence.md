# Evidence for the unattended-delivery replacement proposal

Date: 2026-10-09

Recommendation: [small developer loop and deterministic delivery controller](2026-10-09-unattended-delivery-workflow.md).

## Scope and method

Primary window: **2026-07-12 through 2026-10-09**, inclusive, with September 21 onward weighted most heavily. Older May/June notes establish recurrence and safeguards worth retaining, not a claim that every old defect remains unfixed.

Read-only investigation of operational systems; only proposal/kaizen documentation is changed. No runs were launched, resumed, removed, archived or steered. No credentials were changed. No subagents were spawned. Existing BB conversations were inspected, not messaged.

Inventory and depth:

- All **113 top-level kaizen notes** were inventoried through the ledger; detailed investigation concentrated on implementation, review, test feedback, recovery, publication and scope/BDD notes listed below. This is not a claim that every unrelated note was reread line by line.
- Retrieved **498 unique server run summaries**, including archived runs, through five paginated read-only requests. **460** identify `mattwynne/memba`; **144** of those fall in the primary window. The installed CLI lacks `fabro ls`/`runs list`; the authenticated API supplied the inventory. HTTP access used the project's Req library without printing tokens.
- Retrieved `inspect`, full event streams and worker logs for **35 recent runs**: all **29** implementation runs since September 21, both `code-review` runs, and all four `goal-directed-bdd` runs. Inspected stage/failure/interview histories across that set and drilled into anomalous worker/tool/reviewer evidence. Also retrieved inspect/events for two older successful implementation counterexamples, for **37 event streams** total. Reading selected relevant events is not a claim to have manually read every repeated token/tool payload in roughly 430 MB of exports.
- Inspected current implementation graph/prompts/contracts and publication/deployment source, the prior factory retrospective, current iteration state, and the experimental BDD branch at `3530f0ff9`.
- Inventoried **295 BB threads** visible for this project. Read relevant delivery/retrospective conversation history, including the later correction of the 067 hang diagnosis and manual recovery. Other threads were metadata context, not counted as proven interventions.
- Retrieved the latest **100 Continuous delivery runs** (September 22–October 7), detailed jobs for the original 067 delivery and current main, and failure logs for the October 5 deployments. This is a bounded CI sample, not the complete 90-day CI denominator.
- Inspected `yx 0.3.0`, its existing facade-retirement tree, and the corresponding parent conversation. No yak state changed.

Local working exports are under `/tmp/memba-workflow-evidence/`, `/tmp/memba-all-runs.json`, `/tmp/memba-stage-summary.txt`, `/tmp/memba-interviews.json`, `/tmp/memba-ci-runs.json` and `/tmp/memba-bb-067.txt`. These are temporary analysis aids; durable references below are the reproducible source. Do not commit raw conversations, credentials or huge event exports to the application repository.

## Quantitative observations—not a fabricated success metric

| Population | Observation | Interpretation limit |
| --- | --- | --- |
| Memba implementation attempts in the 90-day window | 68 terminal attempts: 62 failed, 6 succeeded | Attempts include rescues, clarification stops and different workflow revisions. Not a per-iteration or hands-off success rate. |
| Implementation attempts from September 21 | 29: 28 failed, 1 succeeded | The success is 066's final-publish recovery, not an uninterrupted initial delivery. |
| 067 implementation attempts from September 30 | 12, all currently marked failed | 067 subsequently merged by manual rescue. Four later summaries were marked terminated after server restart and report zero duration/cost despite substantial work in their events. |
| September 21 onward implementation summaries | $724.43 API-equivalent recorded cost; 33.22 recorded run-hours | Incomplete: the four zeroed summaries alone make this unsuitable as a true total. Human waiting is included in wall time. Subscription economics differ from API estimates. |
| Recent raw interview completions | Six; four “repair as planned” discussions total about 102 minutes | Includes one separate generated-file prompt and one genuine policy clarification. BB/Slack intervention coverage is incomplete. Do not call all waiting avoidable. |
| Active healer experiment | Two launched code reviews; both clean successes | Target is five qualifying reviews. Clean paths do not demonstrate bounded-heal or consequential-finding classification. |
| Historical BDD pilot | Four attempts: three failed, one successful continuation | Manual graph repair and provider switch occurred. Not four independent samples, not one hands-off whole delivery. |
| Latest 100 CI runs | Push: 62 success, 16 failure, 7 cancelled. PR: 10 success, 5 cancelled | Mixed changes and cancellations, no linkage to all approval/dispatch records. |

There is still no trustworthy per-delivery ledger joining initial approval, all attempts, human interventions, reviewed SHA, tested SHA, publication, actual deployment and cost. The proposal deliberately makes that identity part of the controller, rather than drawing a false percentage from terminal Fabro status.

## Primary causal findings

### 1. Task brokerage is both expensive and a failure surface

In run [01M3QTFPMN3D56FENQ172YE40K](https://fabro.home.wynne.family/runs/01M3QTFPMN3D56FENQ172YE40K), the September 30 planner took 11.06 minutes, then the guard rejected plain-string references where `{path, facts}` objects were required. No worker ran. This was not an application defect.

A later October 3 continuation, [01M41BW0XN9S1VPCTQRXPMB79T](https://fabro.home.wynne.family/runs/01M41BW0XN9S1VPCTQRXPMB79T), spent 10.87 minutes planning and stopped with `Pending obligation task-008a has invalid status`. The note identifies `prepared_revision`; `035b5fce6` corrected schema coverage. The guards worked; the model-maintained handoff remained a source of interruption.

For [01M3R0GGQHYQH093N9J0JG543V](https://fabro.home.wynne.family/runs/01M3R0GGQHYQH093N9J0JG543V), summing completed stage timings gives about 50.1 minutes of `delivery_planner`, 52.0 minutes of implementation/revision and 40.0 minutes of task review, plus 45.0 minutes in human discussion. This is one run, not a general performance estimate.

The current graph has 50 nodes in the latest captured 067 execution; the checked-out graph is 449 lines, and its planner-state helper is 680 lines. Size alone is not causation. The material complexity is duplicated identities/status plus mandatory model→schema→guard exchanges. The earlier planner fix addressed real broad-discovery/context problems; deleting it is safe only if executable small outcomes and bounded context replace its useful preparation responsibility.

Sources: [planner note](../kaizen/2026-09-14-just-in-time-delivery-planner.md), [062 investigation](../kaizen/2026-09-03-iteration-workflow-timeout-masks-test-failure.md), current [graph](../../.fabro/workflows/iteration-implementation/workflow.fabro), raw events for the three runs.

### 2. Recovery is designed to require an operator

Run [01M3RCMKB0QE3KXT99PMFV8E8B](https://fabro.home.wynne.family/runs/01M3RCMKB0QE3KXT99PMFV8E8B) spent 25.55 minutes preparing task 006, then its worker exhausted 40 minutes. A preserved `ready_for_review` artifact and some passing focused test evidence existed, but the failed-stage edge bypassed review and stopped. Neither artifact presence nor time spent proves correctness; a provenance-checked continuation into observation/review is the missing operation.

Four separate 067 discussions recorded repair-under-existing-plan guidance at September 30 05:11 and October 3 19:01, 19:56 and 21:43 UTC. Each ended at `task_clarification_complete`, whose script explicitly forbids automatic restart. That terminal stop is not accidental runtime behaviour: it is the implemented policy.

By contrast, October 3's Membership-without-person clarification changed a contract assumption and appropriately needed Matt. It waited about 9h25m; do not attribute that whole interval to unnecessary technical gates.

Sources: [timeout note](../kaizen/2026-09-30-reviewed-candidate-stranded-by-worker-timeout.md), [churn note](../kaizen/2026-10-03-adapter-review-churn-required-repeated-human-gates.md), [workflow documentation](../../.fabro/workflows/README.md), raw `interview.completed` events and current graph.

### 3. Reviews found real gaps, not just bureaucratic objections

The October 3 churn note records the first four 008A revisions. The later [retrospective conversation](@thread:thr_cb45jbj3w4) and raw run events extend the sequence to nine before acceptance:

- Missing/no-op/malformed-event contract coverage.
- Over-broad invalidations and producerless query interests.
- Synthetic tests omitting the real `person_clubs` interest.
- Impossible reduced fixtures: absent/mismatched roots and inconsistent sender/originator/latest-replier relationships.
- Finally, production-presenter construction and actual query interests supported acceptance around October 4 00:12 UTC in [01M422K1QSVNZT7QYZVEWK4GSC](https://fabro.home.wynne.family/runs/01M422K1QSVNZT7QYZVEWK4GSC).

The worker repeatedly had green focused tests. Therefore “use TDD” is insufficient unless tests observe the real risk and fixtures respect production invariants. Independent final recovery review also found a reply-delivery regression; the [recovery record](../iterations/067-live-projection-queries/delivery-recovery.md) and commit `e16727a58` record the accepted repair.

The evidence does not prove another review panel or mandatory rehearsal per iteration would have prevented all findings. It does support keeping independent inspection, stronger proof and whole-change review while removing human authorization for routine repair.

### 4. Saved work can still be inaccessible, and runtime summaries can lie by omission

Raw worker logs for `01M422K1QSVNZT7QYZVEWK4GSC` repeatedly show GitHub rejecting checkpoint pushes because a Personal Access Token could not update `.github/workflows/continuous-delivery.yml` without `workflow` scope. The workflow continued. Accepted candidate work existed beyond the pushed branch.

The final event trace shows:

- Successful 19-test package execution.
- Successful focused LiveView and 85-test query/adapter checks.
- A started `PATH="$PWD/bin:$PATH" dev check` at **2026-10-04T05:51:31.973Z**, with no tool completion before the restart.
- A later terminated conclusion saying the server restarted before terminal state.

The [parent delivery conversation](@thread:thr_32d5pa6ndi) initially inferred the hang occurred in a trivial scenario gate, then explicitly corrected that after logs became available. The last durable checkpoint was not the last executed operation. The exact RAM-consuming process and host OOM evidence remain unavailable here; do not turn correlation with `dev check` into a proven memory root cause.

This corroborates the older [accessible-branch recovery gap](../kaizen/2026-05-29-resume-contract-gap-between-checkpoints-and-branches.md). A durable audit trail and a reconstructible candidate are different guarantees.

### 5. Publication and release are part of the workflow, not an epilogue

[066 run 01M3JPCGJBCG3NVGR5FTBK3MMG](https://fabro.home.wynne.family/runs/01M3JPCGJBCG3NVGR5FTBK3MMG) passed its ordinary full gate in 269.7 seconds. Publication created a new worktree and ran another full gate inside a 300-second node; it timed out before completing. Raw failures also contain PostgreSQL missing-file errors near the deadline, but their root cause remains unproved. The later timeout/diagnostic/cache fix is real and should not be presented as absent today.

The successful [066 recovery](https://fabro.home.wynne.family/runs/01M3K8Q59BVXWK2DDNW3FMZNJV) took 15.9 minutes and performed no new ordinary worker implementation. It proves guarded publication can work; it does not prove the original delivery was autonomous.

Git commit `e16727a5898efb24401c9830b2ce4a53df20c526` delivered 067 to main on October 5 through manual rescue. [CI run 37260894586](https://github.com/mattwynne/memba/actions/runs/37260894586) shows:

- `dev check`: success, 03:48:30–03:54:18 UTC.
- `deploy to Fly.io`: failure, 03:54:22–03:56:56 UTC.
- Deploy job `111608815192` logs: `Error: Can't resolve '../../../styles.css' in '/app/web/assets/css'`; production `mix assets.deploy` exited 1.
- Post-deploy invariant verification was skipped.

The same missing-style build error appears in [later October 5 run 37326080491](https://github.com/mattwynne/memba/actions/runs/37326080491). This is a release-packaging gap, not evidence that the test suite failed. A walking skeleton must exercise actual packaging/build/start as well as tests.

Current main `42982cfb9bacafc6b4f971b0701a1eee6e629335` has successful check **and deploy** in [run 37617178082](https://github.com/mattwynne/memba/actions/runs/37617178082): approximately 5m44s checking and 3m06s deployment. This is a useful current success control. It does not retroactively make 067's first deploy successful, nor demonstrate absence of human intervention.

Sources: [publish-timeout note](../kaizen/2026-09-28-publish-gate-times-out-in-fresh-worktree.md), [attestation concurrency note](../kaizen/2026-09-27-plan-validation-attestation-ref-push-rejected.md), [exact-checkout note](../kaizen/2026-09-12-dev-check-can-validate-the-wrong-checkout.md), [CI workflow](../../.github/workflows/continuous-delivery.yml), live GitHub jobs/logs.

## The existing BDD pilot: useful, not yet autonomous

Experimental branch: `experiment/goal-directed-bdd-delivery`, inspected at `3530f0ff9`. Read its README, rehearsal account, scenario gate and graph. These are not on main.

| Run | Result |
| --- | --- |
| [01M45DQEMEZR4RKFW9C3DV954H](https://fabro.home.wynne.family/runs/01M45DQEMEZR4RKFW9C3DV954H) | Stopped before the first shot: `max_visits=1` prevents visit one in the installed engine. |
| [01M45DWA57W39TZZPJTYS7KEN0](https://fabro.home.wynne.family/runs/01M45DWA57W39TZZPJTYS7KEN0) | OpenAI overloaded during `call_shot`. |
| [01M45DZW9SVESGQ8DBXYK8SV20](https://fabro.home.wynne.family/runs/01M45DZW9SVESGQ8DBXYK8SV20) | Correctly observed intended red; OpenAI overloaded during implementation. |
| [01M45EKSVMVZJF071CH3WCHVZV](https://fabro.home.wynne.family/runs/01M45EKSVMVZJF071CH3WCHVZV) | Manually prepared continuation switched to Anthropic; one example green, independent accept, final full gate green; no publication. |

The successful continuation took **25m22s/$6.55 API-equivalent**. The attempted sequence spanned roughly **42 minutes**, plus preparation, and includes another reported $0.59 from an interrupted attempt. The test driver had been copied from the delivered version into a historical pre-product checkpoint; it is not a blind replay of planning uncertainty.

Actual demonstrated scope: `Eve asks to join Board`, one domain example, five new focused tests, Messaging regression coverage, and a final gate with 1,578 web tests and five browser journeys. No whole-066 conformance or deployment. No real reject/repair path, multiple-example progression, browser WIP, or recovery after partially edited worker work was established by that successful run.

The prototype itself records that green/review provenance and reviewer non-mutation still need strengthening. Source inspection agrees: `after.json` is not a full candidate-bound trusted receipt; “trusted before” relies partly on checkpoint subject strings. These are not production authority boundaries. The wrong-prediction feedback added at `3530f0ff9` has fixture evidence, not a subsequent live run.

Reuse: real before-implementation observation, controlled scenario activation, exact selection checking, separate review and clear non-publication scope. Replace: hard-coded scenario, local mutable evidence as authority, model-message completion as recovery boundary, and an incomplete final release contract.

Durable branch sources: [README](https://github.com/mattwynne/memba/blob/3530f0ff9/.fabro/workflows/goal-directed-bdd/README.md), [rehearsal](https://github.com/mattwynne/memba/blob/3530f0ff9/.fabro/workflows/goal-directed-bdd/rehearsal-066.md), [gate](https://github.com/mattwynne/memba/blob/3530f0ff9/.fabro/workflows/goal-directed-bdd/scenario_gate.py).

## Active experiment: early evidence check, not a new decision

The sole ledger experiment is [the post-merge healer](../kaizen/2026-06-19-gemini-credit-exhaustion-breaks-review-workflow.md), approved September 21 and due October 19. Its earlier two-of-three quorum proposal was explicitly rejected. The approved change is one non-gating OpenAI reviewer with clean/heal/record/escalate outcomes.

Only two matching launched runs appear in the complete available Memba inventory:

- [01M33X1XFJMCBT6K62P5BXZDNG](https://fabro.home.wynne.family/runs/01M33X1XFJMCBT6K62P5BXZDNG), September 22: clean, succeeded, about 4.3 minutes.
- [01M3K9TBWNP778CVX3WQBRV6S4](https://fabro.home.wynne.family/runs/01M3K9TBWNP778CVX3WQBRV6S4), September 28: clean, succeeded, about 4.1 minutes.

**Early-review recommendation: Iterate by continuing observation under the existing contract through its existing date, not Adopt.** No implementation or contract adjustment is supported by two clean cases. This is before the due date, not authority to extend it. If the sample is still insufficient on October 19, seek approval for a bounded extension through the experiment-review process while preserving its five-run target and guardrails. No date/status change is made here.

No second operational experiment is launched or authorized by the replacement proposal. Its isolated historical predecessor is disclosed, not silently counted as the active healer experiment or as adoption evidence.

## Counterexamples, alternative explanations and ranking

1. **Selected: too many state/ownership handoffs, with operator-dependent recovery.** High confidence in the mechanisms: source plus independent raw run/CI/Git evidence. Highest strategic leverage because it explains both early protocol stops and late salvage. The new architecture's effectiveness is a hypothesis, not a demonstrated outcome.
2. **Product/architecture uncertainty entering delivery.** Very high leverage when present: [064's simpler rule](../kaizen/2026-09-23-bdd-discovery-did-not-challenge-costly-business-rule.md) removed the reason for much attempted architecture. A controller cannot choose that for Matt. Retain discovery, but do not add another permanent review ceremony as the default fix for every technical failure.
3. **Test truth, isolation and runtime resources.** Foundational safety constraint. Some historical failures already have controls; current [invitation timeout](../kaizen/2026-10-05-invitation-liveview-monitor-timeout.md) remains open. Fix specific proven defects; do not normalize arbitrary retries or infer the October OOM cause.
4. **Provider availability alone.** Recurs across providers, including the new pilot. Necessary bounded recovery behaviour, but top-ups/model routing alone would not fix schema, human-continuation, source, publication or release failures.
5. **Gate speed alone.** September's 17m49s local full-gate benchmark and 84% browser share are historical, not today's baseline. ADR 0026/browser reduction has since changed the workload; current CI is around six minutes. Removing duplicate gates and improving narrow feedback is justified; building browser sharding first would target an outdated dominant cost.

Disconfirming evidence:

- [01KXE3F0WV0J6NJX60AXBK8NZM](https://fabro.home.wynne.family/runs/01KXE3F0WV0J6NJX60AXBK8NZM), iteration 053, began from main and completed 22 implementation/validation visits and publication in about 459.7 minutes. The older graph could deliver substantial work. This rules out “multi-node workflows can never work”; it does not establish hands-off production or explain later failure concentration.
- [01M2HJ1M5Z1QAZR6Q42HNKQN86](https://fabro.home.wynne.family/runs/01M2HJ1M5Z1QAZR6Q42HNKQN86), iteration 063, succeeded in 23.7 minutes from `finish/063-quality-gate-20260914`, without ordinary implementation visits. Successful terminal status can describe a rescue tail.
- Genuine reviewer catches argue against deleting review. Genuine human clarification argues against a promise of zero legitimate questions.
- Many guard fixes are effective containment. The proposal removes their unnecessary task representations, not permission to publish without equivalent safety.
- The BDD replay is hindsight-assisted and narrower than an iteration. It cannot support a claim that the proposed replacement is already faster or reliable.
- Recent small facade slices reached successful deployment using BB and yx, but their parent conversation contains repeated human continuation/push approvals and resource recovery. That is useful evidence for coherent slicing, not proof that changing orchestration tools alone produces autonomy.

Evidence that would change the recommendation: representative present-workflow runs completing from initial approval through deploy without rescue; measured low handoff overhead; or a replacement controller requiring comparable protocol complexity to preserve safety. Such results should be retained, not excluded as inconvenient samples.

## Relevant note/source inventory

Core recent notes inspected in depth:

- [JIT planner](../kaizen/2026-09-14-just-in-time-delivery-planner.md), [test cost](../kaizen/2026-09-14-test-feedback-cost-outgrew-implementation-loop.md), and the later investigation sections of [timeouts/masked failures](../kaizen/2026-09-03-iteration-workflow-timeout-masks-test-failure.md).
- [Candidate stranded by timeout](../kaizen/2026-09-30-reviewed-candidate-stranded-by-worker-timeout.md), [adapter review churn](../kaizen/2026-10-03-adapter-review-churn-required-repeated-human-gates.md), [late BDD feedback and implemented WIP loop](../kaizen/2026-10-03-bdd-scenario-feedback-arrives-after-implementation.md).
- [Publication timeout](../kaizen/2026-09-28-publish-gate-times-out-in-fresh-worktree.md), [notes-ref contention](../kaizen/2026-09-27-plan-validation-attestation-ref-push-rejected.md), [run pointers block delivery](../kaizen/2026-09-29-deliver-blocked-by-its-own-run-id-pointers.md).
- [Postgres/unchecked publication](../kaizen/2026-09-20-postgres-validation-failure-did-not-block-merge.md), [terminal-success semantics and run-branch history](../kaizen/2026-09-04-implementation-workflow-terminal-success-gate.md), [false-green composite gate](../kaizen/2026-09-05-dev-ci-masked-precommit-failure.md).
- [Scope simplification](../kaizen/2026-09-23-bdd-discovery-did-not-challenge-costly-business-rule.md), [unresolved merged scenarios](../kaizen/2026-09-26-unresolved-scenarios-in-merged-iteration.md), [implicit ADR triage](../kaizen/2026-09-29-technical-planning-adr-triage-was-implicit.md), [invitation monitor timeout](../kaizen/2026-10-05-invitation-liveview-monitor-timeout.md).
- [Active healer experiment/history](../kaizen/2026-06-19-gemini-credit-exhaustion-breaks-review-workflow.md) and [prior retrospective](2026-09-21-software-factory-retrospective.md).

Historical recurrence and control evidence:

- [Simplify task ownership](../kaizen/2026-05-28-simplify-iteration-task-loop.md), [blind validator/destructive reset](../kaizen/2026-05-28-blind-validator-false-reset.md), [resumability](../kaizen/2026-05-28-resumable-iteration-implementation.md), [accessible branch gap](../kaizen/2026-05-29-resume-contract-gap-between-checkpoints-and-branches.md).
- [Simplify delivery orchestration](../kaizen/2026-05-30-simplify-fabro-delivery-orchestration.md), [publish rescue and feature permissions](../kaizen/2026-05-30-fabro-run-rescue-after-publish-failure.md), [premature merged state and zombie runs](../kaizen/2026-06-01-fabro-iteration-016-premature-merge-and-zombie-runs.md), [provider loop/control-plane starvation](../kaizen/2026-06-03-fabro-rate-limit-loop-wedges-server.md).
- [Unchecked tasks misrouted](../kaizen/2026-06-18-implementation-task-list-check-routes-unchecked-tasks-to-human-failure.md), [coarse task timeout](../kaizen/2026-06-23-coarse-fabro-todos-timeout.md), [client stream versus remote state](../kaizen/2026-06-23-fabro-deliver-stream-timeout-ambiguous.md), [manual domain coverage](../kaizen/2026-06-04-domain-cucumber-coverage-is-manual-and-incomplete.md).

Design grounding: [BDD automation](../../.pi/skills/bdd-automation/SKILL.md), [GOOS reading notes and primary references](../../.pi/skills/bdd-automation/references/freeman-pryce-goos-acceptance-tdd.md), [BDD discovery](../../.pi/skills/bdd-discovery/SKILL.md), [ADR 0026](../adr/0026-keep-browser-journeys-distinct-from-domain-examples.md), current workflow source and the experimental branch. No claim of a new external literature survey or full-book reading.

## Remaining evidence gaps

- No full 90-day, per-approval intervention/deployment denominator; metadata success cannot substitute for it.
- October 4 Fabro-host process/OOM provenance and September 28 PostgreSQL missing-file cause are unproved.
- Some server-restart conclusions lose summary usage/duration. Do not use their zeros as measurements.
- Current CI success establishes tested/deployed revision through jobs, not every user-visible production path or every external-provider smoke.
- The prototype lacks production publication, partial-edit restart and representative live rejection/rework evidence.
- Neither the old planner fixtures nor the prototype's schema/graph tests prove model judgment or long-run reliability.
- No proof yet that the proposed tiny controller/executor boundary works; Milestone A deliberately makes that its first acceptance criterion.
- No model billing/context telemetry for this investigation was collected. No child-agent usage occurred. Investigation and proposal preparation took approximately 27 elapsed minutes. Tool retrieval/analysis was bounded rather than an exhaustive manual reading of all raw payloads.

## Recent implementation attempt inventory

The table below is derived from the complete server summary inventory, filtered to Memba `iteration-implementation` created on/after September 21. Status is the server's current terminal status. Failure categories come from inspect/events, not inferred product correctness. `terminated` rows have unreliable zeroed summary timings.

| Created (UTC) | Run ID | Status / decisive boundary |
| --- | --- | --- |
| Sep 21 08:15 | `01M31GJ78JTZ33EWHC63DAP0H1` | Failed: sandbox preflight |
| Sep 21 08:27 | `01M31H7R4PN1376BT74FXTCGRA` | Failed: sandbox preflight |
| Sep 21 08:51 | `01M31JM9ZVM712QA6MZGKB9FTN` | Failed: sandbox preflight |
| Sep 21 09:18 | `01M31M4Y7HZEVT1K9YF5M6M5C3` | Failed: sandbox preflight |
| Sep 21 09:27 | `01M31MMTC933VWZK6KB6Y4E1TW` | Failed: sandbox preflight |
| Sep 21 09:32 | `01M31MYF9D1KRSY7ZW84CSYF33` | Failed: sandbox preflight |
| Sep 21 09:36 | `01M31N56BYNXBHYJ5ZPNW57C96` | Failed: sandbox preflight |
| Sep 21 10:05 | `01M31PTGSA3ZXZ7S2V4B6A6Q00` | Failed: ready-for-review record includes nonpassing validation |
| Sep 21 10:42 | `01M31RZ6Z1Y1E3W5EK3YKGN8VW` | Failed: planner source-baseline guard |
| Sep 21 13:52 | `01M323T4NNPBS668AMPBWEPPS3` | Failed: iteration-wide revision visit limit |
| Sep 21 16:28 | `01M32CS1V82BB8NKYPWHVM7ZV5` | Failed: iteration-wide revision visit limit |
| Sep 22 02:08 | `01M33DXKV7MD3NVR2BC51JXA3T` | Cancelled |
| Sep 22 07:02 | `01M33YR130B147ZZVAN2ANYC7E` | Failed: iteration-wide revision visit limit |
| Sep 27 16:08 | `01M3HSZ69HTJN82FD03JR94BVV` | Failed: iteration-wide revision visit limit |
| Sep 28 00:23 | `01M3JP9MV0Q5VC61E3A70JH1EF` | Failed: missing expected source HEAD input |
| Sep 28 00:24 | `01M3JPCGJBCG3NVGR5FTBK3MMG` | Failed: cold publish-candidate validation timeout |
| Sep 28 05:45 | `01M3K8Q59BVXWK2DDNW3FMZNJV` | Succeeded: 066 final-publish recovery |
| Sep 30 00:12 | `01M3QTFPMN3D56FENQ172YE40K` | Failed: planner reference schema |
| Sep 30 01:57 | `01M3R0GGQHYQH093N9J0JG543V` | Failed: deliberate stop after human clarification |
| Sep 30 05:29 | `01M3RCMKB0QE3KXT99PMFV8E8B` | Failed: worker timeout before independent review |
| Oct 3 03:58 | `01M3ZYMEWK654QQZZP3Y8PQ1R1` | Failed: deliberate stop after policy clarification |
| Oct 3 17:09 | `01M41BW0XN9S1VPCTQRXPMB79T` | Failed: planner obligation status |
| Oct 3 17:38 | `01M41DJ0E4FYMRSH13KGBRRWKR` | Failed: deliberate stop after technical repair guidance |
| Oct 3 19:02 | `01M41JBGVZ7CRH93KA4VT0T6QJ` | Failed: deliberate stop after technical repair guidance |
| Oct 3 20:46 | `01M41R98D29R3GZC8SGJDKKF7B` | Failed: deliberate stop after technical repair guidance |
| Oct 3 21:47 | `01M41VRF1P0DX6B2DWWAKEBRS3` | Terminated: server restart; substantive review evidence retained |
| Oct 3 22:43 | `01M41YZDCWG8JP1ATXNYGF3DZZ` | Terminated: server restart; substantive review evidence retained |
| Oct 3 23:15 | `01M420SF25N0DZ0T965G9E4EDC` | Terminated: server restart; substantive review evidence retained |
| Oct 3 23:46 | `01M422K1QSVNZT7QYZVEWK4GSC` | Terminated: final full-check tool call has no completion; later manual rescue |

The first seven rows' truncated preflight output contains dependency/setup diagnostics, but does not establish one common root cause; they are classified at the failing boundary only. Some raw `stage.failed` events are intentional routing (for example, the old all-tasks-done command exits 1 when complete). Counts above use terminal run status, not a naive count of failed-stage events.
