# Problem: Fabro implementation run required manual rescue after publish failure

Date: 2026-05-30

## Context

We were rescuing implementation work from Fabro run `01KSXZQ3ZR4RBHVZKG5ZARSE32` for `docs/iterations/006-browser-cucumber-automation/plan.md`.

The run had completed implementation, validation, `npm test` in `acceptance-tests/`, `dev check`, and plan conformance, but did not publish to `main`.

## What happened

The run failed at `Publish Implementation to Main` with:

```text
Refusing to publish implementation: locked acceptance feature files changed.
acceptance-tests/features/operator_email_deliverability.feature
```

At the same time, Fabro repeatedly warned that it could not push the run branch:

```text
Failed to push run branch fabro/run/01KSXZQ3ZR4RBHVZKG5ZARSE32
```

The event log showed GitHub rejected the run branch because the checkpoint history contained an oversized file:

```text
File acceptance-tests/core is 252.54 MB; this exceeds GitHub's file size limit of 100.00 MB
GH001: Large files detected.
```

Manual rescue was needed. The rescue recovered the implementation patch, restored the necessary `@todo-ui` feature tag, fixed local harness drift around `bin/dev up`, aligned Playwright with the Nix browser revision, re-ran validation, merged a clean commit to `main`, and pushed with HTTPS after SSH push failed.

## Observations

- The publish failure hid otherwise valid implementation work behind a final gate failure.
- The locked-feature guard was too blunt for this iteration: the plan explicitly allowed a narrow browser partition tag, but the final publish script rejected the changed `.feature` file.
- The run branch could not be pushed because a generated `acceptance-tests/core` file had entered checkpoint history before `.gitignore` was updated.
- Because the run branch push failed, recovering the final state depended on local Fabro metadata/events and manual patch reconstruction rather than simply checking out a remote branch.
- The rescued code also exposed drift between the browser lifecycle and current `bin/dev up`: `bin/dev up` starts Phoenix and does not return, so using it as a Postgres-readiness command caused local acceptance runs to time out.
- Local validation exposed Playwright/Nix browser revision mismatch when package versions drifted away from `pkgs.playwright-driver.browsers`.

## Why this matters

A successful implementation can become expensive to recover if the publish gate, checkpoint branch push, and local validation environment each fail in different ways. This creates avoidable manual archaeology and increases the risk of losing or mis-merging valid work.

## Open questions

- Should the implementation publish guard allow explicitly planned acceptance-tag changes, or require an explicit workflow input for permitted `.feature` edits?
- Should Fabro prevent oversized generated files from entering checkpoint history before attempting to push run branches?
- Should the acceptance harness have a first-class `bin/dev postgres`/service-readiness contract documented before implementation workflows depend on it?
- Should `devenv.nix` or acceptance tests assert that the installed Playwright package version matches `pkgs.playwright-driver.browsers`?

## Resolution options

Date: 2026-05-30

Root cause: This was not primarily an upstream-main drift problem. The implementation publish script already fetches `origin/main` and runs `git pull --rebase origin main` before pushing. The expensive rescue came from two earlier resilience gaps: the final publish guard had no way to distinguish an explicitly planned acceptance tag-only edit from an accidental `.feature` change, and Fabro checkpoint history already contained an oversized generated `acceptance-tests/core` file, so the run branch could not be pushed for normal recovery.

Options:

1. Add an explicit planned feature-edit allowance — for example a workflow input or plan metadata listing allowed `.feature` files and restricting their diffs to tag-only changes. Benefit: keeps the locked-feature guard while allowing iterations like browser partitioning. Cost/risk: adds policy surface and must avoid becoming a broad bypass.
2. Add a checkpoint-size/generated-file defence — at minimum keep `acceptance-tests/core` ignored/excluded and prefer running acceptance tests through a wrapper that disables/removes core dumps; ideally Fabro itself should reject or skip blobs over the remote host limit before checkpoint commits enter history. Benefit: preserves pushed run branches for recovery. Cost/risk: repository-side guards cannot fully protect against files created inside arbitrary agent commands immediately before Fabro checkpoints.
3. Rebase earlier, before final validation — fetch/rebase onto current `origin/main` before `dev ci` and plan conformance, not only inside publish. Benefit: validates the final implementation against current trunk and surfaces conflicts before the last publish step. Cost/risk: does not address the observed locked-feature or oversized-blob failures; conflict handling still needs a clear stop/resume path.
4. Make recovery independent of remote run-branch push — document a deterministic local rescue command that extracts the final checkpoint patch from Fabro metadata/events when `origin/fabro/run/<id>` is unavailable. Benefit: reduces archaeology when the remote branch cannot be pushed. Cost/risk: fallback only; it does not prevent the failure.

