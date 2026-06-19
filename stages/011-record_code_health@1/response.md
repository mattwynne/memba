CODE_HEALTH_RECORDED

Updated `docs/code-health.md` with one dated Iteration 036 finding. I found no visible reviewer-report or synthesis artifact files in the checkout, so I recorded the judgement-worthy issue found during independent inspection: the auth check-email preview mapping in `preview-conventions.md` names `auth-check-email.html`, while the delivered file is `check-email-delivery-progress.html`, which could confuse the manual DesignSync push.

Verified with `git diff -- docs/code-health.md` that the new entry is present. `dev check` was not run because this was a docs-only code-health recording change.

{"context_updates":{"code_health_recording_ok":true}}