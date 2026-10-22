# Implementation and test plan: a simple coding workflow

Date: 2026-10-15
Status: **Historical working plan; superseded by the published domain-only workflow**

Part of the [review-churn kaizen note](../2026-10-03-adapter-review-churn-required-repeated-human-gates.md), not a product iteration.

## Current outcome — 2026-10-22

The generic workflow and developer tooling were merged to main at `9230ea2796937992da001ffdf2d96553f3beb5b5`. The [current plan workflow](../../../.fabro/workflows/bdd-plan-implementation/README.md) selects one pending domain declaration, implements it through the nested scenario workflow, passes the graph-owned full check and repeats against the changed code. It uses published stock Fabro 0.389; no controller, provider bridge, private engine or ownership workaround is part of the final design.

The [delivery skill](../../../.pi/skills/iteration-delivery/SKILL.md) recommends the guarded domain-only option for suitable small, approved domain-focused work. It retains plan validation, clean/published-source, predecessor and WIP controls. Review, merge, deployment and remaining UI/journey/technical obligations are separate. Read the [current operating guide](../../../.fabro/workflows/bdd-plan-implementation/OPERATIONS.md), not the earlier procedures below, before launching anything. No new product iteration was authorized or launched by publishing this workflow.

Managed run `01M5GZGTGP88RMNSNTPPEAN8PZ` passed full checks on that exact source: 19 package tests, 1,868 app tests, 61 CLI scenarios/322 steps, 19 delivery-guard tests, 16 responsive-detector tests and eight browser scenarios/121 steps. Fifteen deterministic workflow tests also passed; all 2,645 tracked physical entries were unchanged and matched immutable Git. This was source-quality proof with no model calls, not another implementation rehearsal.

The genuine historical rehearsal `01M5GFYTJZPAAYTVZFDAXSMSXV` completed all three domain scenarios in about 97 minutes without manual repair. The first selector also made read-only history queries, so the frozen experiment did not meet its literal current-tree-only rule. Matt judged the observed status-clarification detour innocent; that explanation remains an inference from the commands, not a claim about private reasoning. The limit is recorded without blocking suitable real use or paying for another historical rehearsal. See the [complete result and limits](../../../.fabro/workflows/bdd-plan-implementation/REHEARSAL.md).

The broader review-churn note remains Open: this narrower loop does not prove independent review or end-to-end delivery. The separate healer experiment is unchanged. The historical product implementation remains evidence only, not merged product code.

## How to read the historical record

The remaining sections preserve the earlier proposals, changing scope, failed attempts and evidence available at each date. Statements such as “current”, “unvalidated”, “not yet wired”, “uncommitted on main” and “next run” refer to that historical point. They neither override the current outcome above nor authorize another run or restoration of the removed controller/refactoring/review stages.

The original document, old workflow drafts and ignored evaluation results were preserved in a verified private cleanup archive before the original checkout was updated. References to private reports below are evidence locations, not missing public repository files. Pre-upgrade native run links are historical identifiers: stock 0.389 cannot inspect their old format; archives and the pre-upgrade rollback backup retain that evidence. Source links below use the current package location where the relevant files still exist.

## Deterministic empty-set and dangling-TODO check — 2026-10-20

Matt pointed out that detecting no remaining work does not need a model. He clarified that future iterations' TODOs are allowed, but TODOs left on completed/merged iterations must error, including journeys. The implementation is a small Node helper using the existing Gherkin parser rather than a Python-to-JavaScript wrapper. It reads a commit, discovers the active indexed plan, validates unfinished scenario ownership/status before filtering, and reports remaining domain work versus journeys. Empty domain set routes `done`; nonempty routes `choose`; WIP, parsing problems, unowned/ambiguous work or missing/nonunique plans error. It never edits metadata or treats domain-loop completion as a merged iteration.

`pending.cjs` (the historical predecessor of the [public BDD tooling](../../../dev-tools/bdd/cli.cjs)) is standalone, not yet wired into the draft parent graph. Twelve ordinary tests cover empty/current/future sets, dangling merged TODOs including journeys, inherited tags through Examples, WIP, metadata/parser errors and immutable-commit CLI reads. Direct checks on the three selection fixtures find the expected 3/2/1 pending domain scenarios. No all-done model eval or changed selector prompt is needed.

Exact source `5353d1149601be9adaa6ac21d4dc469cfe8a2cc1` passed full managed-Docker `dev check` and guard/helper tests in `01M5CVXRP7XCEFBQTGJ9VEXTC0`: all 2,639 tracked bytes/modes and Git metadata unchanged. The owned container was observed stopped/exited with matching labels and stable ID in three fresh snapshots. Evidence retained at `/home/matt/.local/state/memba/pending-guard-20261020/` and copied private retained result (`eval/results/pending-guard-20261020/RESULT.md` in the archived draft). No model runs, main publication or Fabro changes; staged numbering work remains unchanged. Next integration is to put this ordinary command in front of the tested selector, not invent a terminal-response protocol.

## Commit-only selection with one domain example left — 2026-10-20

