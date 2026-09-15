# Problem: Test feedback cost outgrew the implementation loop

Date: 2026-09-14

## Context

We investigated whether Memba's Fabro iteration-implementation workflow was slowing down, which tests ran inside task loops, and how long each test class took. The investigation compared retained Fabro runs from iterations 009–063, retained final-gate logs, and a clean local benchmark at commit `b9c819654`.

Relevant machinery and evidence:

- `.fabro/workflows/iteration-implementation/workflow.fabro`
- `.fabro/workflows/iteration-implementation/prompts/implement_next_task.md`
- `.fabro/workflows/iteration-implementation/prompts/validate_task.md`
- `bin/dev`
- `web/mix.exs`
- `acceptance-tests/cucumber.js`
- iteration-063 run `01M2GSY9BXZSK7X2GP9786P2J6`
- `.fabro/tmp/deliver-063-20260914/events-failed-20260914T224730Z.log`
- retained quality-gate logs under `.fabro/tmp/overnight-061-067-20260913-000001/` and `.fabro/tmp/finish-063-quality-gate-20260914/`
- historical run data retrieved read-only with `fabro inspect` and `fabro events`

Related observations already exist in:

- [Test command standard was not obvious during local implementation](2026-06-17-test-command-standard-not-obvious.md)
- [Iteration workflow timeout masks the actionable test failure](2026-09-03-iteration-workflow-timeout-masks-test-failure.md)

Those notes cover command-selection mistakes and specific timeout incidents. This note records the broader longitudinal cost pattern and the mismatch between the intended focused-feedback policy and actual execution.

## Expected standard

Ordinary implementation and revision tasks should use focused tests that give fast feedback for their selected scope. Independent validation should assess the candidate and its current evidence without automatically duplicating successful test work. Full project validation belongs to the deterministic final `dev_check` node, which runs `dev ci` before plan conformance and publication.

The feedback system should make test cost visible, keep it proportionate to the work being validated, and preserve full coverage at the final gate without repeatedly paying that cost inside bounded agent nodes.

## What happened

### Implementation stages did not show a simple recent slowdown

Comparable Fabro stage timing produced this history:

| Iteration | Tasks | Status | Run wall time | Median implementation | Median validation | Final gate |
| --- | ---: | --- | ---: | ---: | ---: | ---: |
| 009 | 8 | succeeded | 68m | 4.5m | 2.2m | 0.9m |
| 010 | 12 | succeeded | 116m | 7.2m | 2.3m | 0.9m |
| 013 | 13 | succeeded | 144m | 7.3m | 2.0m | 1.0m |
| 019 | 9 | succeeded | 122m | 7.2m | 2.2m | 4.5m |
| 028 | 16 | succeeded | 169m | 11.4m | 1.9m | 5.3m |
| 031 | 16 | succeeded | 226m | 8.4m | 2.8m | 5.7m |
| 061 | 9 | failed | 107m | 8.1m | 1.4m | about 11–13m |
| 062 | 12 | failed | 189m | 7.8m | 2.4m | about 18m |
| 063 | 7 | failed | 133m | 5.9m | 5.0m | about 20–24m |

The old final-gate values are exact completed `dev_check` stage timings. The recent values are estimates from retained ExUnit and browser component logs because the corresponding outer command timing was not retained in every case. Recent failed/recovery runs are not directly comparable with old successful runs, and whole-run duration also depends on task count and revisions.

The core implementation-node median rose from iteration 009's early 4.5-minute baseline, then fluctuated. Iteration 063's 5.9-minute median was faster than several old runs. The recent abnormality is therefore not a monotonic increase in ordinary implementation-node duration.

Validation did change in iteration 063: its five-minute median was about twice the historical two-to-three-minute range.

### The final quality gate became much more expensive

A clean local `bin/dev check` benchmark at `b9c819654` took 17m48.9s:

| Test class | Measured time |
| --- | ---: |
| Node acceptance configuration, 81 tests | 22.5s |
| One focused browser scenario | 16.6s wall; 1.9s scenario execution |
| ExUnit excluding domain Cucumber | 83.5s wall; 72.1s test execution |
| Domain Cucumber only, 152 scenarios | 47.7s wall; 34.2s execution |
| Combined full ExUnit suite, 1,471 tests | 143.9s execution |
| Browser suite, 177 scenarios | 15m02.6s |
| Complete `dev check` | 17m48.9s |

Browser acceptance consumed about 84% of the complete gate.

Comparable retained gate logs show the suite growing between iterations 061 and 063:

| State | ExUnit | Browser acceptance |
| --- | --- | --- |
| Early retained gate | 1,259 tests in 75s | 132 scenarios in 8m46.6s |
| Later retained gate | 1,529 tests in 116.7s | 189 scenarios in 18m02.8s on the faster retained run |

Over that interval, ExUnit count rose about 21% while execution time rose about 56%. Browser scenario count rose about 43% while the faster comparable browser duration rose about 106%. Average browser time per scenario rose about 44%. Another 189-scenario run took 21m20s, so variance is also material.

Five browser features accounted for about 76% of summed scenario execution in the local benchmark:

- `custom_group_conversations.feature`: about 2m59s
- `club_message_replies.feature`: about 2m49s
- `member_message_deliverability.feature`: about 1m48s
- `custom_group_creation.feature`: about 1m48s
- `group_conversations.feature`: about 1m41s

### Broad checks and duplicate tests still ran inside task loops

The current implementation prompt says ordinary tasks should use focused checks and leave the full gate to the workflow. Nevertheless, direct parsing of iteration 063's event log found:

| Command class | Invocations | Cumulative shell time |
| --- | ---: | ---: |
| Focused `dev test` | 63 | 10.3m |
| `dev check --quick` | 9 | 22.7m |
| Browser/Cucumber commands | 7 | about 2.1m |
| Node configuration tests | 5 | about 1.6m |
| Formatting commands | 25 | about 1.3m |

Total cumulative test/check shell time was about 38 minutes in the 133-minute run. The nine quick gates averaged 151 seconds and were the largest avoidable class. No full `dev ci` ran inside the task loop.

`validate_task` itself issued 25 focused `dev test` commands plus browser/configuration commands. Some validation was therefore repeated after the implementor's checks rather than consumed as checkpoint-bound evidence.

This behaviour is not new. Historical event logs show broad `dev check` invocations inside implementation and validation loops as far back as iteration 009:

| Iteration | Broad check invocations |
| --- | ---: |
| 009 | 22 |
| 010 | 29 |
| 013 | 26 |
| 019 | 23 |
| 028 | 25 |
| 031 | 14 |
| 063 | 9 quick checks |

The frequency has generally fallen, but the cost of each broad check has risen enough that nine quick checks still consumed 22.7 minutes.

### Focused commands also pay repeated setup and serialization costs

`dev test <files>` runs through the project's Mix test alias, which prepares the test databases before executing the selected files. Repeated focused invocations therefore pay setup cost repeatedly.

`bin/dev` also protects quality-gate commands with a shared lock. Test commands launched concurrently inside one sandbox do not necessarily gain concurrency; iteration 063 recorded focused commands waiting for another quality-gate lock holder. During this investigation, a local benchmark also waited 18.5 minutes behind another gate before its own timeout. The lock protects shared test infrastructure, but parallel launches can turn intended concurrency into opaque queued time.

## Impact

Severity: repeated delivery friction with increasing timeout and feedback-latency risk.

- Ordinary tasks spend a material part of their bounded execution time repeating broad or already-successful checks.
- Independent validation is becoming slower and can duplicate worker evidence.
- The final gate has grown from roughly one minute in early iterations to roughly twenty minutes, approaching or exceeding command budgets used by agent tooling.
- Slow feedback reduces the time available for diagnosis, implementation, and useful handoff before a 40-minute task-node timeout.
- Lock contention and repeated database preparation make nominally focused or parallel commands less efficient and harder to reason about.
- The project retains full quality coverage, but the workflow does not currently allocate that cost at the cheapest reliable boundary.

## What allowed it to happen

Several system weaknesses combine:

1. Focused-validation policy is expressed mainly as prompt guidance. It does not mechanically prevent an implementation or validation agent from invoking a broad check.
2. The workflow does not provide validators with deterministic, commit-bound test evidence captured from worker tool events, so rerunning tests is an easy way to establish confidence.
3. Agents can issue many focused commands independently instead of batching relevant files into one database setup and test invocation.
4. The quality-gate lock correctly serializes shared infrastructure but does not warn agents before they launch supposedly parallel work that will queue.
5. Browser scenario count and per-scenario duration have grown without a tracked runtime budget, historical trend report, or regression warning.
6. The final browser suite remains largely sequential, while the Fabro sandbox's CPU and memory allocation has not been evaluated against safe database-isolated sharding.

## Observations

- The clearest worsening trend is final-gate duration, not ordinary implementation-node duration.
- Browser acceptance dominates the final gate; asset/database lifecycle setup is comparatively small and is not the first optimization target for a full-suite run.
- Broad checks inside task loops are longstanding rather than a new iteration-063 regression. Prompt improvements reduced their frequency but did not enforce the boundary.
- The cost of old broad-check behaviour was partially hidden while a full gate took one to six minutes.
- A single focused browser scenario is mostly fixed lifecycle/setup cost, while the full suite is mostly active scenario execution.
- Failed focused commands include both legitimate TDD red runs and command/path/environment mistakes; the aggregate failure count should not be treated as pure waste without classifying each invocation.
- No product code or tests were changed during this investigation.

## Why this matters

The implementation workflow is designed around bounded, checkpointed tasks followed by one authoritative final quality gate. As test feedback grows, repeated validation inside those bounded nodes can consume the budget intended for product work and recreate the timeout pattern recorded in the related September incident note.

Without cost telemetry and enforceable command boundaries, future improvements to prompts may appear effective while agents continue paying the same cost through a different command shape. The suite can continue protecting behaviour, but its execution policy needs to scale with its size.

## Open questions

