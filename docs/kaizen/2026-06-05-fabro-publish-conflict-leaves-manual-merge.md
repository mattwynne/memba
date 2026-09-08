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

When the final rebase finds a mechanical conflict, the workflow should preserve the attempted artifact and give its existing resolver agent enough evidence to reconstruct and resolve the conflict safely. Any unfinished merge must be created and resolved within one agent node; it must not depend on Git index state surviving Fabro's automatic checkpoint between nodes. A resumed run should not fail merely because failure recovery previously restored lifecycle metadata to `validated`.

#### What happened

The attempted implementation commit `5b8d20364` rebased onto `origin/main` with content conflicts in:

- `docs/iterations/058-generic-group-scoped-club-home/plan.md` — `Status: validated` on `main` versus `Status: merged` in the completed implementation;
- `docs/iterations/README.md` — the iteration 058 row had the same `validated` versus `merged` conflict.

No application-code conflict was reported. The script pushed the complete attempted artifact to `origin/fabro/rescue/unknown-058-publish-conflict` and successfully materialized the merge conflict on the active run branch. Fabro then automatically checkpointed the failed `publish_to_main` node. Checkpoint `b0cec7b` committed the merge and its literal conflict-marker text, thereby clearing Git's unmerged index entries.

The immediately following `publish_conflict_recovery_gate` checked only for live unmerged paths with `git diff --diff-filter=U`. It found none and reported:

```text
Publish failed, but the worktree does not contain conflict markers for agent recovery.
## fabro/run/01M1YGGME8RMTSHTEFBNX3MY3Z
?? .fabro/tmp/
```

The workflow never invoked its `resolve_publish_conflict` agent. The run terminated at `publish_failed`; nothing reached `main` despite every implementation and quality gate having passed.

#### Impact

Publication of a validated 51-file implementation was blocked by two lifecycle-status lines. The artifact was preserved, but the active run branch now contains committed conflict markers and recovery again requires operator investigation. This is delivery-blocking workflow friction rather than a product failure.

#### What allowed it to happen

Two workflow weaknesses aligned:

- Lifecycle restoration and resumed publication both edit the same duplicated status in the plan and iteration index, but publication has no semantic rule for the expected `validated` to `merged` transition. Git therefore encounters a predictable textual conflict late in delivery.
- The conflict producer and resolver communicate through ephemeral Git index state across a mandatory Fabro checkpoint. The checkpoint turns an unfinished merge into an ordinary marker-bearing commit before the gate can inspect it. Existing tests call the publish script and inspect `U` paths immediately, so they do not model this node boundary.

The automatic recovery protocol therefore failed before agent reasoning was attempted. The resolver agent was capable of inspecting the rescue commit and current `origin/main`, but the gate prevented it from receiving the task.

#### Five Whys

| Why | Answer | Status |
| --- | --- | --- |
| 1. Why was the validated implementation not published? | Replaying its squash commit onto current `main` conflicted in two lifecycle-status lines. | Fact |
| 2. Why did those lines conflict? | Both descendants changed the reservation state `implementing`: failure recovery changed it to `validated`, while completed delivery changed it to `merged`. | Fact |
| 3. Why did automatic conflict resolution not run? | `publish_conflict_recovery_gate` found no live unmerged index entries and routed to `publish_failed`. | Fact |
| 4. Why were there no unmerged entries after conflict materialization succeeded? | Fabro's automatic failed-node checkpoint committed the marker-bearing merge as `b0cec7b`, normalizing the index before the next node. | Fact |
| 5. Why did checkpointing erase the recovery signal? | The workflow passes an unfinished Git merge between nodes even though Fabro checkpoints at every node boundary; the regression test does not emulate that boundary. | Root cause |

A second systemic contributor is that lifecycle states have semantic ordering but are merged as duplicated ordinary text in two files.

#### Observations

- Run: `01M1YGGME8RMTSHTEFBNX3MY3Z`.
- Last successful checkpoint before publication: final artifact gate commit `c638cbb`; final `dev check` passed at checkpoint `df78e3a`.
- Attempted/rescued publication commit: `5b8d2036409f906b1e41f84a1f7130dbe3002b15`, parented at reservation commit `ebdc63b`.
- Recovery candidate `c4d10a4` contains the `merged` lifecycle state. Checkpoint `b0cec7b` is a merge commit whose tree contains literal conflict markers in both lifecycle files.
- The remote run branch still contains those committed markers; the remote rescue branch preserves the clean completed artifact.
- The rescue branch uses `unknown` instead of the actual Fabro run ID. Fabro documents `FABRO_RUN_ID` for command hooks, not ordinary workflow command nodes; tests currently inject it manually.
- This is the first observed real conflict-recovery run after the June fix recorded above. Preservation worked, but the resolver handoff did not.

#### Why this matters

Resume is the safety mechanism for long Fabro deliveries. If lifecycle restoration makes resumed publication conflict predictably, and the recovery workflow cannot survive its own checkpoint boundary, a fully green implementation can repeatedly stop at the final step. Committing conflict markers also leaves a more hazardous run branch than preserving a clean implementation and asking an agent to perform the merge in one bounded step.

#### Resolution options

Date: 2026-09-07

1. **Route publish conflicts directly to the existing resolver agent — recommended.** On conflict, preserve the rescue commit, restore or retain a clean active run branch, and route to `resolve_publish_conflict` without first materializing an unfinished merge or requiring `U` entries. The agent fetches current `origin/main`, reconstructs and resolves the merge within its own node, and stops for human input when resolution requires product judgement. Successful resolution returns through `dev_check`, plan conformance, final artifact checks, and publication as it does today.
2. **Pass a durable conflict descriptor and rematerialize in the resolver.** Record exact SHAs and conflicted paths, have a deterministic gate validate them, then let the resolver reconstruct the merge. This is more explicit and can fail closed before model use, but adds protocol and validation machinery beyond what the existing rescue commit and Git history may require.
3. **Publish a rescue pull request for human resolution.** This removes automatic conflict resolution from Fabro and uses a familiar durable workflow, but makes every conflict manual and needs an explicit policy for rerunning the delivery gates.

Recommendation: choose option 1. The agent is already present and is the correct boundary for interpreting conflicts. Remove the broken cross-node index-state handoff rather than adding another recovery layer. The agent must finish with no unmerged paths or conflict markers; ambiguous product, migration, event-schema, security, or authentication conflicts remain human decisions. The remote rescue commit remains the durable fallback.

#### Validation plan

- Extend `.fabro/workflows/iteration-implementation/scripts/test_publish_to_main.sh` with the exact resumed lifecycle case: base `implementing`, current `main` restored to `validated`, and completed implementation advancing to `merged`.
- Exercise the real workflow boundary or emulate Fabro's failed-node checkpoint so a test cannot pass merely because it inspects `U` entries immediately after the script.
- Prove the workflow routes a rebase conflict to the resolver agent without committing marker-bearing files.
- Prove the resolver can merge current `main`, select `merged` for the mechanical lifecycle transition, leave a clean candidate, and return through all final gates.
- Retain a genuine product-code conflict case that requires bounded agent resolution or human input.
- Cover absent `FABRO_RUN_ID` and derive traceability from a supported workflow input, the current `fabro/run/<id>` branch, or commit metadata.

Status: awaiting implementation decision.

#### Open questions

- Should every publish failure reach the resolver agent for classification, or should `publish_to_main` expose a small durable conflict/non-conflict signal without recreating a full recovery gate?
- What supported source should publication use for the run ID in ordinary command nodes?
