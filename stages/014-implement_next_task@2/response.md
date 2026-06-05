1. **Selected todo line**
   - `002 Inspect current admin routes, LiveViews, layouts, tests, and acceptance helpers.`

2. **Changes made**
   - Added `docs/iterations/021-staff-area-redesign/current-admin-surface-notes.md`.
   - Captured the current implementation inventory for:
     - `/admin` routes and staff authorization pipeline/live session;
     - `Layouts.admin`;
     - existing admin LiveViews for Clubs, club detail, person new/edit, Deliveries, and message diagnostics;
     - Membership and Messaging query/read-model seams relevant to upcoming `/admin/people` and `/admin/messages`;
     - current Phoenix tests and reusable test helpers;
     - browser acceptance features, step definitions, and support helpers;
     - missing executable staff-operations acceptance steps for later tasks.
   - Checked off only task `002` in `todo.md`.

3. **Focused validation**
   - `git log --oneline --decorate -20` — inspected recent Fabro checkpoints.
   - `git status --short` before editing — clean.
   - Inspected relevant route/layout/LiveView/query/test/acceptance files.
   - `git diff --check -- docs/iterations/021-staff-area-redesign/current-admin-surface-notes.md docs/iterations/021-staff-area-redesign/todo.md` — passed.
   - Python docs whitespace/final-newline check — passed.
   - Did **not** run `dev check` because this task made docs-only inspection notes, consistent with `AGENTS.md`.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 002 Inspect current admin routes, LiveViews, layouts, tests, and acceptance helpers.`
   - To:
     - `- [x] 002 Inspect current admin routes, LiveViews, layouts, tests, and acceptance helpers.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read relevant accepted ADRs for this inspection context:
     - ADR 0001 Phoenix core application;
     - ADR 0007 separate Membership and Messaging bounded contexts;
     - ADR 0010 shared feature files with Elixir Cucumber;
     - ADR 0013 PhoenixTest for feature-style web tests;
     - ADR 0015 LiveView default for app surfaces.
   - No code, routes, runtime behaviour, feature files, or acceptance helpers were changed.
   - Notes explicitly preserve ADR 0007’s context boundary concern for future global Messages enrichment and respect the shared-feature/acceptance workflow.