- Which browser steps, waits, fixture setup, or application operations caused average scenario time to rise about 44%?
- Can browser features be safely sharded using isolated database/event-store names and Phoenix ports, and what CPU/memory allocation gives the best cost-to-time result?
- Which historical browser scenarios are genuine end-to-end journeys, and which business-rule permutations could retain equivalent acceptance confidence at the faster domain/ExUnit layer?
- Can Fabro expose a reliable run/node environment marker that `bin/dev` can use to permit broad gates only in the deterministic final node?
- What exact evidence should let `validate_task` accept a worker's tests without rerunning them, and how should that evidence be tied to the candidate checkpoint SHA?
- Can focused ExUnit and browser commands reuse prepared infrastructure safely without leaking EventStore or database state?
- How much wall time, rather than cumulative shell time, would each intervention save in a representative successful iteration?

## Possible prevention ideas

- Mechanically reserve `dev check`, `dev check --quick`, and `dev ci` for the workflow-owned final gate when commands run under Fabro; do not rely only on prompt wording.
- Capture exact worker test commands, statuses, durations, selected tests, and checkpoint SHA from Fabro tool events. Supply that evidence to the validator, and rerun only when it is missing, stale, or inadequate.
- Encourage one deliberate red run and one batched focused verification run per task instead of many single-file invocations. Do not launch lock-protected test commands concurrently.
- Route a failed final gate into focused repair of the named file/scenario, then rerun the complete gate once after the focused failure is green.
- Add per-step browser timing and start with the five feature files responsible for most execution time. Investigate fixed sleeps, repeated setup, and business-rule permutations that do not need browser-level coverage.
- Prototype two- and four-way browser sharding with isolated databases, ports, and enough sandbox CPU/memory. Compare elapsed time, reliability, and provider cost before adopting it.
- Evaluate preparing test infrastructure once per bounded task stage for repeated focused checks, while keeping a clean reset for the final gate.
- Persist timing telemetry for every iteration: node durations, test command counts, ExUnit duration, browser scenario p50/p90, slowest features, final-gate wall time, and lock waits.
- Begin with non-blocking budgets or warnings, such as zero broad checks in ordinary nodes, validation median below 2.5 minutes, and a browser-gate target below 10 minutes. Establish representative baselines before making them hard failures.

## Resolution

Date: 2026-09-14

Root cause: the prompt boundary prohibited "full `dev check`" and "`dev ci`", which left `dev check --quick` and other unscoped full-suite commands as an available workaround. Independent validation could also rerun the worker's already-successful tests, duplicating focused-check cost inside the bounded task loop.

Fix applied:

- `.fabro/workflows/iteration-implementation/prompts/implement_next_task.md`: ordinary implementation tasks now prohibit `dev check`, `dev check --quick`, `dev ci`, and any other unscoped full-suite command. Focused commands are named as `dev test ...` and `dev acceptance ...`.
- `.fabro/workflows/iteration-implementation/prompts/validate_task.md`: validation consumes the worker's successful, current evidence in `.delivery/latest-worker-result.json` by default; it reruns a specific focused test only when that evidence is missing, stale, contradictory, or inadequate, and must state the reason. Broad gates are prohibited in ordinary validation.
- `.fabro/workflows/iteration-implementation/scripts/test_task_execution_contract.sh`: added deterministic regression checks for every broad-gate form in the worker and validator prompts, plus the validator consume-by-default and restrict-rerun rules.
- `.fabro/workflows/README.md`: documents the tightened boundary.

Validation:

- `bash .fabro/workflows/iteration-implementation/scripts/test_task_execution_contract.sh` — passed: 39 prompt/graph contract checks, 19 delivery-planner state tests, 12 verdict-helper tests.
- All `.fabro/workflows/iteration-implementation/scripts/test_*.sh` helper suites — passed.
- `python3 -B .fabro/workflows/iteration-implementation/scripts/test_apply_task_verdict.py` — passed (12 tests).
- `python3 -B .fabro/workflows/iteration-implementation/scripts/test_delivery_planner_state.py` — passed (19 tests).
- `fabro validate .fabro/workflows/iteration-implementation/workflow.toml` — OK (pre-existing `publish_to_main` goal-gate warning only).
- Full `dev check` on the staged diff (`MEMBA_POSTGRES_PORT=15463`): exit 1. ExUnit passed; browser acceptance reported 187/189 scenarios. The two failures were pre-existing flaky scenarios: `club_message_replies.feature:24` (projection-timing timeout) and `custom_group_conversations.feature:83` (`:consistency_timeout`). Both passed when rerun in isolation. The diff contains no product, test, or feature-file changes, so these failures are unrelated to this fix.

Remaining follow-up:

- Agent adherence must be demonstrated by a later real delivery run; the contract tests prove the instructions and checks are present, not that agents obey them.
- Browser-suite runtime growth, sharding, and per-scenario profiling remain open (see the observation above).
- The native Fabro runtime harness (`test_task_workflow_runtime.py`) was not runnable in this sandbox for an unrelated local reason (git path resolved inside the sandbox; Xcode license). Its passing shell/Python siblings are the relevant command during a delivery-machinery text change.