The third fixed case narrowly restores historical whitespace validation in the synthetic fixture and completes that example; the original stale-edit assertion still fails as intended. Exact fixture `78defb268862517be3811500cad34a5dd3f82b57` and source `4240e4c350db308d6722afe2cad98086d58e68b7` passed separate managed-Docker `dev check`; the selection prompt and runner remain byte-identical to the first case. Independent prelaunch review verified actual code/proof, not just changed tags.

Native run `01M5C6TXFA2KYQY7DKRDTSW9ZA`: **20/20 correct plan/feature and sole pending stale-edit choice**, zero missing/failed stages; independent final audit confirmed every answer and native record. Twenty distinct sequential sessions used identical prompts; 529 tools were read-only Git commands/filters, final tree unchanged. One native provider retry occurred within trial 7 after an OpenAI server error; no stage retry, repair, replacement or excluded result. Actual cost **$24.095225**, elapsed **26m37.115s**; per-case 95% Wilson **83.887–100%**. Three matching ownership snapshots confirm the batch container stopped/exited; QA resources also stopped.

Across the three cases the same prompt produced the accepted next choice 20/20 at each state: foundation before implementation, whitespace after foundation, then stale edit after whitespace. These are sixty observations across three fixed related states, not a general reliability estimate or proof of implementation/coordination. The second and third cases test excluding completed/out-of-scope work, not ranking multiple pending candidates. Synthetic/stale-prose/legacy-status limitations remain explicit. The all-done/no-pending case is not yet tested or specified in the output contract.

Full records/bundles are retained outside child workspaces, with a private retained third-case report (`eval/results/commit-selection-whitespace-done-20261020/RESULT.md` in the archived draft). Both children completed their assigned execution/review; retain results before archival/stop. No main merge/publication or Fabro change. Native model cost over these three decision batches is $78.146645, excluding preparation/QA and earlier failed batches. The parent kaizen remains Open.

## Commit-only selection after the foundation — 2026-10-20

Matt asked to keep going with subagents. No honest historical half-done checkpoint existed, so we prepared an explicitly synthetic fixture from the first case and historical successful-rename code, with whitespace and stale-edit aggregate constraints deliberately unfinished. Creation invariants and agreed domain assertions were preserved. In managed Docker the foundation passed; both pending examples reached their original behavioural assertions and failed because invalid/stale writes were accepted, not because steps/setup were missing. Exact fixture `b1f14f2b1ee8029579ac874d94d57da7cc8b9337` and selector source `4087367f5d614b560b4035164e393183d344e98b` separately passed full `dev check`. Setup/QA failures were retained, not erased. The prompt and runner were unchanged from the first case.

After independent prelaunch review, native `01M5C2AKZFK08QCW439KQDMVWK` returned **20/20 correct plan/feature and acceptable pending choices**, all whitespace validation. No completed foundation or unrelated work was selected. Independent final audit confirmed all responses, twenty distinct sequential sessions with identical prompts, zero missing/failed stages, read-only Git tools and unchanged final tree. 95% Wilson **83.887–100% on this case**; actual cost **$29.321396**, elapsed **43m30.342s**. One successful read command lacks a matching tool-completed event; process exit/stage/response records are retained. Exact owned containers were stopped/exited in three matching observations.

This tests excluding completed/out-of-scope work, not ordering the two constraints: either pending choice was acceptable and whitespace appeared first. Synthetic provenance, stale 068 background prose and the legacy-070 status ambiguity remain caveats. Evidence/bundles and private retained report (`eval/results/commit-selection-partial-20261020/RESULT.md` in the archived draft) are retained; nothing merged or published. The same children are now preparing/reviewing the next state (foundation and whitespace complete, stale edit pending); no next-case model launch before review. This kaizen stays Open.

## Commit-only selection prompt — 2026-10-20

Matt replaced the coordination exercise with one isolated read-only prompt. Its only task input is a commit: discover the single active plan, find its TODO domain scenarios, inspect code/guidance and return the next scenario plus a short reason. No plan path, scenario list, implementation workflow, double, tag edit or application test is supplied or run.

The first frozen case uses historical product code before name editing, approved 068 planning files, whitespace validation first in file, and consistent plan/index `implementing` status. The accepted first choices remain either successful-rename scenario. Input commit `a481d1420b30a256b6ea547560420ad7177c656e`; source `3f30c0adfc4f0862ba095f266093491c0a28e428`.

Run `01M5BTGG9MSJCN28C17649SFDA` returned **20/20 correct plan discoveries and acceptable scenario choices**, all selecting corrected-name propagation across clubs/history rather than file-first whitespace validation. Twenty distinct native sessions had identical assembled prompts and OpenAI/gpt-5.6-sol/high settings. No missing replies, repairs, retries, replacements or steering. 95% Wilson interval **83.9–100% on this case**, not general workflow reliability. Actual elapsed 36m02s; native cost $24.730024.

Native audit found 539 shell calls containing Git reads/read loops/text filters, no edits/tests/helpers/network/publication; final Git tree unchanged. A few trials consulted immutable ancestry to resolve historical metadata. The fixture's inherited legacy 070 `implementation` status is outside the index's documented active-slot vocabulary; only 068 occupies that slot. The case does not test zero/multiple active plans or partial implementation. All reasons identified the missing rename write/read path, but explanations were not model-judged.

