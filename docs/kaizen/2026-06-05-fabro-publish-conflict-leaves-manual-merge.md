# Problem: Fabro publish conflict left a manual merge to recover

Date: 2026-06-05

## Context

Fabro iteration implementation run `01KTCDPDG5SWTYBV8QQYVE9S5C` was delivering `docs/iterations/021-staff-area-redesign/plan.md` to `main`. The workflow had completed implementation, validation, `dev_check`, plan conformance, and final artifact checks before `publish_to_main` tried to squash the work and rebase it onto the latest `origin/main`.

## Expected standard

The iteration implementation workflow should either publish the validated implementation to `main`, or stop with a clear, safe recovery path that preserves the implementation evidence and makes the next operator action obvious. A failed publish should not leave the repository in an ambiguous merge state or require manual archaeology to understand what failed.

## What happened

The run failed at `publish_to_main` while rebasing the squashed implementation commit onto `origin/main`:

- Run ID: `01KTCDPDG5SWTYBV8QQYVE9S5C`
- Squash commit attempted by the workflow: `c62e011` (`iteration 021: Staff area redesign and read-only operations indexes`)
- Conflicted files reported by Fabro:
  - `web/lib/memba_web/live/admin/deliveries_live/index.ex`
  - `web/lib/memba_web/live/admin/messages_live/show.ex`
- Fabro then entered `publish_failed` with the summary: `Iteration implementation failed: could not squash and push the implementation to main. Check push credentials, branch protection, and whether origin/main moved with conflicts.`

The local repository is now on `rescue-021-merge` at `origin/main`, with the implementation changes staged in the index and conflict recovery left for a human/operator.

## Impact

The implementation appears validated but was not merged. Delivery is blocked until someone resolves or safely replays the publish. The failure also creates risk that a later operator could accidentally commit, drop, or partially merge the staged implementation while trying to recover.

## What allowed it to happen

The publish step depends on a late rebase after all implementation and validation work has completed. When `origin/main` moved with conflicting changes, the workflow could detect the conflict but did not provide an automated conflict-prevention gate, a branch/PR fallback, or a precise recovery command sequence.

The failure message lists broad possibilities, but the system weakness appears to be weak publish-time conflict handling and recovery guidance: the workflow can leave a large, validated change set in a manual merge/rescue state without a standard, low-risk handoff.

## Observations

- The conflict was discovered only at the final publish step, after `dev_check` and plan conformance had passed.
- The failed publish involved a large implementation commit: Fabro reported 30 files changed in the squash commit, while run inspection reported broader implementation summary evidence.
- The rescue state contains many staged product changes, so ordinary `git commit` or reset commands could have unintended consequences.
- The top-level failure message does not name the conflicted files; those details are in the `publish_to_main` failure output from run inspection.

## Why this matters

Late publish conflicts turn an otherwise validated automated delivery into manual recovery work. Without a standard recovery path, each failure requires fresh investigation and increases the chance of lost work, duplicated validation, or an unsafe merge.

## Open questions

- Did another Fabro run or human commit change the same admin LiveViews between the run start and publish step?
- Should Fabro retry by creating a PR/rescue branch when direct publish conflicts, rather than leaving a staged local rescue state?
- What is the safest standard command sequence for operators to recover this specific class of failed publish?

## Possible prevention ideas

- Add a pre-publish freshness/conflict gate before expensive final validation, or repeat it immediately before squash.
- On publish conflicts, automatically preserve the squash commit on a named branch and print exact next steps.
- Include conflicted file names and recovery branch/commit identifiers in the `publish_failed` summary.
- Prefer a PR fallback for conflicted publishes so review and conflict resolution happen in a normal GitHub workflow.

## Resolution

Date: 2026-06-09

Root cause: the deterministic publish script treated late rebase conflicts as a terminal shell failure. It created the attempted implementation commit, but did not preserve that commit on a predictable rescue ref, did not surface structured conflict evidence to the workflow graph, and did not provide a bounded path for automatic conflict repair followed by validation.

Fix applied:

- `.fabro/workflows/iteration-implementation/scripts/publish_to_main.sh`: preserves every attempted publish commit on a `fabro/rescue/<run>-<iteration>-publish-conflict` branch before rebasing, pushes that branch when a rebase conflict occurs, prints the attempted commit, rescue branch, and conflicted files, and fails with explicit recovery guidance.
- `.fabro/workflows/iteration-implementation/workflow.fabro`: routes publish failures through a recovery gate that only invokes conflict recovery when unmerged files are present, records `.fabro/tmp/publish-conflict-evidence.md`, and sends successful conflict resolutions back through `dev_check` instead of pushing directly.
- `.fabro/workflows/iteration-implementation/prompts/resolve_publish_conflict.md`: adds a bounded agent prompt for mechanical conflict resolution, with fail-closed rules for product judgement, migrations, event schemas, security/authentication, or unclear behaviour.
- `.fabro/workflows/iteration-implementation/scripts/test_publish_to_main.sh`: covers both the happy publish path and the final-rebase-conflict path, including rescue branch publication and conflicted-file output.
- `.fabro/workflows/README.md`: documents that conflict-resolved publish candidates return through validation before reaching `main`.

Validation:

- `.fabro/workflows/iteration-implementation/scripts/test_final_artifact_gate.sh && .fabro/workflows/iteration-implementation/scripts/test_guard_acceptance_feature_changes.sh && .fabro/workflows/iteration-implementation/scripts/test_publish_to_main.sh` — passed.
- `dot -Tsvg .fabro/workflows/iteration-implementation/workflow.fabro >/tmp/iteration-implementation.svg` — passed graph parse/render.

Remaining follow-up:

- Observe the first real conflict-recovery run to tune the prompt and decide whether recurring conflict classes should get deterministic merge helpers.

### Additional observation: 2026-09-07 — the recovery gate lost a real lifecycle conflict

#### Context

Iteration-implementation recovery run `01M1YGGME8RMTSHTEFBNX3MY3Z` resumed iteration 058 from the failed run's durable checkpoint branch. It completed and validated tasks 019–022, passed the final `dev check`, plan-conformance gate, and final-artifact gate, then entered `publish_to_main`.

The earlier failed delivery had started from reservation commit `ebdc63b`, where iteration 058 was `implementing`. After that failure, `main` restored the iteration to `validated` so it would not occupy the WIP slot. The resumed run retained the reservation ancestry and, at publication, correctly attempted to mark the completed iteration `merged`.

#### Expected standard

When the final rebase finds a mechanical conflict, `publish_to_main.sh` should preserve the attempted artifact, materialize the conflict on the active run branch, and route through `publish_conflict_recovery_gate` to bounded resolution. A resumed run should not fail merely because failure recovery previously restored lifecycle metadata to `validated`.

#### What happened

The attempted implementation commit `5b8d20364` rebased onto `origin/main` with content conflicts in:

- `docs/iterations/058-generic-group-scoped-club-home/plan.md` — `Status: validated` on `main` versus `Status: merged` in the completed implementation;
- `docs/iterations/README.md` — the iteration 058 row had the same `validated` versus `merged` conflict.

No application-code conflict was reported. The script pushed the complete attempted artifact to `origin/fabro/rescue/unknown-058-publish-conflict` and said the workflow could route the state to conflict resolution. The immediately following `publish_conflict_recovery_gate`, however, found no unmerged paths and reported only:

```text
Publish failed, but the worktree does not contain conflict markers for agent recovery.
## fabro/run/01M1YGGME8RMTSHTEFBNX3MY3Z
?? .fabro/tmp/
```

The run therefore terminated at `publish_failed`; nothing reached `main` despite every implementation and quality gate having passed.

#### Impact

Publication of a validated 51-file implementation was blocked by two lifecycle-status lines. The artifact was preserved, but recovery again requires operator investigation and a deliberate replay through the final gates. This is delivery-blocking workflow friction rather than a product failure.

#### What allowed it to happen

Two workflow weaknesses aligned:

- Lifecycle restoration and resumed publication both edit the same duplicated status in the plan and iteration index, but publication has no deterministic rule for the expected `validated` to `merged` transition. Git therefore encounters a predictable textual conflict late in delivery.
- The conflict producer and recovery gate have a brittle handoff. `publish_to_main.sh` detects the conflict in a disposable rebase, then separately tries to materialize it on the active run branch. The gate accepts only live unmerged paths. In this run, the first step proved a conflict while the second left no conflict markers, so the gate discarded otherwise sufficient evidence and could not invoke the resolver.

The script suppresses output from the active-branch `git reset` and `git merge` attempt and does not report whether reset failed, merge unexpectedly succeeded, or some other materialization condition occurred. The exact reason conflict markers were absent is therefore not established by the run logs.

#### Observations

- Run: `01M1YGGME8RMTSHTEFBNX3MY3Z`.
- Last successful checkpoint: final artifact gate commit `c638cbb`; final `dev check` passed at checkpoint `df78e3a`.
- Attempted/rescued publication commit: `5b8d2036409f906b1e41f84a1f7130dbe3002b15`, parented at reservation commit `ebdc63b`.
- The rescue branch uses `unknown` instead of the actual Fabro run ID, weakening traceability even though the terminal output and commit trailers identify the run.
- This is the first observed real conflict-recovery run after the June fix recorded above. It shows that preserving the rescue artifact works, while automatic recovery still depends on successful conflict materialization.

#### Why this matters

Resume is the safety mechanism for long Fabro deliveries. If lifecycle restoration makes resumed publication conflict predictably, and recovery then requires ephemeral conflict markers rather than durable conflict evidence, a fully green implementation can repeatedly stop at the final step. That wastes validation time and makes successful recovery depend on Git archaeology.

#### Open questions

- Why did the active-branch conflict-materialization sequence leave no unmerged files after the disposable rebase reported two conflicts?
- Why was `FABRO_RUN_ID` unavailable to the publish script, producing an `unknown` rescue branch?
- Should lifecycle status conflicts be treated differently from product-code conflicts when the only valid completed state is `merged`?

#### Possible prevention ideas

- Add regression coverage for a resumed iteration whose `main` status was restored from `implementing` to `validated`, proving publication can advance it to `merged`.
- Make conflict handoff rely on durable attempted-commit/conflicted-path evidence, or fail explicitly when materialization fails, rather than reporting a generic absence of markers.
- Preserve and expose stderr/status from each conflict-materialization command so the recovery gate can distinguish reset failure, clean merge, and genuine unmerged state.
- Ensure rescue and recovery refs include the actual run ID.
