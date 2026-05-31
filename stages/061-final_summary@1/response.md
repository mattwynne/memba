Result: IMPLEMENTED_AND_PUBLISHED

Plan path: `docs/iterations/009-routing-and-liveview-surface-split/plan.md`

## Summary of delivered capability

Implemented the routing and LiveView surface split for iteration 009. Staff/operator LiveView tooling now lives behind `/admin/*` routing with admin-namespaced LiveView modules, while public pages remain separate. The implementation also adds an explicit staff browser pipeline seam, preserves the Postmark webhook route, adds layout coverage including the club-site layout seam, updates tests for the new route structure, and verifies that removed public harness paths return 404 rather than redirecting.

## Plan conformance summary

The implementation conformed to the validated plan:

- All todo items in `docs/iterations/009-routing-and-liveview-surface-split/todo.md` are checked off.
- `/admin` LiveView routes are present and tested.
- Existing LiveView modules were moved into the admin namespace.
- Internal links and verified routes were updated to admin paths.
- Layout functions were adjusted and covered by tests.
- Homepage operational/admin link treatment was updated.
- Controller, LiveView, and router tests were updated for the new paths.
- Old harness/public routes are covered as 404/no-redirect behavior.
- Postmark webhook route remains available.
- No acceptance `.feature` changes were detected.

The plan conformance gate reported:

- `plan_conformant: true`
- `plan_rework_available: false`

## Key files changed

The publish-to-main output is the authoritative changed-file evidence. It reported:

> `13 files changed, 348 insertions(+), 41 deletions(-)`

Grouped by area:

### Iteration tracking

- `docs/iterations/009-routing-and-liveview-surface-split/todo.md`

### Admin LiveViews

- `web/lib/memba_web/live/admin/clubs_live/index.ex`
- `web/lib/memba_web/live/admin/clubs_live/show.ex`
- `web/lib/memba_web/live/admin/deliveries_live/index.ex`
- `web/lib/memba_web/live/admin/messages_live/show.ex`

Publish output notes these as renames from the prior non-admin LiveView paths:

- `web/lib/memba_web/live/{ => admin}/clubs_live/index.ex`
- `web/lib/memba_web/live/{ => admin}/clubs_live/show.ex`
- `web/lib/memba_web/live/{ => admin}/deliveries_live/index.ex`
- `web/lib/memba_web/live/{ => admin}/messages_live/show.ex`

### Layout/component tests

- `web/test/memba_web/components/layouts_test.exs`

### Additional changed files

The final publish output confirmed 13 files changed, but only the file paths shown above were explicitly listed in the provided publish evidence. Per instruction, no additional file names are claimed here beyond those visible in the final artifact/publish evidence.

## Final artifact gate evidence

The final artifact gate confirmed implementation evidence:

- Working tree changes were present:
  - `?? .fabro/tmp/`
- It compared `HEAD` with `HEAD@{1}` and found no differences there.
- It found recent Fabro checkpoint commits.
- It reported:
  - `No acceptance .feature changes detected.`
  - `Final artifact evidence confirmed: working-tree`
  - `Final artifact gate passed.`

Because the final artifact gate showed only working-tree evidence, the only file/path evidence from that gate itself was:

- `.fabro/tmp/`

The publish step then provided the concrete implementation artifact evidence listed above.

## Published commit on main

The implementation was published to `main`.

Publish-to-main output:

- Commit created on the run branch:
  - `a907ae1 iteration 009: Routing and LiveView surface split`
- Successfully rebased.
- Pushed to GitHub:
  - `3b3f302..4f35096 HEAD -> main`
- Resulting main commit SHA:
  - `4f35096bc495230f90da9013f2809ea28d14d01b`

## Commit trailer metadata present

The publish output confirms the implementation was published as:

- `iteration 009: Routing and LiveView surface split`

The provided publish output does not show the full commit message body or trailers, so no specific trailer names/values are claimed here.

## Tests and validation run

Validation passed.

Commands/evidence:

- Implementation task validation ran:
  - `PATH="$PWD/bin:$PATH" bin/dev check`
  - Result: `137 tests, 0 failures`

- Final dev check stage ran:
  - `PATH="$PWD/bin:$PATH" dev ci`
  - Result:
    - `137 tests, 0 failures`

The final dev check output also showed the environment and ExUnit execution completed successfully.

## Manual demo/checks still recommended

Recommended manual smoke checks from the plan:

1. Open `/` and confirm the public homepage renders.
2. Open `/admin/clubs`, create a club, and open its detail page.
3. Add or view members on `/admin/clubs/:club_id`.
4. Send or inspect a message if test data is available.
5. Open `/admin/messages/:message_id` and confirm diagnostics are staff-facing.
6. Open `/admin/deliveries` and confirm the operator overview renders.
7. Confirm `/clubs` returns the normal 404 page and does not render the club list.

## Non-blocking follow-ups

- `/admin/*` now has a routing/pipeline seam, but real staff authentication is still required before production exposure of sensitive operator tools.
- Member-facing white-label routes remain intentionally unexposed; future work should add real club resolution and/or magic-link authentication rather than temporary URL hacks.
- Existing club show/admin flows still combine member management, message sending, and message listing responsibilities; these can be extracted in later member-facing or operator UX slices.