Separate managed-Docker `dev check` and seventeen helper tests passed on exact source `3f30c0adf` (`01M5BSYT3P0CY4SQXFPN9J9HKM`); all 2,637 tracked bytes/modes and Git metadata matched. Both owned containers were stopped/exited on three ownership-checked observations. Full records/bundles retained at `/home/matt/.local/state/memba/commit-selection-20261020/`; copied private retained result (`eval/results/commit-selection-20261020/RESULT.md` in the archived draft). Nothing was merged or published; staged numbering work is unchanged and the kaizen remains Open. Next useful coverage is selection from a commit with foundational work already implemented, not returning to the larger coordination harness.

## Approved rename-first batch — stopped after one trial, 2026-10-20

Matt approved a new fixture with whitespace validation first in file and either successful-rename example accepted first. Two subagents prepared/executed and independently reviewed the batch. Frozen source `a1d7f55bddc64a636bcb3f83453fb7392aa1370b`, fixture `4e9216bfed41430d08cb9e0279ee67f9b43682e2`. Exact-source `dev check` and seventeen helper tests passed in managed Docker (`01M5BR38HABSVFJMF24CAPGZ57`), and independent review checked the approved grading/fixture boundaries before launch.

**Twenty requested; one launched and failed; nineteen never launched.** Run `01M5BRWFP412G7W2A2GCGB6Q94` stopped because our generated command script `@double.sh` was executed literally by Bash (exit127), not expanded to script contents. Stock graph validation had passed but did not exercise command execution. This is an error in our test setup, not another Fabro source-fix task. No imported scenario completed and no full grader verdict exists. The navigator's directly observed first choice was whitespace validation, contrary to the approved criterion; subsequent coordination remains unobserved. Native111.568seconds/$1.871268; no retries, repairs, replacements or regrading. Wilson0/1 interval0–79.3% is not a completed20trial reliability estimate.

Independent audit confirmed receipts, invocation, choice/tag diff, cost/time and three matching stopped/exited snapshots. Agent used shell edits only; no helpers, app tests, uploads or publication observed in the single visit. Full evidence and reviewed source/bundle are retained outside child workspaces at `/home/matt/.local/state/memba/bdd-plan-rename-first-20261020/`; copied local report/manifest/summary under the parent's ignored `eval/results/2026-10-20-rename-first-20/`. No main merge, source repair or new batch followed. Source-quality checks did not catch our generated-double execution error; a further run needs that setup corrected and exercised without a model first. This kaizen remains Open.

## Stock Fabro only — 2026-10-20

Matt explicitly rejected modifying Fabro or running a fork. The separate native source patches are not an integration/deployment path; their investigation is closed and the subagent archived/stopped. The normal CLI/server remain unmodified `0.316.0-nightly.0` (`0abf229`). No upgrade, custom binary or private provider was installed.

The plan workflow now uses Fabro's documented `import` to reuse the scenario graph inside one run, rather than a `shape=house` child engine. This avoids the separate child-output store while preserving one scenario workflow source. Agents are instructed to make all edits/writes through shell commands, avoiding native uploads that were directly observed changing a user-owned file to root ownership. No chmod/chown repair or tool interception is added. A small unconditional success boundary makes the scenario graph importable; failed checks still repair or stop. The double/checker now use imported completion stages.

A tiny model-free capability run `01M5BEMDRSYP8TD6RC7Y35FNNX` succeeded on stock Fabro with normal managed Docker/Git: shell writes before, inside and after an import retained ownership `1000:1000` and contents. Native dump resolved the imported command's output. This is capability evidence, not a real scenario implementation or proof that agents obey the shell-edit instruction.

Exact source `e9fe14759093dcd87447bdc1e192174f68b2f5e5` passed managed-Docker `dev check` and fourteen helper tests in `01M5BEMDHJNSGSCDA5SK0A76NY`: 19 package/1,860 application tests, eight journeys/121 steps. All 2,632 tracked bytes/modes and Git metadata matched before/after. Both owned containers were observed stopped/exited three times. No new model batch or main publication occurred. The proposed new ordering criterion (whitespace first in file; either successful rename acceptable first) still needs Matt's agreement; the old failed trial stays unchanged.

## Plan parent and test-double eval — 2026-10-19

The single-scenario workflow was committed/pushed as `8ac84f8a6` after Matt's approval. Matt then authorised a separate [`bdd-plan-implementation`](../../../.fabro/workflows/bdd-plan-implementation/README.md): choose a useful foundation from the plan/ADRs/code, activate one domain scenario, call the scenario child, keep its work and reconsider the next choice. No refactoring, review or publication was added. The parent uses Fabro's native sub-workflow node and ordinary notes, not a controller.

The first eval uses approved iteration 068 with its three domain scenarios pending and stale-edit confirmation first in the feature file. A test-double child supplies prepared results; real scenario implementation is not repeated. Twenty fresh sequential trials were declared. **One launched and failed; 19 never launched.** Run `01M58Z7AFPYM8A5JS4R0HT2EPN` took 3m59s, estimated $2.592148. No child completed, so keeping earlier results and completing the plan remain unobserved. The overall trial count is 0/1 (95% Wilson 0–79.3%), not a model-reliability estimate or a completed twenty-run batch.