Recommendation: implement options 1 and 2 first. Add option 3 as a nice hardening step because it moves trunk-drift conflicts earlier, but do not expect rebasing alone to prevent this class of rescue. Option 4 is useful documentation after the preventive fixes.

Validation plan:

- `fabro validate .fabro/workflows/iteration-implementation/workflow.toml` after any workflow-input or guard changes.
- A targeted shell test for allowed tag-only feature diffs versus rejected scenario-text feature diffs.
- A smoke run or local script check proving `acceptance-tests/core` is ignored/excluded and not present in publish/checkpoint candidate paths.

Status: accepted; implemented the explicit-plan-permission path for acceptance feature edits.

## Resolution applied

Date: 2026-05-30

Root cause: Plan validation allowed an iteration to require acceptance `.feature` edits while implementation and publish treated every `.feature` diff as forbidden. The lock was right by default, but too blunt: it could not distinguish unplanned acceptance-criteria drift from an explicitly approved feature-file change in the plan.

Fix applied:

- `.fabro/workflows/iteration-implementation/scripts/guard_acceptance_feature_changes.py`: added a deterministic publish/final-gate guard. `.feature` files are locked by default; edits are allowed only when the plan contains `## Allowed acceptance feature changes` naming the exact file. If the permission says `tag-only`, non-tag Gherkin line changes are rejected.
- `.fabro/workflows/iteration-implementation/scripts/publish_to_main.sh`: replaced the blanket `.feature` rejection with the new guard.
- `.fabro/workflows/iteration-implementation/workflow.fabro`: final artifact gate now runs the same guard before publish.
- `.fabro/workflows/iteration-implementation/prompts/`: aligned implementation, validation, repair, and review-synthesis prompts with the explicit-plan-permission rule.
- `.fabro/workflows/plan-validation/prompts/`: taught plan validation to fail plans that expect shared `.feature` edits without an explicit allowed-change section naming files, change kind, reason, and coverage preservation.
- `.fabro/workflows/README.md`: documented the plan section format and tag-only enforcement.
- `docs/iterations/007-deliveries-overview/plan.md`: added the explicit allowed feature-change section for the already planned operator feature remodel.

Validation:

- `.fabro/workflows/iteration-implementation/scripts/test_guard_acceptance_feature_changes.sh` — passed; covers rejected unplanned feature edits, allowed tag-only edits, rejected non-tag edits under tag-only permission, and allowed explicitly planned non-tag edits.
- `python3 -m py_compile .fabro/workflows/iteration-implementation/scripts/guard_acceptance_feature_changes.py` — passed.
- `fabro validate .fabro/workflows/iteration-implementation/workflow.toml` — passed with existing goal-gate retry warnings.
- `dev check` — passed.

Remaining follow-up:

- Consider an upstream Fabro oversized-blob checkpoint guard separately; this fix addresses the planned `.feature` edit failure, not the core-dump push failure.

## Additional observation: 2026-06-08

### Context

While delivering `docs/iterations/029-membership-admin-invitations/plan.md`, Fabro implementation run `01KTKQWKQR3PQPNVTEZRWRF29T` completed all implementation tasks and reached the final validation/conformance path.

The plan explicitly names the shared feature file under `## Allowed acceptance feature changes`:

