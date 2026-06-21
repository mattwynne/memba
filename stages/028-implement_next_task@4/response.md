Implemented the next unchecked task.

1. **Selected todo line**
   - `004 Accept only local_part == "everyone" for now.`

2. **Changes made**
   - Updated `Memba.Messaging.InboundClubDestination` so subdomain-route addresses only resolve when the local part is exactly normalized `everyone`.
   - Unsupported local parts like `committee@kmc.clubs.memba.io` now resolve through the existing unsupported-recipient path instead of becoming club candidates.
   - Updated resolver docs to state that the supported route is the `everyone` local part.
   - Added a focused regression test for rejecting unsupported local parts at a known club subdomain.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH:$PWD/.devenv/profile/bin" bin/mix format --check-formatted lib/memba/messaging/inbound_club_destination.ex test/memba/messaging/inbound_club_destination_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH:$PWD/.devenv/profile/bin" PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 bin/mix test test/memba/messaging/inbound_club_destination_test.exs`
     - Passed: `7 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - `PATH="$PWD/bin:$PATH:$PWD/.devenv/profile/bin" PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 dev check --quick`
     - Completed, but output still reports the existing/later-task `DomainCucumberRunnerTest` failure around `@todo-domain` scenario selection. I did not change acceptance tags/support because that is scheduled for todo `010`.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 004 Accept only local_part == "everyone" for now.`
   - To:
     - `- [x] 004 Accept only local_part == "everyone" for now.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007 preserved: destination resolution still uses Membership’s public slug lookup API.
   - ADR 0016 preserved: no provider-specific parser or webhook boundary was changed.
   - ADR 0019 preserved: the configured inbound namespace remains environment-configurable; this task only restricts the supported local route under that namespace.