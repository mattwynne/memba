Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `007 Update Membership public query APIs so callers can fetch a person's primary email, alternate emails, and lookup active memberships by any known address. ...`

2. **Changes made**
   - Updated `Memba.Membership` public query API:
     - Added `get_person_primary_email/1`.
     - Added `list_person_alternate_emails/1`.
     - Added `list_person_email_addresses/1`.
     - Updated `list_active_clubs_for_member_email/1` to join `membership_person_email_addresses` on `normalized_email`.
     - Updated `active_member_of_club_by_email?/2` to join `membership_person_email_addresses` on `normalized_email`.
     - Updated `list_active_members_of_club/1` to return one row per active member using the primary email-address projection row.
   - Added Membership query tests for:
     - fetching primary/alternate/all email addresses;
     - alternate-address active-club lookup;
     - alternate-address active-member checks;
     - primary-address recipient row selection with multi-address people.
   - Updated the Membership public API whitelist test for the new approved query APIs.
   - Updated shared test fixtures so direct projection-based web tests create a primary `membership_person_email_addresses` row alongside `membership_people`.
   - Updated affected web test helpers to reuse the same projected person for duplicate normalized-email multi-club scenarios, matching the new global uniqueness rule.

3. **Focused validation commands run**
   - `cd web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba/membership/query_test.exs`
     - Passed: `15 tests, 0 failures`
   - `cd web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba/membership`
     - Passed: `104 tests, 0 failures`
   - `cd web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba/accounts_test.exs test/memba/messaging/send_club_message_test.exs`
     - Passed: `11 tests, 0 failures`
   - Targeted affected web tests:
     - Passed: `88 tests, 0 failures`
   - `cd web && mix format --check-formatted ...`
     - Passed for touched files.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `330 tests, 0 failures`
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 007 Update Membership public query APIs ...`
   - To:
     - `- [x] 007 Update Membership public query APIs ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002: Kept behavior in the Membership bounded context with read-model query APIs over projections.
   - ADR 0007: Messaging remains dependent only on `Memba.Membership` public query APIs; no direct Messaging reads of Membership tables were introduced.
   - ADR 0009: Continued using Ecto projection tables as read models for query behavior.
   - ADR 0011: Person identity remains `person_id`; email addresses are mutable projected data, not aggregate identities.
   - No acceptance feature files were changed.