```text
acceptance-tests/features/club_member_invitations.feature: implement the planned Membership Admin scenarios tagged @iteration-029; during delivery, remove or narrow @todo-domain/@todo-ui only when the covered behaviour passes in the relevant runner.
```

The run branch also contains that section at `docs/iterations/029-membership-admin-invitations/plan.md` lines 84-87.

### Expected standard

A behaviour-facing iteration whose plan explicitly permits a named `.feature` file should be able to remove/narrow todo tags for passing planned scenarios without manual intervention, provided the implementation keeps covered behaviour green and `dev check` passes.

The locked-feature guard should distinguish:

- unplanned acceptance-criteria drift, which should stop the run; from
- explicitly planned and permitted feature-file changes, which should pass the final gates.

### What happened

The implementation completed and reported a green final validation task:

```text
PATH="$PWD/bin:$PATH" dev check
ExUnit: 746 tests, 0 failures
Browser acceptance: 72 scenarios (72 passed), 479 steps (479 passed)
```

During plan-conformance repair, Fabro removed `@todo-ui` from the primary `@iteration-029` scenario in `acceptance-tests/features/club_member_invitations.feature` and updated `acceptance-tests/features/support/membership_administration.js` so the now-running scenario used the remembered invited email address.

`verify_plan_repair` then failed with:

```text
Committed files changed after repair:
acceptance-tests/features/club_member_invitations.feature
acceptance-tests/features/support/membership_administration.js
Working-tree files changed after repair:
<none>
acceptance-tests/features/club_member_invitations.feature
Repair modified locked acceptance feature files.
```

The workflow nevertheless continued to `dev_check`, which passed, then failed again in `plan_conformance_gate` with:

```text
Plan conformance cannot be accepted automatically because the implementation/repair modified a locked acceptance feature file: acceptance-tests/features/club_member_invitations.feature. The plan has no explicit 'Allowed acceptance feature changes' section naming this file and permitted changes, while the workflow acceptance rules require human input for any repair requiring feature-file changes. The plan also explicitly asks to remove/narrow @todo-domain/@todo-ui tags, creating a scope/process conflict that needs human confirmation rather than another repair loop.
```

That error is factually inconsistent with the plan in the run branch, which does contain the explicit allowed-change section naming `acceptance-tests/features/club_member_invitations.feature`.

### Impact

A green implementation was blocked after substantial work and validation because the repair/conformance machinery treated an explicitly permitted feature-file change as locked. Matt had to inspect the run and decide how to proceed manually before the implementation could be published and reviewed.

This repeated the waste pattern this note originally captured: explicitly planned feature-file work still reached a late gate that could not safely recognize it.

### What allowed it to happen

The prevention added on 2026-05-30 is incomplete across workflow stages:

- The deterministic final/publish guard understands explicit plan permissions, but `verify_plan_repair` still appears to apply a blanket feature-file rejection to repair diffs.
- The LLM plan-conformance gate reported that no `## Allowed acceptance feature changes` section existed even though the plan had one, suggesting the prompt or evidence supplied to that gate did not make the permission easy or deterministic to verify.
- The workflow edge from failed `verify_plan_repair` continued to `dev_check`, allowing the run to spend more time before surfacing the same policy conflict again.
- The plan asks delivery to remove/narrow todo tags, but the repair guard cannot distinguish tag narrowing from other feature-file edits during repair.

### Observations

- Run: `01KTKQWKQR3PQPNVTEZRWRF29T`.
- Changed planned feature file: `acceptance-tests/features/club_member_invitations.feature`.
- Changed support file: `acceptance-tests/features/support/membership_administration.js`.
- Plan path: `docs/iterations/029-membership-admin-invitations/plan.md`.
- The run branch `origin/fabro/run/01KTKQWKQR3PQPNVTEZRWRF29T` shows the allowed section in the plan and a tag-only diff for the four `@iteration-029` scenarios in the feature file.
- The implementation run status ended at `plan_not_ready` with `plan_conformant=false`, not because tests were red.

### Why this matters

