# Unattended delivery: replace the task factory with a small developer loop

Date: 2026-10-09

Status: **October 10: isolated skeleton implementation authorized; replacement not adopted or rolled out.**

Evidence: [investigation, run inventory and limitations](2026-10-09-unattended-delivery-evidence.md).

## Recommendation

**Stop orchestrating implementation tasks. Orchestrate the acquisition of evidence for a small, approved outcome.**

Use one builder, one independent reviewer, and a small deterministic delivery controller. The builder works outside-in from an executable example, using unit-test red/green/refactor cycles inside it. Ordinary diagnosis and repair stay inside that development loop. The controller preserves work, runs authoritative checks, enforces budgets, and publishes an immutable candidate. Neither a successful agent response nor a completed graph means delivery succeeded.

This is a replacement architecture, not another gate on the existing planner/packet/todo workflow. Develop it separately. Reuse the useful parts of the existing `goal-directed-bdd` prototype, but **do not promote that prototype to production by adding a publish node**.

The essential simplification is three separations:

1. **People decide the destination; tests guide the route.** An implementation task list is not a second specification.
2. **A saved candidate is not an accepted candidate.** Interruptions may delay progress without destroying it or manufacturing approval.
3. **Thinking and delivery are different machines.** An agent explores; a deterministic controller owns externally consequential transitions.

The objective is quality-preserving, approval-to-production completion without Matt operating the machinery. Safe blocking remains necessary when the contract is genuinely undecidable or dependencies remain unavailable. It counts as a non-completion, not a cleverly redefined success.

## Why a replacement is justified

The recent evidence is not simply “the model needs more time.”

| Observed failure | Architectural lesson |
| --- | --- |
| 067 preparation spent eleven minutes producing a `references` shape rejected before coding; a later continuation failed on `prepared_revision`. | We are asking a model to maintain a distributed task-management protocol before it can do useful development. Remove the protocol, not its fail-closed protection. |
| One 067 run spent approximately 50 minutes planning, 52 implementing/revising, and 40 reviewing. | A separate planner is not free preparation. Here it cost almost another implementation pass. |
| Task 006 saved a review-ready claim and passing focused evidence, then timed out during its final response. Review never started. | Useful work should not depend on a model finishing its closing prose before a timer. |
| Four recorded “repair as planned” discussions consumed about 102 minutes of waiting and ended in deliberate terminal stops. | We have implemented human-operated continuation, not unattended repair. One separate invalid-event decision really did need Matt. |
| 008A required nine revisions; reviews caught production-interest and impossible-fixture gaps despite green tests. | Removing independent scrutiny would remove a protection that demonstrably mattered. Improve executable proof, not merely the pass rate. |
| 066 passed its full gate, then repeated it in a cold publication worktree under a shorter timeout and failed. | Prepare the publishable candidate **before** its authoritative full check. |
| 067 continued after checkpoint pushes were rejected for missing GitHub `workflow` scope. The later final check was interrupted by a server failure. | Local checkpoints are not durable recovery. Publication capability and checkpoint persistence must be real, not best-effort assumptions. |
| 067 eventually merged through manual rescue, then its initial Fly deployment failed after CI tests passed: the production asset build could not resolve `../../../styles.css`. | Merge, test success, release packaging and production delivery are distinct facts. |

From September 21 onward, the retained Memba implementation summaries contain **29 runs: 28 failed and one succeeded**. The success was 066's final-publish recovery. These are attempts, not 29 independent deliveries; some failures are deliberate clarification stops. Nevertheless, the evidence directly contradicts hands-off completion. See the evidence report before interpreting the denominator or costs.

The older history matters too: May already contains “simplify task loop,” “make resumable,” and “simplify orchestration” fixes. Each solved a real local problem. We must not repeat the cycle by calling a shorter graph simple while retaining multiple authorities for task identity, acceptance, recovery and completion.

## The new normal path

```text
Agree a small outcome and its examples
                  │
                  ▼
       Admit an immutable contract
                  │
                  ▼
      Develop one example at a time ◄──── bounded technical repair
      @wip → observe → unit TDD → green                 ▲
                  │                                    │
                  ▼                                    │
       Independent review of green change ─────────────┘
                  │
           More obligations? ───────► Develop
                  │ no
                  ▼
     Assemble final candidate → whole-change review
                  │
                  ▼
        Exact-candidate full check
                  │
                  ▼
       Publish → observe deploy and smoke
                  │
                  ▼
                Delivered
```

