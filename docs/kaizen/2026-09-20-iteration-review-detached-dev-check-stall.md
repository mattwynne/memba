# Problem: code review repair left a detached dev check running into the workflow gate

Date: 2026-09-20

## Context

Iteration 063 review run `01M2HKG92Q13FYYVXTN083WF97` reviewed `docs/iterations/063-add-custom-group-members/plan.md` from `2026-09-15T04:00:36Z` to `2026-09-15T05:39:05Z`.

Checked for matching kaizen notes before creating this note. Related notes already existed for implementation-loop full-gate cost and timeouts, especially:

- `docs/kaizen/2026-09-03-iteration-workflow-timeout-masks-test-failure.md`
- `docs/kaizen/2026-09-14-test-feedback-cost-outgrew-implementation-loop.md`
- `docs/kaizen/2026-09-05-review-repair-evidence-ignored-staged-changes.md`

Those notes cover implementation-loop broad checks, task timeouts, and a prior review-repair verifier defect. No existing note matched this code-review-specific detached-process stall.

Relevant machinery:

- `.fabro/workflows/code-review/workflow.fabro`
- `.fabro/workflows/code-review/prompts/apply_review_fixes.md`
- `bin/dev` quality-gate locking around `dev check`, `dev ci`, `dev test`, and `dev acceptance`

## Expected standard

The review-repair node should apply the bounded synthesis request, run only focused validation needed to prove that repair, and then return control to deterministic workflow gates:

```text
apply_review_fixes -> verify_review_repair -> dev_check
```

The workflow-owned `dev_check` node should be the full-suite authority after review polish. A repair prompt should not leave a detached full-suite process running that can collide with the next scripted gate.

## What happened

The three independent reviewers accepted the implementation. Review synthesis requested one bounded repair, `strengthen-membership-command-boundary-test`.

`apply_review_fixes` changed `web/test/memba_web/membership_command_boundary_test.exs`, ran a focused one-test validation successfully, then delegated the full gate to a subagent. The subagent launched a detached background check:

```sh
nohup sh -c 'repo=$1; result_dir=$2; PATH="$repo/bin:$PATH"; export PATH; dev check; check_status=$?; printf "%s\n" "$check_status" > "$result_dir/exit-status.tmp"; mv "$result_dir/exit-status.tmp" "$result_dir/exit-status"; exit "$check_status"' sh "$PWD" "$log_dir" </dev/null >"$log_dir/dev-check.log" 2>&1 &
```

The detached process wrote logs under `/tmp/memba-dev-check.mWMChe/` and was still running browser acceptance when the prompt-node budget expired. The parent had switched to a long polling loop:

```text
The check is still progressing through acceptance scenarios. I’m switching to one bounded monitoring loop that checks the detached process every 55 seconds...
```

Fabro timed out `apply_review_fixes` at its 2,400-second handler timeout:

```text
handler timed out after 2400000ms
```

The graph's unconditional edge still routed to `verify_review_repair`, which succeeded. It then routed to `dev_check`. The second `dev_check` visit started at `2026-09-15T05:09:03Z` with:

```sh
PATH="$PWD/bin:$PATH" dev ci
```

No further activity was recorded for that node. At `2026-09-15T05:39:03Z`, the stall watchdog failed the run:

```text
stall watchdog: node "dev_check" had no activity for 1800s
```

The run failed even though the repair diff was preserved at final commit `8ed31ce3b8b2dcde82f74fe88ba00c6920dc48a7`.

## Impact

Severity: delivery-machine stall and wasted review time.

The workflow had already paid for independent review, synthesis, a bounded repair, and a successful repair verifier. It then spent another 30 minutes with no useful workflow output and failed before publishing review polish or finalizing the iteration. Operators had to inspect run events to see that the actionable failure was a detached validation process from the previous prompt node, not a reviewer disagreement or product-code assertion.

## What allowed it to happen

- `apply_review_fixes.md` did not explicitly reserve full-suite validation for the following workflow-owned `dev_check` node.
- The repair prompt did not prohibit subagents, detached/background test processes, `nohup`, or long polling loops.
- `bin/dev` serializes quality gates with a per-Postgres-port lock. A detached `dev check` can therefore collide with the next workflow `dev ci` in the same sandbox.
- The review graph allowed a timed-out `apply_review_fixes` node to continue through `verify_review_repair -> dev_check` when repository state changed, but it had no guard that the timed-out agent had left no background validation process behind.
- Fabro recorded the next `dev_check` as a command start and then had no activity until the 1,800-second stall watchdog fired, so the terminal failure named the silent gate rather than the earlier detached-process boundary violation.

