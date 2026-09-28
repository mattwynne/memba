# Problem: publish gate timed out validating a fresh worktree

Date: 2026-09-28

## Context

Iteration 066 (`docs/iterations/066-request-group-access/plan.md`) reached publication in Fabro run [`01M3JPCGJBCG3NVGR5FTBK3MMG`](https://fabro.home.wynne.family/runs/01M3JPCGJBCG3NVGR5FTBK3MMG). All nine tasks were accepted. The workflow's `dev_check`, plan-conformance, and final-artifact stages succeeded. The run branch is preserved at `origin/fabro/run/01M3JPCGJBCG3NVGR5FTBK3MMG`; `origin/main` was still `0692b0232` after failure.

Relevant machinery: `.fabro/workflows/iteration-implementation/workflow.fabro`, `scripts/publish_to_main.sh` in that directory, and `.fabro/workflows/scripts/attest_dev_check.sh`.

## Expected standard

Publication should rebase the completed implementation, run `./bin/dev check` on the exact clean commit it intends to push, record its attestation, and publish only after that check exits successfully. If validation cannot finish, it should preserve the candidate and report the failing boundary clearly, without treating a non-conflict failure as a merge conflict.

## What happened

The workflow's earlier `dev_check` completed in 269.7 seconds. `publish_to_main.sh` then constructed a candidate, marked the iteration merged **in that candidate only**, and successfully rebased it onto `origin/main`. Its attestation helper started a second full `./bin/dev check` in a newly created disposable worktree at commit `900e52fc4682205e121aacbb1f480d172f57e016`.

The `publish_to_main` workflow node has `timeout="300s"`. It timed out after about 302 seconds while the fresh worktree's check was still running. The captured output shows devenv setup, a fresh npm install and dependency compilation, then ExUnit progress. The publish command began at 02:10:18.485 UTC, making its 300-second deadline approximately 02:15:18.485. PostgreSQL reported `ERROR 58P01 (undefined_file) could not open file "base/16389/132626"` (and another missing file) at 02:15:19.387, **after that deadline but before** the stage failure was recorded at 02:15:20.895. The output contains an untimestamped shell `Killed` line before those errors. A `tcp recv: closed` warning at 02:15:13.000 preceded the deadline; a similar warning occurred during the earlier successful check at 02:08:16.892. The timeout could have initiated cleanup of the disposable worktree while its database was still in use, but the dump does not establish that cleanup occurred, where PostgreSQL stored its data, or what caused either connection warning. A single cause for all symptoms is unproven.

The workflow sent the failed publish through `publish_conflict_recovery_gate`, which said there were no conflict markers, and then `publish_failed`. Its terminal message was generic: `goal gate unsatisfied for node publish_to_main and no retry target`. Nothing was pushed to `main`.

Separately, the preserved run branch contains `.fabro/workflows/iteration-implementation/scripts/__pycache__/delivery_planner_state.cpython-313.pyc`. The worker had identified that generated directory as untracked, and the operator selected “Ignore and continue” rather than delete it. The publish script's `stage_publish_artifact` stages all untracked, non-ignored files outside `.fabro/tmp`, so the attempted candidate also contained this bytecode. This did **not** cause the timeout, but it is an independent artifact-hygiene risk discovered during recovery inspection.

## Impact

Delivery is blocked despite accepted tasks and a passing earlier full gate. The published state has no exact-commit attestation; it correctly did not reach `main`. Recovery requires reconstructing a clean candidate, investigating the database error, and rerunning exact-commit validation rather than trusting the earlier run-branch check. The failure classification and generated artifact increase manual recovery work.

## What allowed it to happen

The publication node combines Git preparation with a full fresh-checkout validation under a fixed five-minute budget, while the ordinary workflow-owned full gate alone took almost that long. No preflight compared that budget to cold setup plus test time. The fallback after **any** publish failure checks only for conflict markers and otherwise emits a generic failure, obscuring the timed-out validation. The staging policy also does not exclude or reject generated Python bytecode before creating the publish candidate.

## Evidence retained and limits

- The complete Fabro run export was gathered with `fabro dump 01M3JPCGJBCG3NVGR5FTBK3MMG --output /tmp/memba-066-publish-failure-evidence`; it contains `events.jsonl`, `run.log`, checkpoints, and `stages/046-publish_to_main@1/output.log`, `status.json`, and `script_timing.json`. The server-side run remains the durable source; the `/tmp` export is a local working copy, not a repository artifact.
- The publish command's stored output is run blob `sha256/2383e8ab2e5ba646e6b1149fa5d4c0509e90a6827e8621d94d6d35610656dfee` (26,748 output bytes). `script_timing.json` records `duration_ms: 302400` and `termination: timed_out`. The output shows an OS `Killed` message just before the 02:15:19 PostgreSQL errors; it does not identify what killed that process.
- The saved output establishes no successful exit from the publish-candidate check. It does not include separate PostgreSQL server logs, actual `PGDATA`/`PGHOST`, process or kill provenance, surviving database state, or a reproducer of the missing-file error. The disposable publish worktree and run sandbox were removed/stopped after failure. A read-only journal query from this development host returned no kernel entries for the interval; it is not the Fabro container host. Those boundaries remain unverified.

## Open questions

- What produced PostgreSQL's missing-file errors just before the deadline? Did the fresh worktree's managed service interact with an earlier service or cleanup?
- How long does exact-commit validation take in a healthy cold publish worktree, and what budget or isolation contract is appropriate?
- Should a non-conflict publish failure preserve a named candidate and its command output as an explicit recovery handoff?
- Why did final artifact checks not reject generated `.pyc` files before the publish stage?

## Possible prevention ideas

- Budget the publish node against measured cold-worktree setup and full-check duration, and distinguish validation timeout or infrastructure failure from a Git conflict.
- Preserve a fetchable, clean candidate and phase-specific failure evidence for non-conflict publish failures.
- Prevent generated caches from being staged, and assert publish-candidate hygiene before expensive exact-commit validation.
