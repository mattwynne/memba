# Problem: Iteration review publish checkpoint used stale tmp ignore from review branch

Date: 2026-05-29

Selected iteration: 004 Delivery statuses and views
Plan path: docs/iterations/004-delivery-status-and-views/plan.md
Review branch: review/004-delivery-status-and-views
Implementation ref under review: e35b20e7d205357fd5f27356d361a1602c7d42c3
Base sha: d5361cf805a61a320973bf536c7d75678f16fc76

Fabro run ID: 01KSV1FB1HGF626VA38H8EVYE8
Web UI: https://fabro.home.wynne.family/runs/01KSV1FB1HGF626VA38H8EVYE8

Failed stage/status: checkpoint after `publish_polish_to_main`; run status FAILED.

Exact failure text:

```text
git checkpoint commit failed for node 'publish_polish_to_main': git add failed (exit 1)
```

Observed output:

```text
docs/code-health.md was not updated.
Reason: the review synthesis accepted the implementation (`implementation_accepted: true`) and reported no outstanding review fixes or judgement-worthy code-health findings (`review_fixes_available: false`).
```

Observations:

- The review workflow itself had been fixed on `main` to avoid adding `.fabro/tmp/` to `.git/info/exclude`.
- The reviewed branch still pointed at the implementation commit, which contained the older `publish_polish_to_main.sh` script that adds `.fabro/tmp/` to `.git/info/exclude`.
- The review stages completed and accepted the implementation with no review fixes or code-health findings.
- The failure happened after the publish script during checkpointing, not during code review or validation.
- This is a workflow/stale-branch interaction rather than an implementation failure.

Retry command after updating the review branch to include the review workflow fix:

```bash
bin/dev iteration-review review/004-delivery-status-and-views docs/iterations/004-delivery-status-and-views/plan.md d5361cf805a61a320973bf536c7d75678f16fc76
```