The navigator chose stale-edit confirmation, explaining that it establishes a conditional rename within the Person boundary before broader cross-club/history reads. That differs from our predeclared expected choice but is not evidence of blindly following file order. The eval also had a flaw: the navigator could and did read its prepared implementation patch before choosing. We must correct that visibility and review the case's ordering criterion, not quietly relabel the result as passing.

The native child applied prepared code but hit `EACCES` when rewriting the feature previously edited by the navigator. Docker upload ownership is a source-backed hypothesis, not a verified UID/GID diagnosis. Fabro's dump then failed on a missing child-output blob; source inspection found an in-memory child store. Raw events and artifact copying retained the failure. The eval runner stopped on export before updating its terminal summary; the original was retained and the launch count manually reconciled. No permission workaround, custom export bridge, replacement run or execution in a stopped container followed.

Exact committed/pushed source `f21989066278325f378858653c2be45971b5e512` passed managed-Docker `dev check` and twelve pure utility/eval tests in `01M58Z6P0EVTJ0VFYGJTW0NZSY`: 19 package tests, 1,860 application tests, eight journeys/121 steps; all 2,630 tracked bytes/modes and Git metadata matched. An earlier quality attempt hit the ten-minute command timeout and remains failed; the second used the same source with a 30-minute QA-node timeout. All three owned containers were observed stopped/exited three times. Source quality is not parent coordination success. The parent stays unpublished, main's unrelated staged patch is unchanged, and this kaizen remains Open. Detailed local evidence is under the parent's ignored `eval/results/2026-10-19-v1/`.

### Eval simplification requested by Matt — 2026-10-19

Removed per-child feature copies, code hashes and the file inventory. The double records selections/tags in one log; one checker uses that log, native child completions, the final feature and final Git diff. The runner collects native events/artifacts without requiring `fabro dump`, and derives totals from saved launch/wait/grade receipts so failed exports cannot erase terminal results. Prepared code is bundled into the child command rather than copied into the initial checkout; a Git-clone test covers that boundary.

Exact source `7eab46740f2fa26d62405efdf4e433eeea5851cf` passed managed-Docker `dev check`, six Node helper tests, two Python infrastructure tests and the five existing scenario utility tests in `01M59DHRN696RCKD08PCQEJWKH`. All 2,630 tracked bytes/modes and Git metadata matched before/after; the owned container was observed stopped/exited three times. No new model batch ran, no first-choice criterion changed, and the native permission/output problems remain unresolved. The old failure stays intact. This is a simpler eval with source-quality evidence, not successful parent coordination or publication.

## Current scope — 2026-10-18

Matt asked to remove refactoring and review from this workflow, keep it focused on implementing one scenario, and retain the `bdd` prefix. It is now [`bdd-scenario-implementation`](../../../.fabro/workflows/bdd-plan-implementation/scenario/README.md): navigator/driver changes until the scenario passes, then `dev check`; failed checks return for repair and passing checks finish. The three refactoring/review prompts and their stages are removed. Those jobs belong in separate workflows, which have not been built here.

The navigator unit case now starts with a passing scenario, removed WIP tag and no full-check result. The full-workflow eval now requires implementation and final checks, not an internal review. Historical results remain intact and do not count as runs of the smaller workflow. The remaining sections record earlier designs and trials, not requirements to restore the removed stages.

The new scenario-passes unit case was run 20 times with each set of instructions: the previous navigator chose checks in 8/20 trials (95% Wilson interval 21.9%–61.3%); the simplified navigator chose checks in 20/20 (83.9%–100%). Case, model settings and eval graph stayed identical, with no missing or replaced answers. The graph now has seven nodes and two agent prompts. Exact source `0c2496b4d02c100d4b517cdceedec6984a723fc3` passed five utility/workflow tests and managed-Docker `dev check` in run `01M588BBVZVJE2QYVEVSZVS5JF`; its 2,616 tracked files and Git metadata were unchanged. Both unit runs and the quality run were observed stopped/exited three times. A full implementation run of this smaller workflow has not yet been evaluated.

The first run of the direct-checks version of the old workflow (`01M57Y8PZS00BPHM6ZWFZDRCAE`) finished natively after 99m20s, with estimated cost $51.137480. It exercised review → repair → checks → fresh review successfully. Its final commit `85b30c52300cd0077dc5ea32f92f97fb2306590e`, logs and artifacts are retained. Its owned container was observed stopped/exited three times. The old three-run batch is closed after one run because Matt changed the scope; runs two and three were never started. This is not a three-run success claim.

## Simplification after review — 2026-10-17

Matt rejected the custom controller and asked for something as small and clear as a toy example. The current implementation replaces it with the Fabro graph, normal configuration and five short prompts. The Python runner, its state files, hooks, reply validation and regression suite are removed. Their source and overnight evidence remain in the earlier throwaway commits and private records.

