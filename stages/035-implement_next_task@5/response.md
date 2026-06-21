Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `005 Resolve <club-slug> through the existing Membership slug lookup.`

2. **Changes made**
   - Added a focused regression test in:
     - `web/test/memba/messaging/inbound_club_destination_test.exs`
   - The new test proves that:
     - the extracted club subdomain label is used as the Membership slug lookup value;
     - `everyone@kmc-alpine.clubs.memba.io` resolves to a club whose actual slug is `kmc-alpine`;
     - a different subdomain, `everyone@kmc.clubs.memba.io`, does not resolve to that club.
   - No production code changes were needed because the current resolver already calls `Memba.Membership.get_club_by_slug/1` when resolving club candidates.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba/messaging/inbound_club_destination_test.exs`
     - Passed.
   - Initial focused test run with the default sandbox socket failed before tests due Postgres readiness/socket setup.
   - Retried with the project profile path and explicit sandbox Postgres socket:
     - `PATH="$PWD/bin:$PATH:$PWD/.devenv/profile/bin" PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 bin/mix test test/memba/messaging/inbound_club_destination_test.exs`
     - Passed: `8 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - `PATH="$PWD/bin:$PATH:$PWD/.devenv/profile/bin" PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 dev check --quick`
     - Completed, but ExUnit output still includes the existing `Memba.DomainCucumberRunnerTest` failure around `@todo-domain` scenario selection. I am not reporting this as a clean dev-check pass; that acceptance-tag/support work remains scheduled for later todo `010`.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 005 Resolve <club-slug> through the existing Membership slug lookup.`
   - To:
     - `- [x] 005 Resolve <club-slug> through the existing Membership slug lookup.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007 preserved: Messaging continues to depend on Membership through the public query API (`Membership.get_club_by_slug/1`), not Membership projection storage.
   - ADR 0016 preserved: no provider-specific parser or webhook boundary changed.
   - ADR 0019 preserved: no local/prod club-domain routing configuration changed; this only proves slug-based resolution for inbound email subdomains.