## Observations

- The initial workflow `dev_check` passed before independent reviews.
- The repair's focused validation passed: `1 test, 0 failures` for `membership_command_boundary_test.exs` through a direct ExUnit invocation.
- The detached background `dev check` was not required by the graph; the graph already runs `dev_check` after `verify_review_repair`.
- The detached check was still producing browser acceptance output at `05:06Z`, shortly before `apply_review_fixes` timed out at `05:08:54Z`.
- The final failure was deterministic workflow inactivity: `stall watchdog: node "dev_check" had no activity for 1800s`.

## Why this matters

Review runs are meant to be bounded fix-forward polish after implementation has already merged. If a repair node can start an unowned full gate that survives into the deterministic full-gate node, the workflow can stall after successful review evidence and repair verification. That creates manual archaeology, wastes provider/runtime budget, and weakens trust in review automation.

## Open questions

- Should the graph add an executable no-background-quality-gate guard before `dev_check`, or is prompt plus contract-test prevention enough for this specific failure mode?
- Does Fabro expose enough sandbox process information to make a generic detached-process guard reliable without false positives?
- Should timed-out prompt nodes route differently when they left a valid diff but did not return a final summary?

## Possible prevention ideas

- Make `apply_review_fixes` explicitly single-owner and focused-validation-only; reserve `dev check`/`dev ci` for the scripted workflow gate.
- Add a prompt-contract regression that fails if the review-repair prompt stops prohibiting broad or detached validation.
- Consider a future pre-`dev_check` guard that detects live quality-gate locks/background test processes and fails with a diagnostic instead of waiting silently.

## Resolution

Date: 2026-09-20

Root cause: the review-repair prompt left ownership of final validation ambiguous. It allowed the repair agent to delegate and launch a detached full-suite `dev check` even though the graph already runs `verify_review_repair -> dev_check`. That unowned process could keep using the same sandbox quality-gate resources after the prompt node timed out, so the following scripted `dev_check` stage had no useful activity until Fabro's stall watchdog failed it.

Fix applied:

- `.fabro/workflows/code-review/prompts/apply_review_fixes.md`: made the repair node single-owner, prohibited subagents/delegated validation, restricted repair validation to focused commands, reserved `dev check`/`dev check --quick`/`dev ci` and other unscoped full-suite commands for the workflow-owned post-verifier gate, and prohibited detached/background test processes, `nohup`, and over-budget polling.
- `.fabro/workflows/code-review/scripts/test_review_report_routing.sh`: added contract checks so the review workflow test fails if those repair-boundary rules disappear, and corrected the verifier-contract assertion to inspect the delegated verifier script rather than stale inline graph text.
- `.fabro/workflows/code-review/scripts/test_finalize_iteration_status.sh` and `.fabro/workflows/code-review/scripts/test_publish_polish_to_main.sh`: set the temporary bare origin's `HEAD` to `main` so the existing git-fixture tests clone the intended branch reliably during validation.
- `docs/kaizen/2026-09-20-code-review-detached-dev-check-stall.md`: recorded the observation, cause analysis, countermeasure, validation, and follow-up.

Validation:

- `bash .fabro/workflows/code-review/scripts/test_review_report_routing.sh` — passed.
- `for f in .fabro/workflows/code-review/scripts/test_*.sh; do bash "$f"; done` — passed all code-review shell contract/helper tests.
- `fabro validate .fabro/workflows/code-review/workflow.toml --no-upgrade-check` — validation OK; retained the pre-existing `finalize_iteration_status` goal-gate warning.
- `env -u MEMBA_DEVENV_SHELL ./bin/dev check` — passed: 1,529 ExUnit tests with 0 failures; 189 browser scenarios / 1,415 steps passed.

Check / expected result:

- Expected: future review-repair agents will run focused proof for bounded changes and then return; the only full post-repair gate is the deterministic `dev_check` node.
- Observed now: prompt-contract tests prove the instruction boundary is present. A later live review run is still needed to demonstrate agent adherence and absence of recurrence.

Remaining follow-up:

- If a later run still leaves background validation behind, add an executable pre-`dev_check` guard that detects live quality-gate locks or background `dev`/Cucumber/Mix processes and fails with a diagnostic instead of waiting for the stall watchdog.
