CODE_HEALTH_RECORDED

Updated `docs/code-health.md` for Iteration 038 because no reviewer/synthesis artifact files were visible in this checkout, but independent inspection found one judgement-worthy non-blocking code-health issue: projector replay can still nudge the supervised email dispatcher if it is running, risking provider side effects during replay/rebuild.

Verified with `git diff -- docs/code-health.md`; the new entry is present.

{"context_updates":{"code_health_recording_ok":true}}