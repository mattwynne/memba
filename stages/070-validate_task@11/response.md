### Decision

**VALID**

### Evidence

- **Completed todo/check-off evidence found.**
  - `/tmp/fabro-pre-validate-snapshot.md` records a clean working tree at the implement checkpoint.
  - Live `git status --short` is clean.
  - Recent commits show `ed80431 fabro(...): implement_next_task (succeeded)` followed by `a19a6d8 ... pre_validate_snapshot`.
  - `git diff ed80431^ ed80431 -- docs/iterations/021-staff-area-redesign/todo.md` shows exactly one ordinary task changed from unchecked to checked:
    - `010 Remove the embedded club messages list from club detail and replace it with a clear link/copy toward /admin/messages or future club-filtered messages.`
  - Parent todo state confirms task `010` was the first unchecked task at implementation start.

- **Implementation artifacts found.**
  - `web/lib/memba_web/live/admin/clubs_live/show.ex`
    - Removed the `Memba.Messaging` alias and club-scoped message query.
    - Removed `:message_count` assign and `:messages` stream.
    - Removed embedded `#messages` stream/list and per-message diagnostics links from club detail.
    - Added `#club-messaging-card` with copy explaining messages now live globally.
    - Added `#club-messages-link` navigating to `/admin/messages`.
  - `web/test/memba_web/live/admin/clubs_live/show_test.exs`
    - Updated composer-absence coverage to expect the global Messages link.
    - Added coverage proving projected club messages are not embedded on club detail.
  - `web/test/memba_web/live/browser_acceptance_harness_test.exs`
    - Updated browser-facing harness assertions to use `/admin/messages` for diagnostics navigation.
    - Removed assertions depending on embedded club message rows.
  - No `*.feature` files were changed in the implement checkpoint.

- **Tests run/results found.**
  - Re-ran focused tests live:
    - `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd web && mix test test/memba_web/live/admin/clubs_live/show_test.exs test/memba_web/live/browser_acceptance_harness_test.exs'`
    - Passed: `13 tests, 0 failures`.
  - `git diff --check ed80431^ ed80431` passed.
  - Implementation summary reports `dev check` passed with ExUnit and acceptance suites.

- **ADR/plan conformance notes.**
  - Matches plan task `010` and acceptance criteria requiring club detail to stop embedding the old club-scoped messages list while providing a clear route/copy toward global Messages.
  - Scope stays narrow: no new filters, no replacement staff composer, no domain/model changes.
  - ADR 0001 respected: work remains in Phoenix LiveView.
  - ADR 0007 respected: Membership and Messaging bounded contexts remain separate; the UI removes a local Messaging read dependency from club detail.
  - ADR 0009 respected: no projection ownership/plumbing changes.
  - ADR 0013 respected: browser-facing behaviour remains covered through PhoenixTest-style harness coverage plus focused LiveView tests.

{"context_updates":{"task_valid":true,"task_retry_available":false}}