An infrastructure interruption does not introduce a new product workflow. The controller waits or resumes the same job from durable evidence. A genuine decision produces a precise blocked result with preserved work. Neither route silently changes the contract.

### What disappears

- Mechanical conversion of prose implementation steps into mandatory todos.
- A separate delivery-planner model visit before every worker/revision.
- Worker packets, accepted-task lineage, and synchronized `todo.md`/execution-state representations.
- Per-task check-off as a proxy for implemented behaviour.
- A reviewer after every deliberately intermediate red increment.
- Separate model calls merely to predict a failure, relay a finding, reflect on “repair as planned,” or announce success.
- Iteration-wide graph-visit limits standing in for meaningful resource/progress budgets.
- “Repair as planned” approval gates and terminal stops after ordinary technical feedback.
- A pre-publication full gate followed by another full gate merely because publication constructs a different commit.
- Product-branch commits just to acquire/release a workflow WIP slot.

### What stays

- Agreed behaviour, binding ADRs, explicit exclusions and scope-change approval.
- Small changes, focused tests, one active example, independent review.
- Correct-checkout and exact-candidate verification.
- Real test execution, complete exit-status propagation, coverage accounting and generated-file hygiene.
- Preserved unaccepted work, bounded spending, single-writer execution and safe cancellation.
- Full `dev check` before product publication; no red example or unresolved blocker can publish.
- Existing post-merge `code-review` remains a separate non-gating healer.

These are policies to preserve, not a requirement to transplant their current task-specific scripts unchanged.

## 1. Planning supplies a destination, not a program

The input is an approved, versioned contract with:

- The smallest useful outcome and why it matters.
- Agreed examples, identified unambiguously, and their proving boundaries.
- Necessary technical obligations: for example compatibility, query isolation, package independence, migration/replay safety or rollout constraints.
- Binding decisions, permitted feature changes, exclusions, and decisions reserved for Matt.
- The publication/deployment authority granted at dispatch, plus resource and retry limits.

This is a short index into existing examples/ADRs, not another elaborate document. Derive scenario identities from the feature AST; do not copy their wording into a competing specification. Outline example rows need explicit identities and selection counts.

Do not require a new readiness committee or a complete simulated implementation for every iteration. During planning, ask: **“What evidence would tell us this outcome exists, and what decision would prevent us implementing it?”** Probe temporal, negative and boundary cases. If a rule creates disproportionate machinery, return to the desired outcome before designing that machinery. Iteration 064's follow-preference simplification is the strongest example of this leverage.

Reconnaissance can locate existing drivers, fixtures and public seams. It should leave a short list of useful references, not instructions for every future edit. If neither the behaviour nor an observable proof is understood, commission a bounded learning spike rather than label the work autonomously deliverable.

Admission is mechanical where possible: authorized contract revision, valid example selection, appropriate runner, source identity, environment readiness, checkpoint storage, permitted credentials and a free single-writer slot. A known-broken baseline is a blocker, not an invitation to mix unrelated repair into the job.

**No arbitrary task-count/file-count rule.** Slice by a coherent outcome and its proof. Several examples can share setup and one reviewable change; unrelated outcomes should not share a giant packet. An independently deployable slice is preferable. Do not partially release an iteration unless those release boundaries were approved in advance.

## 2. BDD is the outer loop; TDD is the inner loop

Matt's earlier requirement remains explicit: select an agreed scenario, mark it `@wip`, run it before implementing its behaviour, and implement only what makes it pass, including supporting unit tests.

### One active example

