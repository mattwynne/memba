# Problem: BDD scenario feedback arrives after implementation

Date: 2026-10-03

## Context

In iteration [067](../iterations/067-live-projection-queries/plan.md), the agreed [open member-list example](../../acceptance-tests/features/live_club_member_list.feature) was formulated before delivery but remains tagged `@todo`. The plan places activation of that example, its step definitions and final proof in task 011, after the dashboard work in task 005, conversation detail in task 006, package extraction and other migrations. Task 005 needed a human clarification that a new conversation should enter an already-open list; the missing example is recorded separately in the as-yet-unmerged example-mapping note on `kaizen/067-example-mapping-gap`.

## Expected standard

An agreed BDD/ATDD example should guide delivery as a live, executable, failing-to-passing feedback loop. Choose one scenario deliberately; identify its genuine current failure; make the smallest meaningful change that advances the outcome; rerun it; repeat until it passes. Mark the active scenario `@wip` while it is the focus and expected to be red, and remove `@wip` when it turns green. Keep independent review, approved scope and final all-green gates.

## What happened

The current plan permits removing `@todo` from the 067 feature during implementation but schedules the acceptance example for the final implementation task. The default Elixir and browser runners both exclude `@todo`, so an `@wip` tag alone would not make that scenario run. The delivery planner instead hands a bounded *technical packet* to one worker; its result contract allows `ready_for_review` only with successful focused validations, or `replan`/`human_blocked`. There is no explicit one-scenario WIP selection, baseline failure, incremental failure-to-failure handoff, or success transition that removes the tag. Task 006's 40-minute timeout exposed the cost of a packet combining several vertical proofs without such a driving scenario loop; it does not itself establish that an active scenario would have shortened that task.

## Impact

The accepted example cannot expose missing steps or a failing user outcome early in delivery; focused implementation tests can pass while a stakeholder-visible gap remains undiscovered until late. Large packets may accumulate work before the scenario gives feedback. Conversely, an intentionally red scenario cannot be treated as a passing quality gate or silently published.

## What allowed it to happen

The plan and workflow treat the formulated feature as a late acceptance artifact rather than the worker loop's first-class feedback signal. `@todo` suppresses it; packet routing and task review have no state for reviewed incremental progress while that chosen scenario still fails. The feature-change policy rightly limits changes to explicitly approved files, so changing tags or wording cannot be an unchecked planner shortcut.

## Observations

- The [acceptance runner guide](../../acceptance-tests/README.md) defines `@todo` as excluding future scenarios from both runners and warns against hiding broken current behaviour; `@wip` has no runner semantics today.
- The agreed 067 scenario concerns an already-open member list, not every conversation-detail or package-integration proof. Technical unit and connected LiveView tests remain necessary even in a scenario-driven workflow.
- A changed failure message is useful only if the worker moved a real behavioural obstacle. Making an assertion weaker, skipping a step, or fabricating success must not count as progress.
- A scenario going green need not complete all iteration obligations. Keep it green while refactoring/integrating; choose the next approved scenario when appropriate.

## Why this matters

The team loses BDD's early feedback and may mistake a late green acceptance test for evidence that the scenario drove design. A deliberate WIP loop could also produce smaller, more diagnosable worker steps, provided the chosen scenario can observe the risk and its failing state is isolated from final publication.

## Open questions

- How should the planner select an agreed scenario with useful feedback, and what additional scenario discovery/formulation is needed when the current example does not cover the behaviour being built?
- How should a targeted `@wip` run include a scenario currently marked `@todo` without contaminating the normal quality gate or letting a red scenario publish? What tags and runner selection are needed at each transition?
- What exact durable evidence ties a worker change to the prior and new failure, and what does independent review accept while the active scenario is intentionally red?
- When and on which iteration should this workflow be piloted, without interfering with 067's preserved, unreviewed task-006 checkpoint?

## Proposed direction (not implemented)

Matt proposes that the planner choose **one** agreed scenario carefully, mark it `@wip`, run it to capture the actual failure, then dispatch one small worker change intended to advance that failure. After review, rerun the same scenario and plan from the new result. Remove `@wip` as soon as it is green; retain the scenario in the normal suite thereafter. Do not weaken the scenario or bypass independent review, clean-tree, feature-change, or final quality gates. Investigate the tag/runner and interim-review contract before changing the workflow. No countermeasure or delivery-run recovery was authorized by this observation alone.

