# Problem: Iteration 003 review accepted implementation but publish polish rebase failed

Date: 2026-05-29

Selected iteration: 003 Messaging skeleton
Plan path: docs/iterations/003-messaging-skeleton/plan.md
Review branch: review/003-messaging-skeleton
Base sha: 75c1d673cb9ee6c4247f605ac12fb32a62da884c

Fabro run ID: 01KSV31JY4HEHNYVKNC2KYAXM1
Web UI: https://fabro.home.wynne.family/runs/01KSV31JY4HEHNYVKNC2KYAXM1

Failed stage/status: `publish_polish_to_main` followed by `publish_failed`; run status FAILED.

Exact failure text:

```text
Could not apply f165284... # review polish: iteration 003
```

Final failure:

```text
goal gate unsatisfied for node publish_failed and no retry target
```

Observations:

- The independent review stages completed.
- The synthesis accepted the implementation.
- The code-health stage explicitly reported that `docs/code-health.md` was not updated because no judgement-worthy findings were needed.
- The failure occurred while publishing review-polish to main, not while reviewing the implementation.
- The review branch had been advanced from the pure implementation commit only to include review workflow fixes needed to avoid the `.fabro/tmp` checkpoint failure. That likely contributed to the later rebase conflict when publishing against current `main`, where related workflow fixes already existed.
- This is a workflow/review-branch publishing problem rather than an implementation failure.

Retry options:

```bash
bin/dev iteration-review review/003-messaging-skeleton docs/iterations/003-messaging-skeleton/plan.md 75c1d673cb9ee6c4247f605ac12fb32a62da884c
```

A safer retry may require a review branch based on current `main` or a publish script path that can run from the committed workflow definition rather than from stale reviewed branch contents.