Acceptance feature files are now part of the planned delivery contract for behaviour-facing iterations. If different gates interpret feature-file permissions differently, teams get a false choice between preserving the feature-file lock and completing planned BDD delivery. The late failure also makes a green run look like a product or plan problem when the abnormality is in the delivery machinery.

### Open questions

- Why did `plan_conformance_gate` claim the plan had no explicit allowed-change section when the run branch plan did have one?
- Should `verify_plan_repair` call the same deterministic allowed-feature-change guard as final artifact and publish, using the repair baseline as the comparison base?
- Should a failed `verify_plan_repair` route to a hard stop or human-input node instead of continuing to another `dev_check` loop?
- Should tag-only changes to explicitly allowed scenarios be classified separately from broader Gherkin text changes in every gate, not only the final/publish guard?

### Possible prevention ideas

- Reuse `guard_acceptance_feature_changes.py` in `verify_plan_repair` and plan-conformance checks instead of maintaining separate blanket `.feature` checks.
- Make the conformance evidence script print the parsed `## Allowed acceptance feature changes` entries and the exact feature-file diff classification before asking an LLM to judge conformance.
- Add a workflow test fixture for a plan-conformance repair that removes `@todo-ui` from an explicitly allowed scenario and updates step support, proving the workflow accepts the repair after `dev check` passes.
- Route failed repair verification to a clear human-input failure with the parsed permission evidence, instead of spending another `dev_check` cycle and producing a contradictory later error.

## Resolution applied: plan-repair feature permissions

Date: 2026-06-08

Root cause: `iteration-implementation` had two different acceptance-feature policy implementations. Final artifact and publish used `guard_acceptance_feature_changes.py`, which understands `## Allowed acceptance feature changes`, but `verify_plan_repair` still used an older blanket `.feature` rejection. Its unconditional edge to `dev_check` also meant a failed repair verification could continue into another expensive validation loop and produce a later, contradictory LLM conformance message.

Fix applied:

- `.fabro/workflows/iteration-implementation/workflow.fabro`: changed `verify_plan_repair` to call `guard_acceptance_feature_changes.py` with the repair baseline HEAD and current plan path, so committed or working-tree repair diffs are checked against explicit plan permissions instead of blanket-rejected.
- `.fabro/workflows/iteration-implementation/workflow.fabro`: changed `verify_plan_repair` routing so only a successful repair verification proceeds to `dev_check`; failures now route to `plan_not_ready` instead of continuing silently.
- `.fabro/workflows/iteration-implementation/scripts/test_guard_acceptance_feature_changes.sh`: added coverage for committed repair-style feature diffs, including an explicitly allowed tag-only committed change and a committed unplanned feature change that must fail.

Validation:

- `bash .fabro/workflows/iteration-implementation/scripts/test_guard_acceptance_feature_changes.sh` — passed.
- `python3 -m py_compile .fabro/workflows/iteration-implementation/scripts/guard_acceptance_feature_changes.py` — passed.
- `fabro validate .fabro/workflows/iteration-implementation/workflow.toml` — passed with pre-existing goal-gate retry warnings.

Remaining follow-up:

- The LLM `plan_conformance_gate` can still make a poor judgement if the evidence does not clearly show parsed feature-file permissions. Consider adding deterministic permission/diff-classification output to the conformance evidence script if this recurs.

## Additional observation: 2026-06-23

### Context

Matt asked Pi to run:

```bash
bin/dev fabro deliver docs/iterations/043-conversations-overview-grouping/plan.md
```

After clearing stale predecessor metadata for iteration 042, delivery launched Fabro implementation run `01KVSADV33NPQZCN8VDWYSQRM1` for `docs/iterations/043-conversations-overview-grouping/plan.md`.

The iteration plan expected one shared acceptance feature change in `acceptance-tests/features/club_message_replies.feature`: the implementation should make the new `@iteration-043 @todo-domain` scenarios pass and remove the todo tag once implemented.

### Expected standard

A behaviour-facing plan that expects implementation to edit a shared `.feature` file should express the permission in the workflow-supported format before delivery starts.

The implementation workflow and guard expect a top-level section named exactly:

