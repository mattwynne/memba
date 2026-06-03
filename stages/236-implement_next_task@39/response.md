Implemented the next unchecked task.

1. **Selected todo line**
   - `010 Add active-membership authorization for the resolved sender and destination club.`

2. **Changes made**
   - Added `Memba.Messaging.InboundClubAuthorization`.
     - Authorizes only when the resolved sender person is an active member of the resolved destination club.
     - Uses `Memba.Membership.active_member_of_club?/2` via Membership’s public API.
     - Returns `:ok` or typed rejection details: `{:error, :sender_not_active_member, details}`.
   - Added public API:
     - `Memba.Messaging.authorize_inbound_club_email_sender/2`
   - Added focused tests in:
     - `web/test/memba/messaging/inbound_club_authorization_test.exs`
     - Covers active member allowed, member of another club rejected, inactive member rejected.
   - Checked off task 010 in `todo.md`.
   - Also applied formatting-only fixes to existing unformatted files surfaced by `mix format --check-formatted` so `dev check` could pass.

3. **Validation run**
   - Initial bare `mix test` attempt failed because Postgres was not available outside the devenv shell.
   - Focused validation:
     - `devenv shell -O services.postgres.port:int 15432 -- bash -lc 'cd web && mix test test/memba/messaging/inbound_club_authorization_test.exs test/memba/messaging/inbound_club_sender_test.exs test/memba/messaging/inbound_club_destination_test.exs'`
     - Result: `12 tests, 0 failures`
   - Formatting:
     - `devenv shell -O services.postgres.port:int 15432 -- bash -lc 'cd web && mix format --check-formatted'`
     - Result: passed
   - Full required gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: passed
       - `431 tests, 0 failures`
       - `31 scenarios (31 passed)`

4. **Todo check-off made**
   - Changed:
     - `- [ ] 010 Add active-membership authorization for the resolved sender and destination club.`
   - To:
     - `- [x] 010 Add active-membership authorization for the resolved sender and destination club.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007: Messaging depends on Membership’s public query API, not Membership projection internals. The authorization module calls `Membership.active_member_of_club?/2`.
   - ADR 0002 / 0009: No new CRUD write model or projection machinery was introduced.
   - ADR 0011: No aggregate identity changes were made.
   - ADR 0005: Recipient resolution and message sending were not changed; this task only adds sender authorization.