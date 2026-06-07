## Files changed

- `docs/iterations/025-messaging-and-onboarding-quick-wins/plan.md`

## Summary of edits

- Clarified that the referenced acceptance feature files are existing files.
- Made the staff-only authorization boundary explicit for the new request-specific conversion URL.
- Added an objective completion condition: the three new acceptance scenarios must pass without `@wip` tags and `dev check` must pass.
- Renamed `Open Technical Decisions` to `Implementation Details to Confirm` and clarified those items are non-blocking implementation details.
- Added validation guidance to remove the three new `@wip` tags once implemented and run those scenarios green.

## Opus instructions applied

Applied the obvious readiness-tightening edits implied by the reviews:

- Reframed non-blocking “open technical decisions” as implementation details.
- Made existing staff authorization explicit for the request-specific route.
- Strengthened the stop condition around passing acceptance scenarios without `@wip` and `dev check`.
- Clarified the existing feature-file placement.

## Instructions skipped because they require Matt’s judgment

None.

## Anything Opus should pay special attention to in recheck

- `Status:` remains `ready`, not `validated`, per instruction. The deterministic `publish_ready` stage should perform validation status changes if the final gate succeeds.
- No app code or unrelated files were changed.
- I did not run `dev check` because this was a docs-only plan edit.