1. Select the next approved example at the boundary that can actually observe its risk. Activate only that example; account for inherited tags and outline rows.
2. Record the expected failure **before** running it. The prediction and the observation are append-only evidence, not a model's retrospective story.
3. Run it through a trusted test runner. Verify the selection, execution completion and actual failure.
4. Read the actual failure and diagnose the current obstacle. Make the smallest meaningful change needed to overcome it, using fast failing unit/application/LiveView tests, minimal implementation, and refactoring.
5. **Rerun the same whole acceptance scenario after overcoming that obstacle.** Its next failure determines the next move: repeat observation → diagnosis → unit TDD/refactor → acceptance rerun until green. Do not implement the whole feature between acceptance runs or execute Gherkin steps artificially in isolation. Keep regression checks green; deliberately red work remains on the private candidate branch.
6. Once the example is green, run the coherent focused regression set and submit the changed boundary for independent review.
7. After acceptance, remove `@wip`, retain normal executable coverage and select the next example. Tag changes create a new candidate; they do not inherit an exact-SHA final attestation.

**Do not turn every red→red step into a planner/worker/reviewer exchange.** Those steps are ordinary development. Save them cheaply; review a meaningful green outcome. Where several examples already became green together, observe and account for each, then review the coherent change once rather than pay an identical review per row.

### Technical obligations remain first-class

Matt confirmed that scenarios cover much, but not all, of an iteration. Maintain one small approved obligation list in the contract, with a proving method for every obligation—not a second detailed implementation plan:

| Obligation | Driving feedback and completion proof |
| --- | --- |
| Behavioural example | The scenario-driven acceptance loop above |
| Package independence | Dependency or architecture check |
| Behaviour-preserving refactor | Green characterization/regression tests plus proof of the intended structural change |
| Release packaging | Build and start the actual production image |
| Migration compatibility | Migration/replay tests against representative old state |
| Documentation | Explicit completeness criterion and independent inspection |

For technical work, identify the missing proof, make the smallest relevant change and rerun that proof. Do not invent Gherkin or deliberately break working behaviour to manufacture a red. Technical obligations stay outstanding until their evidence is accepted; passing all scenarios alone cannot complete delivery.

The builder may discover and organize implementation prerequisites just in time, nested under the obligation they enable, optionally using yx. Those tasks are working notes, not acceptance authority. A prerequisite cannot authorize a new product outcome or consequential architecture decision. The simplification is **not “no tasks”; it is no competing task bureaucracy defining done**.

### Predictions are learning, not passwords

“Call your shot” is valuable. A guessed exception substring is not proof of understanding.

- A surprising failure triggers diagnosis and a new recorded prediction before rerunning. Preserve the first observation. Do not continue implementing the original guess blindly.
- A missing step, zero selected tests, compilation/setup error or infrastructure failure is not behavioural red. Test-driver work can happen first, within approved scope and without changing the product; then establish the real baseline.
- Unexpected green is information. Verify that the example observes the intended boundary and that assertions are meaningful. Record already-satisfied behaviour; do not break working code to manufacture a red or use green to authorize unrelated work.
- A refactoring/technical job uses characterization, invariants and structural proof. It must not invent a failing customer scenario solely to satisfy the workflow.
- A second changed error message is not automatically progress. The reviewer checks the actual behavioural obstacle removed and the quality of the tests.

Keep the prediction and diagnosis in the builder's small working session. Do not require a separate planning agent or an exact-diagnostic-matching graph branch for every learning step. Changing the prototype's strict matching policy requires approval and tests; this document does not silently change it.

### Listen to awkward tests

Use fast acceptance examples at domain/application boundaries for rules, targeted Phoenix tests for web responsibilities, and a few actual browser journeys for browser risks, consistent with ADR 0026. Never substitute a domain pass for connected UI navigation or cross-host proof.

008A shows why output assertions alone are insufficient: “nothing relevant changed” needs observable non-refreshes, not merely unchanged rendered state. Use real public builders and production-derived relationships where fixture invariants matter. Fakes belong at intentional ports; do not mock away the action or observation being proved.

A harness that cannot isolate a scenario, distinguish no selection from green, or synchronize on completion is unfinished factory infrastructure. Fix that boundary rather than teaching agents longer incantations. New flaky assertions remain failures until explained; unattended operation must not mean retrying arbitrary tests until a lucky green.

## 3. One builder, one reviewer, no task broker

### Builder

The builder can inspect and change its isolated candidate, write tests and run focused checks. It cannot change the approved contract, grant itself new permissions, mark acceptance, publish to main, or change the controller's policy.

