Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `003 Update destination resolution to parse local_part@host where host is <club-slug>.<configured inbound domain>.`

2. **Changes made**
   - Updated `Memba.Messaging.InboundClubDestination` to parse the club slug from the recipient host/subdomain:
     - `everyone@kmc.clubs.memba.io` now resolves using `kmc` from `kmc.clubs.memba.io`.
     - Configured inbound domains still work, e.g. `everyone@kmc.example.clubs.memba.io`.
   - Kept existing fallback behavior for the old flat shape for now so this task does not prematurely implement later rejection/cutover tasks.
   - Updated destination resolver docs in:
     - `web/lib/memba/messaging/inbound_club_destination.ex`
     - `web/lib/memba/messaging.ex`
   - Updated focused resolver tests in:
     - `web/test/memba/messaging/inbound_club_destination_test.exs`
   - Checked off only todo item `003`.

3. **Validation run**
   - Formatted touched files:
     - `PATH="$PWD/bin:$PATH" bin/mix format lib/memba/messaging/inbound_club_destination.ex lib/memba/messaging.ex test/memba/messaging/inbound_club_destination_test.exs`
     - Passed.
   - Focused resolver test:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/messaging/inbound_club_destination_test.exs'`
     - Passed: `6 tests, 0 failures`.
   - Adjacent inbound messaging tests:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/messaging/inbound_club_destination_test.exs test/memba/messaging/inbound_club_message_acceptance_test.exs test/memba/messaging/inbound_email_api_test.exs'`
     - Passed: `30 tests, 0 failures`.
   - Whitespace check:
     - `git diff --check`
     - Passed.
   - Broad quick check:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" dev check --quick'`
     - Completed but output still reports the known/later-task `DomainCucumberRunnerTest` failure around `@todo-domain` scenario selection. I did not change acceptance tags because that is scheduled for todo `010`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 003 Update destination resolution to parse ...`
   - To:
     - `- [x] 003 Update destination resolution to parse ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007 preserved: Messaging still resolves clubs through the Membership public slug lookup API, not Membership storage internals.
   - ADR 0016 preserved: no provider-specific behavior or provider boundary was changed.
   - ADR 0019 preserved: inbound namespace remains environment-configurable; this task only changes recipient host parsing under that configured namespace.