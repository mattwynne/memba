Implemented the next unchecked task.

1. **Selected todo line**
   - `002 Extract reusable club creation/slug form logic if needed so request conversion and /admin/clubs share the same slug generation, validation, and availability behaviour. Prefer reuse over duplication.`

2. **Changes made**
   - Added `web/lib/memba_web/admin/club_slug_form.ex`
     - Centralizes staff club slug form behaviour:
       - empty club form params
       - Phoenix form construction
       - projected-club-to-form params
       - generated slug suggestion/preservation
       - max slug length
       - slug validation + availability feedback
       - feedback CSS class selection
   - Refactored:
     - `web/lib/memba_web/live/admin/clubs_live/index.ex`
     - `web/lib/memba_web/live/admin/clubs_live/show.ex`
   - Added tests:
     - `web/test/memba_web/admin/club_slug_form_test.exs`
   - Checked off only todo `002`.
   - No acceptance feature files were edited.

3. **Focused validation**
   - Formatting check:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/admin/club_slug_form.ex lib/memba_web/live/admin/clubs_live/index.ex lib/memba_web/live/admin/clubs_live/show.ex test/memba_web/admin/club_slug_form_test.exs`
     - Result: passed.
   - Focused tests:
     - `devenv shell -- bash -lc 'cd web && mix test test/memba_web/admin/club_slug_form_test.exs test/memba_web/live/admin/clubs_live/index_test.exs test/memba_web/live/admin/clubs_live/show_test.exs'`
     - Result: `17 tests, 0 failures`.
   - Full quality gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: passed.
     - ExUnit: `532 tests, 0 failures`.
     - Acceptance: `38 scenarios (38 passed), 252 steps (252 passed)`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 002 Extract reusable club creation/slug form logic...`
   - To:
     - `- [x] 002 Extract reusable club creation/slug form logic...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: kept work within Phoenix web app structure.
   - ADR 0013: added automated Phoenix/ExUnit coverage for the extracted web-facing behaviour.
   - ADR 0015: preserved LiveView implementation for staff admin pages.
   - ADR 0002/0011: no new aggregate/domain command behaviour or ID policy changes introduced.
   - ADR 0021/0022: no read-model publication/barrier behaviour changed; existing staff club tests continue to pass.