Give it the active example, relevant constraints, a small orientation note, the current diff and concrete outstanding findings—not all prior stage transcripts. Retain context within a coherent example; start a fresh session at a natural boundary using source and durable observations. Do not make context compaction a prerequisite for success.

This is not a return to the giant worker that struggled in iteration 062. The input is an executable narrow outcome, not a dual-layer acceptance project plus architecture discovery and a full gate. A bounded reconnaissance checkpoint may be appropriate, but there is no second agent rewriting the work contract before every edit.

Use soft yield points before the executor's hard deadline. A worker may save partial work without claiming completion. A deadline never grants acceptance; a saved candidate is re-observed before further work or review.

### Reviewer

The reviewer uses a separate session and a read-only snapshot of the candidate. It examines code, test meaning, scope, negative cases and the actual runner receipts. It can request a targeted reproduction or run it in a separately isolated test environment. Its verdict is bound to that candidate and contract revision. It cannot silently edit the implementation it is accepting.

Feedback has three outcomes:

- **Accept:** the coherent outcome and its required proof are sound.
- **Repair:** a concrete violation of the existing contract, preferably with a reproducer or precise missing proof. Return directly to the builder, without Matt's permission.
- **Decision needed:** two plausible interpretations, a consequential architectural/product choice, unsafe expansion, or insufficient authority. Name the question and why existing evidence cannot decide it.

Non-blocking taste and future improvements are recorded, not used to extend the approved scope. Do not resolve disagreement by majority vote, model shopping or repeated requests until a reviewer accepts. A disputed finding gets one evidence-led clarification within budget; unresolved consequential disagreement blocks.

Track outstanding findings across repair attempts. A renamed task or a restarted provider cannot reset their history. Distinguish a new repairable finding from the same reproducible defect persisting after attempted fixes. Both consume the same job budget; persistent non-progress eventually blocks.

At completion the same reviewer role performs a whole-change pass for interactions and non-scenario obligations. This is not an additional panel. It catches the kind of reply-delivery regression found during 067's final rescue. A failed final full check goes back through the same repair/review process, not a special unreviewed polish path.

## 4. Durability makes interruption ordinary

### A small deterministic controller is the authority

Use one single-writer controller on durable storage, supervised by the host service manager. It owns the delivery job; agent sessions and Fabro runs are replaceable **attempts** within that job. Initially reuse Fabro for bounded sandbox/agent execution where its API supports the required contract, not as the owner of a fifty-node delivery transaction.

The first implementation milestone must establish this executor contract with crash tests. If the installed Fabro cannot cancel/fence work, preserve candidates and launch bounded replacement attempts reliably, use a directly supervised supported agent runner instead. **Do not build a chain of Fabro recovery workarounds to protect that choice.** Provider/runner wiring is replaceable; the delivery semantics are not. This is an explicit proof-dependent implementation choice, not a claim that the present Fabro API already provides these guarantees.

Keep only three authoritative kinds of information:

1. **Contract:** immutable approved scope, examples, constraints and authority.
2. **Candidate:** content-addressed source checkpoints, including unaccepted work.
3. **Evidence:** controller-written observations, review decisions and external-effect receipts bound to contract/candidate identities.

A single durable job record references them and records the active attempt, cumulative budget, phase and next action. Human status pages, Markdown checklists and optional yaks are views—not competing lifecycle stores. Do not store a second mutable execution plan in the product checkout. Ordinary atomic local persistence and a single writer suffice initially; this does not need a distributed event platform.

Before starting another unit of work, verify the candidate is recoverable from durable storage independent of the disposable worker. If checkpoint persistence fails, stop advancing. Do not accumulate another hour of locally “accepted” work behind a rejected Git push.

### The controller reconciles facts after every restart

It asks what evidence is missing for the current candidate, not which graph node last returned success.

