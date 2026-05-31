# Problem: Iteration review checkpoint tried to add ignored .fabro/tmp

Date: 2026-05-29

Selected iteration: 004 Delivery statuses and views
Plan path: docs/iterations/004-delivery-status-and-views/plan.md
Implementation ref: e35b20e7d205357fd5f27356d361a1602c7d42c3
Base sha: d5361cf805a61a320973bf536c7d75678f16fc76

Fabro run ID: 01KSV12PCV8X7ENEW642PZHXTZ
Web UI: https://fabro.home.wynne.family/runs/01KSV12PCV8X7ENEW642PZHXTZ

Failed stage/status: checkpoint after `preflight_sandbox`; run status FAILED.

Exact failure text:

```text
git checkpoint commit failed for node 'preflight_sandbox': git add failed (exit 1)
```

Observed cause:

```text
The review preflight script added .fabro/tmp/ to .git/info/exclude and then wrote .fabro/tmp/review-start-sha.txt. During checkpoint, Fabro tried to add the ignored .fabro/tmp path and git refused.
```

Commands used:

```bash
bin/dev iteration-review review/004-delivery-status-and-views docs/iterations/004-delivery-status-and-views/plan.md d5361cf805a61a320973bf536c7d75678f16fc76
```

Observations:

- The review sandbox initialized and preflight itself succeeded.
- The failure occurred in Fabro's checkpoint machinery immediately after preflight, before review gates or reviewer agents ran.
- This is the same class of workflow/tooling failure previously fixed for the iteration implementation workflow.
- No implementation or review-polish code was attempted.

Retry command after applying the workflow metadata fix:

```bash
bin/dev iteration-review review/004-delivery-status-and-views docs/iterations/004-delivery-status-and-views/plan.md d5361cf805a61a320973bf536c7d75678f16fc76
```

## Resolution

Date: 2026-05-31

Root cause: Review preflight wrote `.fabro/tmp/` to `.git/info/exclude` and then created a file under `.fabro/tmp`; Fabro's checkpoint attempted to add the ignored path and Git rejected it.

Fix applied:

- `.fabro/workflows/iteration-review/workflow.fabro`: commit `c4fdb16` changed preflight to clean/create `.fabro/tmp` without mutating `.git/info/exclude`.
- `.fabro/workflows/iteration-review/workflow.toml`: commit `c4fdb16` expanded checkpoint excludes to cover both `.fabro/tmp` and `.fabro/tmp/**`.
- `.fabro/workflows/iteration-review/scripts/publish_polish_to_main.sh`: commit `c4fdb16` removed the `.git/info/exclude` write and stages changes with explicit pathspec exclusions for `.fabro/tmp`.

Validation:

- `fabro validate .fabro/workflows/iteration-review/workflow.toml` — read-only status check reported validation OK, with only existing goal-gate retry warnings.
- Read-only status check confirmed `rg "git/info/exclude" .fabro/workflows/iteration-review` finds no matches in current review workflow files.

Remaining follow-up:

- None for this note.

