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