| Interruption | Required continuation |
| --- | --- |
| Worker dies after editing, before its final message | Stop/fence its process tree; preserve its changed candidate as unaccepted; rerun the relevant observation; continue or review from that source. Never infer acceptance from a worker-result file. |
| Checkpoint write/push fails | Preserve local evidence, retry the same persistence action within budget; do not advance acceptance or dispatch a successor that cannot recover it. |
| Reviewer is interrupted | Keep the green candidate; rerun only the missing review. |
| Controller restarts after acceptance | Reconstruct acceptance from the candidate-bound receipt; do not reimplement the example. |
| A late old worker returns | Reject its result using attempt identity; it has no authority over the current candidate or phase. |
| Provider returns a transient failure | Back off durably without holding a model loop; retry the same pending operation within the remaining budget. |
| Billing/auth failure | Do not spin. Use at most an explicitly approved available fallback route, otherwise record an infrastructure block. Never broaden credentials automatically. |
| Test infrastructure dies | Terminate owned children, recreate isolated test resources and rerun the uncompleted check within the infrastructure budget. Its partial output is never a pass. |
| Push succeeds but the response is lost | Query the remote ref and candidate identity; record publication if proven. Never rerun implementation or create another publication blindly. |
| Deployment observation is interrupted | Reconcile the deployment/run/revision identity; resume observation or a documented idempotent deploy operation, not the development loop. |

A durable wake-up must exist outside the assistant conversation. “I will check later” is not unattended operation. The controller's service restart and pending-retry scheduling are part of the tested design.

### Budgets and failure states

Use elapsed active work, deadline, resource limits and cumulative usage—not graph-visit counts. Budgets belong to the stable delivery ID and survive all restarts/fallbacks. Track waiting separately so provider backoff does not appear as coding time, but still bound the overall delivery deadline.

Before each canary, approve concrete caps from measured cold-test and worker costs. The October 5 pilot's roughly 15-minute worker and 5.6-minute final gate are useful observations, not universal limits. Reserve enough budget for review and full validation instead of letting coding consume it all.

The explicit outcomes are **delivered**, **waiting for a bounded retry**, **blocked with a decision/infrastructure diagnosis**, or **cancelled**. A human block is truthful and safe but still fails the hands-off-completion metric. Permanent outages and undiscovered business decisions cannot be made to disappear by an elegant loop.

### Environment and authority

One job owns its workspace, database/event store, ports and child process group. One component starts and stops them. No nested acceptance helper may destroy a parent-owned database. Warm dependencies can be reused; mutable test state must be isolated/reset under that owner. Cancellation waits for owned processes to stop before deleting their files.

Keep the controller and durable log storage outside the worker's memory/resource limit. Do not let an expensive test or provider loop starve the control plane. Capture memory/exit/process diagnostics without credentials. The October 4 RAM-consuming process remains unidentified; containment is justified, a specific OOM fix is not.

Give product editing, focused testing and publication separate capabilities. Worker/reviewer containers must not inherit production secrets, main-push credentials or the publisher's control socket. Controller/publisher code and policy are trusted inputs, not whatever the candidate branch edits. Explicitly decide how to support authorized changes to GitHub Actions files before dispatch; do not discover missing scope after accepted work exists.

This does not itself establish repository-wide branch protection. Humans or unrelated automation with direct main-push rights remain outside the controller's guarantee. Changing that policy requires Matt's decision.

## 5. Prepare once, prove the final artifact, then publish

Retain trunk-based publication unless Matt changes that decision. Do not introduce mandatory PR ceremony merely to implement this proposal.

1. Acquire the serialized publication lane and fetch current main.
2. Construct the final candidate, including integration/rebase, approved tag cleanup, lifecycle metadata and intended commit structure. Preserve the worker checkpoint branch; never rewrite its ancestry to squash it.
3. Independently review the final combined diff and whole-contract obligations. If repairs change it, produce a new candidate and invalidate affected evidence.
4. In the prepared validation workspace run **one workflow-owned full `dev check` for that exact final candidate**. Record source identity, runner/policy identity, environment, command, selected suites and successful exit. Keep logs outside the candidate tree. A timeout or dirty candidate cannot receive an attestation.
5. Build and smoke-start the actual release package/image from that candidate before publication; record its digest. `dev check` alone did not catch 067's missing production CSS input. Promote the tested image rather than first discovering packaging failures in production deployment. Preserve the current source-backed release invariants. Publish the attestation using the existing concurrency-safe policy, then a normal fast-forward update of main. No code or metadata mutation is allowed between final validation and push.
6. If main advances incompatibly with that candidate, rebuild/review the integrated candidate and revalidate. A new SHA is not covered by the old result. Do not force-push or silently rebase after checking.
7. Reconcile the exact CI/deployment result and required safe smoke checks for the published revision. Record delivered only after that evidence exists. If another revision supersedes it, record the relationship explicitly; an unrelated green deploy is not proof of this candidate's release.

