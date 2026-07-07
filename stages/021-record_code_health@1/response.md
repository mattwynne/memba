CODE_HEALTH_RECORDED

Updated `docs/code-health.md` with a dated Iteration 047 entry because the merged delivery details page still has expandable delivery groups whose open/closed state is client-local (`<details>`) rather than URL-addressable under ADR 0023 guidance.

I verified `git diff -- docs/code-health.md` shows the new entry. No acceptance feature files or product behaviour were changed. Dev check was not run because this was a docs-only code-health recording step.

{"context_updates":{"code_health_recording_ok":true}}