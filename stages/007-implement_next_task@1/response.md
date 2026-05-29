Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 009 Run \`devenv shell mix precommit\` and fix any issues.`

2. **Changes made**
   - Updated `bin/mix` so database-backed mix tasks (`precommit`, `test`, `ecto.*`, `event_store.*`) ensure Postgres is running when invoked via `devenv shell mix ...`.
     - This fixes the exact failure from `devenv shell mix precommit`, where Ecto/EventStore setup tried to connect before Postgres was started.
     - If the wrapper starts Postgres, it cleans it up afterward.
   - Accepted formatter changes produced by `mix precommit` in:
     - `web/lib/memba/membership/projectors/club.ex`
     - `web/mix.exs`
     - `web/test/event_sourced_setup_test.exs`
     - `web/test/features/cucumber_configuration_test.exs`
     - `web/test/memba/membership/club_test.exs`
   - Checked off the selected todo line in `docs/iterations/001-event-sourced-foundation/todo.md`.

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, `30 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" devenv shell mix precommit`
     - Initially failed because Postgres was not running.
     - Passed after the `bin/mix` wrapper fix, `30 tests, 0 failures`.
   - Final `PATH="$PWD/bin:$PATH" dev check`
     - Passed, `30 tests, 0 failures`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 009 Run \`devenv shell mix precommit\` and fix any issues.`
   - To:
     - `- [x] 009 Run \`devenv shell mix precommit\` and fix any issues.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read and followed ADRs 0002, 0007, 0008, 0009, 0010, and 0011.
   - The fix supports the existing Commanded/EventStore + Ecto projection test path by ensuring Postgres is available for EventStore/Ecto setup.
   - No acceptance feature files were edited.
   - No architectural changes were made to the Membership/Messaging bounded-context decisions or UUID identity rules.