“One full check” means one authoritative check in this new publication path per unchanged candidate, **not** deleting focused TDD tests or claiming GitHub's independent CI has disappeared. Keep the current CI deploy gate initially. Any later deduplication across trusted systems needs its own equivalent-attestation proof.

A deployment failure after merge remains **published, not delivered**, with a bounded recovery policy. Do not rerun coding just because Fly is unavailable. Do not automatically roll back schema/data changes unless rollback compatibility and authority were explicitly approved. The first rollout should avoid irreversible migrations and external side effects.

Docs-only operational status should not trigger a product full suite. In-progress/blocked status belongs in the job record; product `merged` metadata may be included in the final checked candidate. The independently observed deployed state cannot truthfully be prewritten into that commit.

## 6. Use yx as a map, not a second workflow engine

I inspected the installed `yx 0.3.0` and the existing facade-retirement tree. Its nesting is a useful way to expose prerequisites and real blockers. It also visibly refuses to pretend uncovered acceptance action probes are safe work.

Use yx for the human-facing implementation backlog **after approval**, with prerequisites nested under the outcome they enable. Do not make `yx done` mean tests passed, review accepted, main advanced or production deployed. Those facts need source-bound receipts. Do not have the agent synchronize yx, Markdown todos and a JSON execution-state file on every cycle.

For this proposal a document is sufficient; I have not added another live yak tree or modified the existing refactor map. If we later expose delivery status through yx, derive it one-way from the controller rather than create another authority.

## 7. Build the replacement with BDD/TDD, starting at the dangerous end

**First build a walking skeleton that survives interruption and delivers a trivial change to a non-production target. Then add intelligence.** A polished coding demo with publication omitted is the wrong first proof for an unattended delivery system.

### Milestone A — deterministic walking skeleton

Use a disposable repository/remote, isolated service resources, scripted builder/reviewer doubles and a fake deploy endpoint. Build admission → saved candidate → accepted evidence → exact check → publication → deployed receipt.

Drive the controller through public interfaces with acceptance tests; unit-test its transition decisions. Inject termination before/after each durable write and external effect. Prove restart, single ownership, refusal of stale receipts, finite retries and no duplicate publication. First determine whether the selected executor can satisfy the recovery contract; change executor rather than expand the product workflow if it cannot.

**Exit:** repeated process/service restarts recover automatically with no lost accepted work, false success or duplicated external effect. No production credentials or effects are available.

### Milestone B — real outside-in development

Reuse the useful runner/selection work from the experimental branch, replacing hard-coded scenario names and checkpoint-subject trust with explicit identities and controller-owned receipts. Generalize selection to an approved manifest, real outline rows and appropriate domain/browser runners.

Add one real builder and the independent read-only reviewer. Prove meaningful red→green, unit-test/refactoring work, already-green behaviour, driver-first setup and wrong-prediction learning. Exercise a real review rejection and repair, not only supplied dispositions.

**Exit:** several examples complete in one job, review can reject without Matt's intervention, and an interrupted partially edited candidate resumes without redoing accepted examples.

### Milestone C — sealed candidate and end-to-end release

Extract the useful source, feature-change, generated-artifact and publication policies from current helpers. Do not import todo/packet dependencies. Prepare the final artifact before full validation and bind review/check receipts to it. Add production-image build/start proof, then promote that immutable image through the release path; this requires an explicit change to today's build-during-deploy path. Exercise real cold/warm test environments under resource limits and the non-production deploy observer. Production smoke effects must be explicitly authorized and confined to controlled test identities.

**Exit:** changed main, lost push acknowledgment, checkpoint push rejection, cold gate timeout, database teardown and deploy failure all take the expected recovery path. No failure can publish unchecked code or claim production delivery.

### Milestone D — representative evidence, not one rehearsed happy path

Run isolated historical replays and fresh non-production canaries:

- Original 066's **whole bounded outcome**, including its second example/outline, actual browser journey and final conformance—not just “Eve asks.”
- A coherent 067-style dependency slice with production-derived fixture relationships and positive/negative isolation proof. Seed a genuine defect the reviewer must reject.
- A behaviour-preserving refactor whose customer examples start green.
- A deliberately ambiguous contract that must stop with a useful question.
- A fresh small slice not selected because its implementation is already known.

Record every preparation step, failed start, retry, provider switch and manual edit. If preparing the replay copies the delivered test driver, name that hindsight advantage. Compare equivalent scope against the old workflow; do not compare one scenario with an entire iteration.

**Exit:** safety fixtures pass, representative jobs complete unattended, and the measured costs justify the change. Historical success alone cannot establish prospective effectiveness.

### Milestone E — opt-in rollout and deletion

After explicit approval, admit a small, reversible production slice with one stable delivery ID and bounded cost/deadline. Retain the old workflow as a fallback **choice before dispatch**, not a second concurrent owner or an automatic mid-job escape hatch. Expand only with evidence. If adopted, retire the old task broker, packet/todo protocol, associated prompts and duplicate final gates; leaving both canonical indefinitely would forfeit the simplification.

Do not retrofit accepted 067 checkpoints into the new acceptance representation or restart old runs as part of building this system.

## Acceptance tests for the factory itself

These are proposed behaviour examples for agreement, not claims about implemented coverage.

| Example | What must be proved |
| --- | --- |
| A user dispatches the same approved job twice | Only one owner changes the candidate; the second request finds the existing job. |
| An example has zero selected tests, undefined steps or the wrong boundary | No behavioural pass and no publication; harness diagnosis is explicit. |
| The prediction is wrong | Original evidence survives; diagnosis precedes another prediction/run; no blind implementation. |
| An example is already satisfied | Coverage is checked without intentionally breaking the product. |
| The worker dies after a useful edit | The preserved candidate remains unaccepted and is safely re-observed; prior acceptance is not lost. |
| The reviewer finds unrelated-query refreshes despite green output tests | The builder adds/fixes relevant proof and code; the reviewer rechecks without a human “repair” approval. |
| The reviewer changes a file or returns a verdict for an older candidate | Acceptance is rejected. |
| A feature assertion is weakened or a pending example hidden with a tag | Whole-contract completion fails. |
| A provider overloads, then recovers | Backoff/resume occurs without a tight loop or manual provider switch. |
| A provider is permanently unauthorized | The job respects its approved fallback policy or blocks; it does not grant credentials or retry forever. |
| A checkpoint cannot be persisted | No subsequent accepted work relies on that non-durable checkpoint. |
| Tests pass but their parent command is interrupted | No complete gate receipt is written. |
| The final source changes after a passing check | Publication refuses the stale attestation. |
| Main moves or the push acknowledgment is lost | Reconcile actual remote identity; recheck a new integrated candidate; never duplicate or force publication. |
| Tests pass but the production image omits a required asset | Packaging fails before publication/deployment; a test-suite pass cannot stand in for a runnable release. |
| A deploy fails after merge | Status remains published/not-delivered; development is not repeated and success is not announced. |
| A genuine policy choice or irreducible no-progress loop appears | One actionable block, preserved work and spent-budget history—not a restart invitation disguised as failure. |

Use fault injection and temporary Git remotes, not only assertions that prompts mention these rules. At least one test must kill the actual coordinator process and let its real supervisor recover it. Scripted agent fixtures prove routing; live seeded-defect reviews are needed to evaluate judgment.

## How we decide whether it is trustworthy

Primary outcome: **hands-off production completion rate** = approved admitted jobs that reach verified production within their declared budget/deadline, with no manual restart, edit, provider switch or continuation, divided by **all** admitted jobs. Count infrastructure blocks, abandoned attempts and decision blocks. Report pre-admission rejection rate and reasons alongside it to prevent gaming admission.

Secondary measures: approval-to-production elapsed time; human interventions by cause; model/runner/test cost including failures and preparation; time spent building versus planning/reviewing/testing; and escaped defects/rollbacks. API-equivalent dollar estimates are not invoices. Never treat missing usage as zero.

