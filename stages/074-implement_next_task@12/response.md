Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `012 Update Messaging recipient resolution to return one recipient per active member using the person's primary email address only.`

2. **Changes made**
   - Updated `web/test/memba/messaging/send_club_message_test.exs`:
     - Added a multi-address Messaging regression test proving:
       - each active member receives exactly one `EmailDeliveryCreated` event;
       - delivery uses the person’s primary email address;
       - alternate addresses are not delivered to.
     - Extended the local `create_person/1` test helper to support optional `:email_addresses`.
   - No production code change was needed:
     - `Memba.Messaging` already resolves through `Membership.list_active_members_of_club/1`.
     - `Membership.list_active_members_of_club/1` already returns one row per active member using the primary `PersonEmailAddress`.

3. **Focused validation run**
   - `cd web && mix format --check-formatted test/memba/messaging/send_club_message_test.exs`
     - Passed.
   - Initial bare test run failed because default `/tmp/devenv/postgres` socket was unavailable.
   - `PATH="$PWD/bin:$PATH" dev postgres`
     - Started/confirmed devenv Postgres service.
   - `cd web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba/messaging/send_club_message_test.exs`
     - Passed: `4 tests, 0 failures`.
   - `cd web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba/membership/query_test.exs test/memba/messaging/send_club_message_test.exs`
     - Passed: `19 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `337 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 012 Update Messaging recipient resolution to return one recipient per active member using the person's primary email address only.`
   - To:
     - `- [x] 012 Update Messaging recipient resolution to return one recipient per active member using the person's primary email address only.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0005: Messaging still resolves recipients before dispatch and includes resolved recipients in `SendMessage`.
   - ADR 0007: Messaging continues to depend on Membership’s public query API only; it does not query Membership projection tables directly.
   - ADR 0009: Projection-backed read models remain the source of query data.
   - ADR 0011: Person identity remains `person_id`; email addresses are not used as aggregate identities.
   - Acceptance feature files were not edited.