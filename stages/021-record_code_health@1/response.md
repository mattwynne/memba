CODE_HEALTH_RECORDED

Updated `docs/code-health.md` with a new 2026-06-19 section for Iteration 036 because judgement-worthy, non-blocking code-health findings were found during repository inspection:

- Auth check-email DS preview path mapping disagrees with the implemented filename, risking a wrong/duplicate/manual DesignSync push target.
- New static DS previews duplicate the full theme/head scaffolding across files, creating future drift risk as app tokens change.

Verified with `git diff -- docs/code-health.md`, which shows the new entry. No product behaviour or acceptance feature files were changed.

{"context_updates":{"code_health_recording_ok":true}}