Safety/reliability invariants are non-negotiable: no unapproved scope change, weakened proof, lost accepted work, stale acceptance, unchecked publication, duplicated irreversible effect or false delivered claim. Any such failure stops rollout irrespective of completion speed.

Before a pilot, agree prospective numeric budgets and sample criteria. A sensible **initial** hurdle is five consecutive representative non-production jobs with zero interventions and all injected failure cases handled safely, followed by a separately approved small production canary. That is a development hurdle, not statistical proof of long-run reliability. For perspective, even 20 successes from 20 jobs leave substantial uncertainty about rare failure rates. Retain ongoing monitoring rather than announce “trusted” after a demo.

Do not endlessly extend a pilot until it looks green. Keep all attempts in the record. If the new controller recreates packet schemas, routine human continuation or multiple state owners, reject that implementation even if its demo succeeds.

## The active experiment and approval boundary

The kaizen ledger already has one active experiment: the non-gating `code-review` healer, due October 19. The earlier quorum proposal in its note was **rejected**, not the current experiment.

An early read-only check found two launched healer runs, both clean successes, versus the predeclared five-run target. That supports continued observation, not adoption; it does not test healing/escalation quality. Leave the implementation, ledger status, criteria and review date unchanged. At the scheduled review, insufficient qualifying evidence calls for the experiment-review process's approval-gated continuation decision, not retrospective threshold changes.

There is also an existing historical BDD rehearsal on an experimental branch, but no ledger authority to treat that as an adopted replacement. Do not launch another operational factory experiment while silently ignoring WIP=1. Matt must decide the sequencing or explicitly supersede that constraint before rollout. Designing this requested proposal does neither.

**Recommended next authorization:** build Milestone A in isolation, with no product delivery and no production credentials, then review its interruption/recovery evidence before building the real-agent loop. Consequential controller/authority decisions should be agreed with Matt and recorded before implementation, rather than invented by a worker inside delivery. This proposal does not accept an ADR, change `bin/dev fabro deliver`, modify the prototype, launch a run, or authorize publication.

### Authorization and first implementation — October 10

Matt authorized proceeding with the isolated skeleton test, learning from it, and trying a real iteration. The [walking-skeleton spike](../../spikes/unattended_delivery/README.md) now exercises actual process interruption, local Git publication and a fake deployment endpoint. Its independent review exposed four additional recovery/boundedness gaps after the initial green suite; regression tests reproduce them and the fixes are included. This is scripted Milestone A evidence, not real-agent or production delivery evidence.

Admission inspection found no currently ready/validated iteration: 068 explicitly needs replanning and 069 needs revision. The authorization does not resolve missing product decisions, make the draft contract ready, or silently change the healer experiment's ledger status. The real-agent loop and release adapters remain work to do; the spike's README records limits rather than claiming all milestones passed.

## Alternatives rejected

- **Raise timeouts and retry counts:** treats useful progress and genuine non-progress identically; does not remove manual continuation or ambiguous completion.
- **Add a readiness reviewer to every packet:** adds another model handoff to a protocol already costing nearly as much as coding. Small executable examples are a better default control.
- **One unconstrained agent until “done”:** removes visible boxes but repeats 062's broad discovery/context problem and leaves tests, permissions and publication to self-report.
- **Remove independent review:** contradicted by 008A and the final 067 regression catch.
- **Require every acceptance example through a browser:** conflicts with the project's test-boundary decision and repeats the historical slow-feedback problem.
- **Make yx the workflow engine:** task organization does not establish candidate identity, test truth, idempotent publication or supervised recovery.
- **Adopt the current one-scenario pilot unchanged:** ignores its manual recoveries, hard-coded scope and unproved green/reviewer provenance and release paths.
- **Replace Fabro with a large new orchestration platform:** adds a migration project before proving the small domain protocol. Make the executor replaceable, and require the simplest one that passes the real recovery tests.

## Bottom line

**The thing we should trust is not an agent's promise to finish a plan. It is a small development loop whose progress is observable, whose work survives interruption, and whose publisher cannot outrun its evidence.**

BDD supplies the outcome. TDD supplies the next safe move. Independent review challenges the proof. Deterministic recovery and publication let that work run unattended.