## Investigation — 2026-10-03

Matt chose to use this loop immediately and added **call your shot**: before running the focused scenario, the planner must record the particular failure it predicts. A different failure is learning, not permission to pretend the planned change is still the next step. The planner must revise its understanding and next move from the observed failure. The prediction must be durable and timestamped/ordered *before* the execution evidence, so it cannot be rewritten after seeing the result. A worker should change one meaningful thing to advance the observed failure, then the same scenario is rerun; the next prediction is made before that rerun. `@wip` is removed once the scenario passes, and normal green regression coverage remains.

**Current boundary:** 067's only explicitly authorized new acceptance example is Bob's already-open **member list**. Task 006's preserved, unreviewed candidate concerns **conversation detail**. Existing conversation scenarios cover replies/following but not the newly live-updating, already-open detail rule. The 067 plan authorizes changes only to `live_club_member_list.feature`; the planner cannot invent a new conversation-detail acceptance scenario or use Bob's list to claim conversation-detail proof. `@todo` excludes the authorized member-list example until activated. The delivery planner currently emits a typed handoff before the worker, but does not run a selected scenario or persist a pre-run prediction; a new test-execution boundary and intermediate-red review semantics would be needed. Keep the current fail-closed planner guard and independent task review.

**Recommendation:** start with the already authorized member-list example, safely activate it as the only `@wip` scenario, and record a specific predicted failure before every run; stop and diagnose surprises before dispatch. Do not discard or accept the task-006 checkpoint. Whether to create an additional conversation-detail example for its own BDD loop requires a separate agreed example and plan permission; do not silently treat the list scenario as covering it. Compare predicted versus observed failures and the size/time of each reviewed change; keep final gates green and free of `@wip`. This investigation has not changed the workflow or resumed 067.

## Resolution — 2026-10-03 (implementation, effectiveness pending)

Matt authorized changing the existing planner-owned task loop now, without discarding accepted 067 work or treating the unreviewed task-006 checkpoint as accepted. The planner packet now has an explicit `scenario_focus` (nullable for justified technical/recovery work). For a focused domain/application scenario in a plan-permitted feature, the deterministic stage activates exactly one scenario-level `@wip` (removing `@todo`), records the planner's specific predicted failure **before** running it, and dispatches a worker only when the observed red result matches. The planner also predicts the post-worker failure or green outcome before dispatch. A pre-worker surprise returns to the planner for diagnosis. After the worker, a separate trusted rerun records red/green evidence and removes `@wip` on green. Independent review retains authority: the verdict guard rejects missing/stale observations, an unchanged failure, or a post-worker surprise; a changed red failure still needs a meaningful-progress review. Full `dev ci`, the final-artifact gate and publication reject any remaining `@wip`.

The change is in `.fabro/workflows/iteration-implementation/` (graph, planner/worker/reviewer prompts, schema, deterministic helpers and regression fixtures), plus the acceptance-runner/workflow guides. The typed writer and existing planner boundary stay fail-closed; accepted todo lines and candidate provenance remain protected. The focused WIP runner currently supports only domain/application examples with an exact scenario name, not browser journeys or scenario outlines. It does not invent an approved conversation-detail scenario or resume/review/publish run `01M3RCMKB0QE3KXT99PMFV8E8B`.

Focused helper, native Fabro routing and final/publish gate tests cover prediction-before-run, one active WIP tag, expected versus surprising failure, green tag removal, acceptance of a meaningfully changed red diagnostic only after review, altered/stale/unchanged prediction evidence rejection and no-WIP publication. A real ExUnit run confirmed that `--only scenario_name:…` selects exactly one accepted scenario (179 discovered, 178 excluded). `dev check` passed on the final staged workflow change (1,615 ExUnit tests and six browser journeys). A live scenario-driven delivery remains unproven: fixtures cannot establish that a real planner selects well, calls its shot accurately, or returns early enough to avoid another 40-minute timeout. Keep the ledger Open until effectiveness is observed and the 067 recovery is separately authorized.