Drivers always return to their navigator. Predictions and actual test output are compared by the navigator, not a Python function. Plain Markdown assignments/results and ordinary test logs let separate conversations share work; no code parses those notes. Full `dev check` is a command node, and its actual exit determines whether review starts. Review findings return for repair, followed by refactoring, checks and a fresh review.

This deliberately trades custom enforcement for clear agent instructions. Staying in scope, predicting before testing and stopping at the predicted result are no longer checked on every tool call. Native stage timeouts and visit limits remain; the old aggregate operation/deadline counter does not. None of this renews the exhausted overnight scenario allowance or resolves the uninvestigated formatter permission error.

The graph and five prompts are the implementation to review now. Fabro validation passes (10 nodes, 20 edges). A separate normal-Docker [`dev check`](https://fabro.home.wynne.family/runs/01M54BM1P0G42HST7CR9DN12DQ) passed on exact throwaway source `33a2640f6010058e0ee4de28c8831fbb15be5172`, with 19 package tests, 1,851 application tests and eight browser journeys/121 steps. Tracked source bytes/modes and Git metadata were unchanged before/after. The container is stopped; main's staged changes remain untouched. This is source-quality evidence, not another scenario rehearsal.

The earlier plan and overnight results below describe how we got here, not requirements to rebuild the removed machinery.

### Navigator unit eval — 2026-10-18

Matt asked to test the navigator decision independently, with repeated trials and statistics, before changing its behaviour. The [unit eval and run command](../../../.fabro/workflows/bdd-plan-implementation/scenario/eval/README.md#earlier-results) now supply one fixed after-review-repairs case to the unchanged production prompt. It grades Fabro's extracted route, not the agent's prose. Twenty tool-free native prompt calls provide a success rate and 95% Wilson interval; missing responses are reported separately. This is a distilled decision fixture, not a replay of the whole conversation or a test of full-check execution.

Baseline run `01M56Y1BBCWGBJY6R380HP3XFX`: **0/20 chose the newly required direct `check` route** (95% interval 0.0%–16.1%); 17 chose `change`, three `refactor`. No responses were missing or replaced. The current prompt does not offer `check`, so this is a red test for the desired new behaviour, not a measurement of the historical stop rate. All assembled prompts were identical. No production prompt/routing change or new “blocked” option was included; the earlier partial routing edit was reverted before the baseline.

Source `77daf79bc045899d1dbcdc9826688efcb819d763` passed four runner/scorer tests and full `dev check` in managed Docker (`01M56Y1B3W1ABYKE4DZ72RQ9FY`): 19 package tests, 1,860 application tests and eight browser journeys/121 steps; responsive checks correctly skipped a non-layout change. All 2,619 tracked bytes/modes and Git metadata were unchanged. Both owned runtimes were observed stopped/exited three times. At that point, no changed-version unit eval or new full-workflow batch had run.

Matt then asked a subagent to add the direct checks choice and repeat the same 20-trial unit eval. Commit `7388b78a40e48cc1781ac7a2f2e68c059eaa18e4` changes only the navigator prompt and adds its edge to the existing check node. The changed navigator chose `check` in **20/20 trials** (95% Wilson interval 83.9%–100%), compared with 0/20 before. The case, model settings and eval code were unchanged; all requested trials returned answers. Run `01M57WXG2S73A77P2MYBPHF2SH` took 155 seconds with a native cost estimate of $0.171220. This supports the changed decision on this case, not general workflow reliability.

The exact committed change also passed four runner/scorer tests, graph validation and normal managed-Docker `dev check` in run `01M57WY4TJ3D322NT0DXAYT0NG`. All 2,619 tracked files and Git metadata matched before/after. Both owned containers were stopped/exited on three observations. The parent reviewed and applied the two-file change without staging it, retained the child's results under `eval/results/`, and preserved main's existing staged work. No new full-workflow eval has run.

### Plan-seeded workflow and repeatable eval — 2026-10-18

Matt then asked to seed the navigator directly from the iteration plan and run exactly one `@wip` domain example, initially failing. The separate brief and test-command input are gone. `dev test:wip` now belongs to ordinary test tooling: it rejects zero/multiple selections, preserves real failures, and also exits nonzero after a passing scenario with “This scenario now passes. Remove its @wip tag.” The navigator removes the tag, then uses ordinary focused tests for refactoring and repairs.

The tracked [eval process](../../../.fabro/workflows/bdd-plan-implementation/scenario/eval/README.md) and [fixed historical case](../../../.fabro/workflows/bdd-plan-implementation/scenario/eval/cases/name-change.md) define preparation, the checklist and manual judgement. `eval/results/` is Git-ignored. No new custom limits or controller were added; time/cost limits were explicitly deferred to learn from actual use. Fixes and reruns remain manual decisions.

Frozen workflow/tooling source: `4f489b1770d8538827ddb5e2b1bfea8fe14d2ea2`. Prepared historical source: `42b0f051ba206f972120e2be110bf1ac4dd80c4e`. All three runs used that same prepared commit, model and image in fresh normal Fabro environments. None inherited another run's implementation, and no parent repair or steering occurred during a run.

| Run | Native outcome | Elapsed | Native estimated cost |
| --- | --- | --- | --- |
| [1](https://fabro.home.wynne.family/runs/01M56537E00SWJQKJNVGMT0VXZ) | Completed; full check and clean fresh review | 73m51s | $39.23 |
| [2](https://fabro.home.wynne.family/runs/01M569DKR7EE26CAW43M4RY216) | Completed after two review/repair cycles | 108m43s | $71.15 |
| [3](https://fabro.home.wynne.family/runs/01M56FPDS23ZHB8G3J2YK9RWS6) | Failed: navigator selected stop instead of final checks/review | 91m07s | $59.37 |

**Batch verdict: failed, 2/3—not the required 3/3.** The third run got the scenario green and repaired two genuine review findings, but its final navigator response said the code was ready for checks while emitting `preferred_next_label: stop`. The full check before those repairs was stale. Earlier, the refactoring navigator twice selected the BDD-repair route instead of dispatching its own cleanup. These are visible model routing mistakes, not a Python controller refusing collaboration. No fourth run, hidden fix, resume or replacement followed.

Positive evidence is stronger than the earlier overnight prototype: real navigator session reuse, fresh drivers and reviewers, actual green-before-edit cleanup in runs1/2, and review/repair/recheck/rereview in run2. Run3 demonstrated six small assignments, each stopping at the predicted next undefined step until the final scenario passed. Wrong initial product predictions were not observed in this batch; do not count that branch as tested.

The eval also exposed extra work: the agents spawned 10, 12 and 10 nested helpers respectively and repeated full checks outside the graph's check node. Run2's reviews changed their judgement about a future-client baseline risk, causing additional repair. Formatting still encountered root-owned write restrictions. These are findings for a manual discussion, not reasons to rebuild the removed controller. Native scenario estimates total $169.750526, not billing or total preparation cost.

The normal-Docker [source-quality run](https://fabro.home.wynne.family/runs/01M564CEA0YNWV6TEVSKQPMX7Z) independently passed actual no-WIP/multiple/red/green/untagged command probes, 12 focused tooling tests and full `dev check` on exact frozen source: 19 package tests, 1,860 application tests, 10 responsive checks and eight browser journeys/121 steps. All 2,616 tracked bytes/modes and Git metadata matched before/after. The coding subagent's earlier host tests did not count as that validation; the parent reran it in normal Docker. All four owned QA/eval runtimes were observed terminal and stopped/exited three times. Raw results, native artifacts and candidate Git checkpoints are retained. Main's original HEAD and staged numbering changes remain untouched; replay product code was not merged or deployed.

## The simplest thing that could work

Add one opt-in workflow on main, alongside the existing workflows. Keep `fabro deliver` and its current behaviour unchanged. Reuse the tested normal Docker runtime from the private prototype; do not merge that branch wholesale.

Start with one scenario, four implementation prompts and one review prompt. Use Fabro's existing agents, conversation handling, commands and checkpoints, with only small supporting guards where needed. No new orchestration platform, task ledger or eval framework. One review prompt covers all applicable lenses; parallel work within the review can wait until useful.

**Order: write → Matt reviews workflow and prompts → small tests/evals → run one historical scenario through Fabro normally → consider fuller use.**

This document authorises none of those runs by itself. It does not renew an old allowance or permit a push/deployment.

## 1. Write the workflow and prompts; stop for review

The original five-prompt draft lived at `.fabro/workflows/bdd-implementation/`. Its successor is the smaller [scenario workflow](../../../.fabro/workflows/bdd-plan-implementation/scenario/workflow.fabro), described in its [README](../../../.fabro/workflows/bdd-plan-implementation/scenario/README.md).

Correction, 2026-10-16: Matt did not require Pi inside the workflow. The assistant mistakenly carried that detail over from the old prototype and created an unnecessary blocker. The revision uses Fabro's normal agent engine, `openai/gpt-5.6-sol` with high reasoning. No Pi SDK, ACP adapter, host bridge, custom provider or private server is required. The actual rehearsal results are recorded below.

- `workflow.fabro` and `workflow.toml`: the actual branches and loops, not a single box hiding the whole process.
- `prompts/bdd-navigator.md` and `prompts/bdd-driver.md`.
- `prompts/refactoring-navigator.md` and `prompts/refactoring-driver.md`.
- `prompts/review.md`: one review using architecture/ADRs, code design and idiomatic Elixir, spec adherence, UX and copy as appropriate. Copy uses [talking-to-humans](../../../.pi/skills/talking-to-humans/SKILL.md).
- Only small support needed beyond native Fabro context/routing and normal Docker test execution, plus a short README.

Use Fabro's normal agents with the workflow's configured Sol model and high reasoning throughout. Navigators retain their separate conversations through native context handling. Each delegated change gets a fresh driver. Final review starts without the implementation conversation. Document native restart/context limits honestly; do not build a new session platform.

The original plan paused here for Matt to review the workflow and complete prompts before testing. On 2026-10-16 he explicitly asked for a normal Fabro scenario run overnight. That later request authorises proceeding with this rehearsal without waiting for his review. Retain the actual files, prompts and results for him to review afterwards; do not claim unchecked code is validated.

The overnight attempt has one original deadline, **2026-10-16T13:03:37Z**, at most **three scenario-run launches**, and **600 aggregate operations** across all repairs. Use only throwaway trial/source/checkpoint branches needed for the normal run. No main push or deployment. The separate overnight admission record preserves that scope; no historical allowance is renewed.

Work on main as requested, without changing the existing workflows or committing unrelated staged numbering changes. After review, commit only the intended workflow/support changes. The real scenario trial must use Fabro's normal branch/source setup, not a special local-source injection path. If the normal setup needs a remotely available branch, obtain approval to push only the throwaway trial branch—not main.

## 2. Keep the role rules small and explicit

**BDD navigator:** read the code, plan one change and predict the next acceptance result. On the first change, also predict the initial failure. Driver checks that initial result before editing; a mismatch returns to navigator without edits. Later changes reuse the previous actual result if code, scenario and setup still match.

**BDD driver:** may run an inner unit-test red/green loop within the assigned change, predicting results before running tests. Acceptance guides the work. As soon as it reaches navigator's predicted next failure or expected green, stop and hand back—even if the scenario is still red. Do not solve the next obstacle. An unchanged known failure permits continued work on the same change; an unexpected acceptance result returns to navigator.

**Refactoring:** use a different navigator prompt and our CQRS, event-sourcing and responsibility guidance. Read all changes since work on the scenario began. Pick one worthwhile code smell at a time. Driver tests before editing; red means return untouched. After refactoring it may repair its own regressions until green or blocked. Use the scenario, relevant unit tests and affected earlier examples. Finish when no worthwhile cleanup remains, reserving time for final checks and review. Do not force a refactoring just to exercise the loop.

**Final review:** after all scenario work and refactoring, run full checks, then review the whole change through the applicable lenses. One combined list of concrete findings feeds one fix-and-review loop. Navigator checks findings and assigns repairs to fresh drivers, one change at a time. Rerun tests/full checks and review changed code again. Ordinary fixes do not need another approval; genuine scope/design decisions or exhausted limits do.

Keep one original deadline/work allowance across all roles and repairs. A test result must identify the actual source version, selected test and command exit. Match predicted outcomes by the relevant failure and reason, not a stray phrase or exact timestamps. Missing tests, setup failures, stale evidence and incomplete review cannot count as success. Preserve approved examples, assertions and authorisation rules.

## 3. After review, test a few parts in isolation

First test the small runner decisions without model calls: routing, source/result matching, test selection and limits. Then exercise the actual reviewed prompts with the requested model against small, controlled fixtures, using the same prompt files and role entry points as the workflow. Call these evals: each supplies a situation and checks what the agent actually does.

| Part | What to check |
| --- | --- |
| BDD navigator | Calls the shot before execution; uses an unexpected observation to reconsider instead of asking driver to blindly repair. |
| BDD driver | Initial mismatch causes no source edit. Matching baseline permits unit-test work. Reaching the predicted next acceptance failure stops it immediately; an unexpected result also returns to navigator. |
| Conversations | Navigator really keeps its conversation between visits; a later driver starts fresh. Verify actual session/request records, not just an agent saying it remembered. |
| Refactoring | Navigator sees the whole scenario diff. Driver leaves a red baseline untouched; it can repair a regression caused by its own refactoring. |
| Review and repair | Review follows refactoring/full checks, uses the code lenses correctly and returns one list. A real finding leads to a repair and another check/review, not repeated approval requests or separate loops per lens. |

Use a few fixture files and ordinary assertions over requests, commands, file changes and results. Do not grade only the agent's explanation or build another model-based judging system. Begin with one run per case; report every attempt and failure. Agree any repetitions before running them, not after seeing a result. Correct failures before moving on; do not dilute the expected behaviour to get green.

Run ordinary `dev check` on the exact implementation checkpoint after these tests pass. Keep prompt changes and eval results visible to Matt. Small eval success is not proof that the whole workflow works.

## 4. Run one historical scenario through Fabro normally

Use **“Alice's older edit requires confirmation of the newer name”** in [member_profile.feature](../../../acceptance-tests/features/member_profile.feature). Give Fabro a real implementation task on a throwaway branch, not a direct runner call or another eval harness.

1. Choose and record a Git commit from before the scenario was implemented. Create a throwaway branch in a separate worktree so main and its staged changes stay untouched.
2. Bring across the reviewed new workflow and the agreed scenario, preserving its wording and assertions. Retain the current tested runtime configuration needed to run the workflow. Record the setup diff; do not accidentally bring the finished product implementation along with it. Keep historical pending examples visible rather than silently dropping coverage. Missing step definitions are implementation work, not proof of an environment problem.
3. Launch the new workflow through the normal Fabro entry point, using the normal server, sandbox, branch checkout and checkpoints. Make the trial branch available to that launch in the usual way, with approval for any needed branch push. Do not use the existing delivery helper's main-publication path, a private proof server or an eval wrapper that bypasses the real workflow.
4. Let navigator predict the initial result before driver observes it. Let the workflow implement the selected scenario, refactor if worthwhile, run full checks and complete the single review/fix loop. Require exactly the selected scenario to execute; do not ask it to deliver the whole historical iteration.
5. Check that stale rejection and subsequent confirmation both work, relevant unit tests and final `dev check` pass, and no tests were weakened or manual coding repairs needed.

Keep the historical base, prepared trial commit, actual Fabro run ID, resulting code/checkpoints, observations, review result and cleanup evidence. Equivalent correct Elixir is fine; matching the old patch byte-for-byte is not the goal. A failed run stays failed with its branch and logs preserved.

Do not merge replay product changes into main: the feature is already delivered there. This tests the actual Fabro workflow on a known case, not novel problem solving, UX/copy review, every recovery path or whole-iteration autonomy.

## Overnight results — 2026-10-16

All three authorised launches used the normal Fabro server, managed Git clone, pinned Docker image and native API agents. The historical base was `5645fb62d50892b763f419f4b08e5d22b9a0e4bd`; only the approved stale-name example and new workflow were added before implementation began. Completed product code was not copied from main.

1. [First run](https://fabro.home.wynne.family/runs/01M51WR9N7CT1RWX9W9938FT0N) failed when the navigator's unit-test line selector selected no tests. That correctly did not count as green, but the controller wrongly made an ordinary selector correction terminal.
2. [Second run](https://fabro.home.wynne.family/runs/01M51Y5D2Y42021EYE1PHYB875) produced real command, aggregate, event and projection code. The aggregate tests passed. The driver correctly asked the navigator to include the missing command-dispatch file in its assignment; the controller wrongly refused an early, nonpassing handback.
3. [Third run](https://fabro.home.wynne.family/runs/01M5200JAVXEK2XYST6YG4KYRR) continued from that unaccepted native checkpoint, with factory fixes and the original budget preserved. No person manually repaired the product code. The selected scenario passed: **one executed, zero failures, 131 excluded**. The focused unit files passed **21 and four tests**, all against the same source. Nevertheless, the workflow **failed**: the current scenario was also listed as an earlier example, and the controller demanded a second record for that identical selection.

The third run supplies real evidence for two important rules: a wrong initial prediction returned without edits, and the navigator reconsidered it in the same native conversation. Two driver visits used different fresh sessions. The driver then stopped at the predicted green result rather than doing more work.

The controller fixes now have **54 isolated regression cases**, including the real failed selectors, handbacks and duplicate-selection evidence. Actual TOML validation passes. The last deduplication fix was **not** tried in another complete workflow: the three-launch limit was exhausted. It reuses the actual, current-source scenario observation rather than weakening a check or running the same scenario after the driver's stop point.

Refactoring, the workflow's final full check, and its combined review were **not reached**. A formatter call also failed with permission denied on the newly created step-definition file; its ownership or mount cause is not established. A passing scenario is not a completed or accepted delivery.

The campaign consumed **316 of 600 aggregate operations**. Native scenario-run cost estimates total **$19.737051**, not billing; coding-agent and other component costs are not included. Failed runs, raw artifacts and unaccepted Git checkpoints were retained. All three scenario containers were independently observed stopped/exited three times. No fourth scenario launch, main push, product merge or deployment was made. Main's existing staged numbering changes remain untouched.

The final factory source is `c380050bc26e479ddbf0910ebc84ce1c8e51e568`, preserved on the throwaway source branch. Its separate ordinary [`dev check`](https://fabro.home.wynne.family/runs/01M521K0C1FPSPT0BSEN9Y5Q23) passed at 09:54Z on that exact committed/pushed source: 19 package tests, 1,851 application tests and eight browser journeys/121 steps. All 2,623 tracked files' actual bytes/modes and Git metadata matched before/after. The ordinary responsive check correctly skipped a non-layout diff; the scenario jobs separately ran ten forced viewport checks each. This source-quality run does not turn the failed scenario workflow into a success. The files on main remain uncommitted for Matt's review. The parent kaizen stays **Open**; another complete rehearsal needs fresh authority.

## Limits and what counts as done

Before model evals or the replay, agree fresh finite time/work limits, including room for full checks, review and cleanup. Keep controller credentials outside the application container, reuse one exact-owned normal Docker runtime per job, keep its genuine browser/network preflight, verify committed source bytes/modes and retain original receipts. An uncertain launch acknowledgement is not permission to create a replacement. Observe exact-owned resources stably stopped afterwards.

The private runtime repair at `b3f071656326aa726174be52b0d4e6f60adb8c06` is a tested foundation, not proof of this workflow. Remote process caps remain unverified. Normal API export of the rehearsal's stored JSON and log artifacts was observed; that is not a guarantee for other artifact types. Do not claim broader runtime properties from this rehearsal.

The first version is ready for discussion of fuller use when Matt has reviewed the files, the small tests/evals pass, and the one-scenario replay finishes within its limits without manual repair. Report actual runs, failures, elapsed time and available usage figures. No broader reliability claim, main publication or deployment follows automatically.

Defer review fan-out, Credo integration, CRAP, standalone editorial work and general technical-task machinery. A technical task can later use a named executable check in place of a scenario; no invented Gherkin or forced red is needed. Keep the parent kaizen note **Open** until results justify changing it. The separate active experiment and historical admissions remain unchanged.
