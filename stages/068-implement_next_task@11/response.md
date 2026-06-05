Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `010 Remove the embedded club messages list from club detail and replace it with a clear link/copy toward /admin/messages or future club-filtered messages.`

2. **Changes made**
   - Updated `web/lib/memba_web/live/admin/clubs_live/show.ex`
     - Removed the club-scoped message query and `:messages` stream from club detail mount.
     - Removed the embedded `#messages` list, message rows, and per-message diagnostics links from the club detail page.
     - Replaced it with a `#club-messaging-card` explaining that messages live in the global Messages operations area.
     - Added a clear `#club-messages-link` to `/admin/messages`.
   - Updated `web/test/memba_web/live/admin/clubs_live/show_test.exs`
     - Adjusted existing absence-of-composer coverage to expect the global Messages link instead of the embedded list.
     - Added coverage proving existing projected club messages are not embedded on club detail and staff are pointed to `/admin/messages`.
   - Updated `web/test/memba_web/live/browser_acceptance_harness_test.exs`
     - Reworked browser harness expectations to use the global Messages page for diagnostics navigation.
     - Removed assertions depending on embedded club message rows/links.

3. **Validation commands/results**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/live/admin/clubs_live/show.ex test/memba_web/live/admin/clubs_live/show_test.exs test/memba_web/live/browser_acceptance_harness_test.exs`
     - Passed after applying formatter-suggested changes manually.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/admin/clubs_live/show_test.exs test/memba_web/live/browser_acceptance_harness_test.exs`
     - Failed before running tests due the known bare-wrapper Postgres socket readiness mismatch.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd web && mix test test/memba_web/live/admin/clubs_live/show_test.exs test/memba_web/live/browser_acceptance_harness_test.exs'`
     - Passed: `13 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed:
       - ExUnit: `524 tests, 0 failures`
       - Acceptance: `34 scenarios (34 passed), 215 steps (215 passed)`
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 010 Remove the embedded club messages list from club detail and replace it with a clear link/copy toward /admin/messages or future club-filtered messages.`
   - To:
     - `- [x] 010 Remove the embedded club messages list from club detail and replace it with a clear link/copy toward /admin/messages or future club-filtered messages.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001 respected: work remains in Phoenix LiveView.
   - ADR 0007 respected: Membership and Messaging bounded contexts remain separate; UI removed a local Messaging read query from club detail and did not change domain ownership.
   - ADR 0009 respected: no projection plumbing or read-model ownership changes.
   - ADR 0013 respected: browser-facing behaviour is covered with PhoenixTest-style harness coverage plus focused LiveView tests.