## Files changed

- `docs/iterations/014-member-dashboard-liveview-polish/plan.md`

## Summary of edits

1. **Strengthened the BDD/Gherkin omission rationale** in `## Acceptance Scenarios / Feature Files`:
   - Kept the decision as “not useful for this slice”.
   - Clarified that new Gherkin would mostly duplicate UI-level checks better covered by LiveView/Phoenix tests.

2. **Made implementation step 9 deterministic**:
   - Replaced conditional wording tied to iteration 013 with a direct requirement:
   - ensure no inline compose form remains on club home, and compose is reached only via the CTA link.

3. **Added an explicit `## Stop Condition` section**:
   - Declares completion criteria: acceptance criteria passing, `dev check` green, targeted tests + existing browser scenario passing, and no regressions in public/forbidden flows.

## Which Opus instructions were applied

- ✅ Add explicit BDD/Gherkin decision (or rationale for omission).
- ✅ Add explicit stop condition.
- ✅ Replace conditional step about iteration 013 with deterministic instruction.

## Instructions skipped (need Matt’s judgment)

- None.

## Anything Opus should pay special attention to in recheck

- The plan already had a BDD omission decision; this pass **tightens** the rationale rather than changing scope.
- Step 9 is now branch-state agnostic and objective.
- A new explicit stop condition is present and aligned with existing validation expectations.

---

Note: I attempted to run `dev check` per workflow, but the command is unavailable in this environment (`dev: command not found`).