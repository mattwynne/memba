### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found:
  - Live working tree is clean except untracked `.fabro/tmp/`.
  - Just-completed implementation is in recent checkpoint `81bea91 fabro(...): implement_next_task (succeeded)`; current HEAD is the following pre-validation checkpoint.
  - `81bea91` changed exactly one ordinary todo line:
    - `003 Design the request persistence model:`
    - from `- [ ]` to `- [x]`.
  - Parent todo state shows tasks `001` and `002` checked, with `003` as the first unchecked task.
- Implementation artifacts found:
  - Added `docs/iterations/022-request-to-club-onboarding/request-persistence-model.md`.
  - The design covers the planned persistence fields and decisions: requester name/email, requested club name, note, active/converted/rejected status, rejection notes, converted club/person/membership IDs, submitted/triaged timestamps, indexes/constraints, schema/changeset rules, and context API shape.
  - No acceptance feature files were edited in the implement checkpoint.
- Tests run/results found:
  - Re-ran reported validation checks:
    - `git diff --check` — passed.
    - no-index whitespace check for the new doc — passed.
  - No automated app tests were necessary for this docs-only design task; skipping `dev check` is consistent with project guidance for docs-only changes.
- ADR/plan conformance notes:
  - Work stays within task `003` and does not delete, weaken, split, or reorder plan-required work.
  - ADR 0002 respected by explicitly documenting an Ecto source-of-truth exception for this operational request/triage model.
  - ADR 0009 respected by avoiding foreign keys to membership projection tables.
  - ADR 0011 respected by specifying generated typed request IDs.
  - The task is small and independently checkpointable.

{"context_updates":{"task_valid":true,"task_retry_available":false}}