```text
## Allowed acceptance feature changes
```

When that section names the exact feature file and allowed change, Fabro should be able to remove/narrow `@todo-domain` for passing planned scenarios, run `dev check`, and publish without human rescue.

### What happened

The plan contained an allowed feature-change section, but it was nested as:

```text
### Allowed acceptance feature changes
```

Fabro implemented all four TODO tasks in the sandbox, removed `@todo-domain` from the iteration-043 rule in `acceptance-tests/features/club_message_replies.feature`, added domain step support, and ran `dev check` successfully.

The run then failed in `verify_plan_repair` / `plan_not_ready` with:

```text
Refusing to publish implementation: locked acceptance feature policy failed.
Acceptance .feature files changed without explicit plan permission under '## Allowed acceptance feature changes':
- acceptance-tests/features/club_message_replies.feature

To permit a feature edit, add a '## Allowed acceptance feature changes' section to the plan naming each .feature file and the allowed kind of change.
```

The run status ended as:

```json
{"kind":"failed","reason":"workflow_error"}
```

with failure detail:

```text
goal gate unsatisfied for node plan_not_ready and no retry target
```

### Impact

A green implementation was blocked after substantial sandbox work and validation. The work was present in Fabro's final diff and the TODO list was fully checked, but it did not publish to `main` because the plan permission heading was one Markdown level too deep.

This forced manual diagnosis of the run, plan, guard expectations, and sandbox diff before the implementation could be rescued or resumed.

### What allowed it to happen

The acceptance-feature permission contract is brittle and duplicated across planning, validation, and implementation:

- The deterministic guard requires `## Allowed acceptance feature changes` exactly.
- The plan used `### Allowed acceptance feature changes`, which looks semantically clear to a human but is invisible to the guard.
- Plan validation did not reject or repair the near-miss heading before delivery.
- The implementation workflow discovered the mismatch only after implementation, plan repair, and `dev check` had already consumed time.
- The failure message correctly named the expected heading, but by then the run had failed at a late gate rather than at plan validation.

### Observations

- Run: `01KVSADV33NPQZCN8VDWYSQRM1`.
- Run URL: `https://fabro.home.wynne.family/runs/01KVSADV33NPQZCN8VDWYSQRM1`.
- Plan path: `docs/iterations/043-conversations-overview-grouping/plan.md`.
- Feature file changed in the sandbox: `acceptance-tests/features/club_message_replies.feature`.
- The sandbox TODO showed all implementation tasks checked.
- Fabro's final diff summary showed 11 changed files, 495 additions, and 201 deletions.
- `dev_check` succeeded in the run; the failure was delivery-machinery policy, not product-code validation.
- The plan text elsewhere explicitly said the new `@todo-domain` scenarios should go green and the tag should be removed once implemented.

### Why this matters

The project depends on shared acceptance feature files as executable product contracts. If a plan can contain an almost-correct permission section that passes validation but fails only after implementation, the workflow preserves the feature-file lock but wastes a full implementation cycle and creates avoidable manual rescue work.

### Open questions

- Should plan validation reject `### Allowed acceptance feature changes` when a `.feature` edit is expected, or normalize it before validation passes?
- Should the guard accept the section at any heading level when the heading text is exact, or is top-level `##` intentionally part of the contract?
- Should the planning skill/template always place `## Allowed acceptance feature changes` as a top-level section rather than under acceptance scenarios?
- Can `bin/dev fabro deliver` or the validation workflow run the same deterministic parser before marking a plan validated?

### Possible prevention ideas

- Add a plan-validation fixture that fails a behaviour-facing plan with `### Allowed acceptance feature changes` and expected `.feature` edits.
- Make `.fabro/workflows/iteration-implementation/scripts/guard_acceptance_feature_changes.py` available as a pre-delivery/validation check so permission parsing fails before implementation work starts.
- Update iteration-planning guidance or templates to require `## Allowed acceptance feature changes` exactly, with examples for tag-removal-only changes.
- Include parsed feature-change permissions in plan validation output so near-miss headings are visible before delivery.
