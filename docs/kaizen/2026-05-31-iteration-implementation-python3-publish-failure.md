# Problem: implementation workflow publish depends on missing sandbox Python

Date: 2026-05-31

## Context

We ran the Fabro `IterationImplementation` workflow for `docs/iterations/008-postmark-email-integration/plan.md`.

Run: `01KSYDGE493407G865AWRP1409`

Web UI: `https://fabro.home.wynne.family/runs/01KSYDGE493407G865AWRP1409`

The workflow completed the task loop, `dev check`, evidence collection, and plan conformance for the Postmark email integration iteration. The implementation work was checkpointed and available on `origin/fabro/run/01KSYDGE493407G865AWRP1409`.

## Expected standard

A validated implementation run should either publish a single clean implementation commit to `main`, or fail early with a clear preflight signal that the sandbox cannot run the required workflow scripts.

The workflow's `Preflight Sandbox Toolchain` step is expected to prove the sandbox has the tools required by later gates and publish scripts.

## What happened

The run failed after successful implementation and validation:

```text
✓ Run Dev Check
✓ Collect Implementation Evidence
✓ Plan Conformance Gate
✓ Plan conformant?
✗ Final Artifact Gate
Error: /bin/bash: line 73: python3: command not found
✗ Publish Implementation to Main
Error: .fabro/workflows/iteration-implementation/scripts/publish_to_main.sh: line 29: python3: command not found
✗ Fail: Publish to Main
Error: Iteration implementation failed: could not squash and push the implementation to main.
```

The missing executable was not an application dependency. It was a workflow dependency: both the final artifact gate and `.fabro/workflows/iteration-implementation/scripts/publish_to_main.sh` invoke `python3` to run `.fabro/workflows/iteration-implementation/scripts/guard_acceptance_feature_changes.py`.

A manual recovery attempt showed that the implementation diff could be applied from the remote run branch and validated locally. `dev check` passed in the recovery worktree with `129 tests, 0 failures`. Publishing still required manual care because `main` moved after the run: a direct push of the recovered commit was rejected as non-fast-forward after other commits reached `origin/main`.

## Impact

The product implementation was valid enough to pass the workflow's validation gates, but delivery still failed at the final publish boundary. This created manual rescue work, delayed the iteration, and increased the risk of mis-merging implementation work once `main` continued moving.

The failure also made the run look like an implementation failure even though the abnormality was in the workflow runtime contract.

## What allowed it to happen

The workflow runtime contract was incomplete. The sandbox preflight did not verify every executable used by later workflow gates and scripts.

The scripts also depended on a host-level `python3` command rather than either:

- ensuring Python is present in the sandbox toolchain; or
- invoking the guard through a runtime already guaranteed by the workflow environment; or
- failing before the expensive implementation loop begins.

Because the missing dependency was discovered only after implementation, validation, and plan conformance, the workflow accumulated valuable work before hitting a preventable environment error.

## Observations

- `Preflight Sandbox Toolchain` passed even though a later required command, `python3`, was unavailable in the sandbox.
- The final artifact gate and publish script share the same hidden dependency on `python3`.
- The acceptance-feature guard is workflow machinery, not product code, but its runtime dependency was not declared or checked.
- The implementation branch existed remotely, so recovery was possible by applying `b5b84aabcafb5cdfb34154ed46a2df6745a19cfa..origin/fabro/run/01KSYDGE493407G865AWRP1409` onto current trunk and revalidating.
- Manual recovery became more complex once unrelated commits reached `main` after the failed run.

## Why this matters

Late workflow-tool failures waste the most expensive part of an implementation run: the validated code exists, but the automated publish path cannot complete. Repeated occurrences would turn Fabro delivery into manual archaeology and make trunk integration riskier.

## Open questions

- Should workflow validation derive required executables from gate scripts, or should each workflow declare an explicit toolchain contract?
- Should `guard_acceptance_feature_changes.py` remain Python, or should it be implemented in a runtime already guaranteed by the sandbox?
- Should publish recovery be a first-class command when a run has passed validation but failed only at finalization?

## Possible prevention ideas

- Add `python3` to the implementation sandbox preflight check, or remove the Python dependency from final gates and publish scripts.
- Add a workflow-level smoke test that executes every local helper script used by finalization with `--help` or a harmless fixture before implementation begins.
- Make publish failures distinguish between product validation failures and workflow/runtime failures, with a clear recovery command when the run branch contains validated work.
