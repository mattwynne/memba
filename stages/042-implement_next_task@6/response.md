Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `006 Reject unsupported local parts, unknown club subdomains, unsupported domains, and the old flat address using the existing inbound rejection pathway where possible.`

2. **Changes made**
   - Updated `web/lib/memba/messaging/inbound_club_destination.ex`
     - Removed fallback support for the old flat `kmc@clubs.memba.io` shape.
     - Non-subdomain recipients now resolve as `:unsupported_recipient_address`.
     - `everyone@unknown.clubs.memba.io` still resolves through the unknown-club rejection path.
   - Updated/added tests in:
     - `web/test/memba/messaging/inbound_club_destination_test.exs`
       - Added explicit regression coverage that `kmc@clubs.memba.io` is rejected even when `kmc` exists.
     - `web/test/memba/messaging/inbound_club_message_acceptance_test.exs`
       - Added end-to-end rejection-path coverage for:
         - unsupported local part: `committee@kmc.clubs.memba.io`
         - unsupported domain: `everyone@example.org`
         - old flat address: `kmc@clubs.memba.io`
         - unknown club subdomain: `everyone@unknown.clubs.memba.io`
       - Updated existing inbound acceptance/rejection examples in that file to use `everyone@kmc.clubs.memba.io`.
     - `web/test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs`
     - `web/test/memba_web/controllers/resend_inbound_webhook_controller_test.exs`
       - Updated controller-level accepted/rejected webhook payloads to route through the new address shape so selected-task hard cutover does not break those focused tests.

3. **Focused validation**
   - Formatting:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/messaging/inbound_club_destination.ex test/memba/messaging/inbound_club_destination_test.exs test/memba/messaging/inbound_club_message_acceptance_test.exs test/memba_web/controllers/resend_inbound_webhook_controller_test.exs test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs`
     - Passed.
   - Focused tests:
     - `PATH="$PWD/bin:$PATH:$PWD/.devenv/profile/bin" PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 bin/mix test test/memba/messaging/inbound_club_destination_test.exs test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs test/memba_web/controllers/resend_inbound_webhook_controller_test.exs`
     - Passed: `27 tests, 0 failures`.
     - `PATH="$PWD/bin:$PATH:$PWD/.devenv/profile/bin" PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 bin/mix test test/memba/messaging/inbound_club_message_acceptance_test.exs`
     - Passed: `22 tests, 0 failures`.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH:$PWD/.devenv/profile/bin" PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 dev check --quick`
     - Ran, but output still reports 2 failures in domain Cucumber selection/step support around new-address acceptance scenarios. I am **not** reporting dev check as passing; that remaining work maps to later todo `010`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Reject unsupported local parts, unknown club subdomains, unsupported domains, and the old flat address using the existing inbound rejection pathway where possible.`
   - To:
     - `- [x] 006 Reject unsupported local parts, unknown club subdomains, unsupported domains, and the old flat address using the existing inbound rejection pathway where possible.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007 preserved: Messaging continues resolving clubs through Membership’s public slug lookup boundary, not Membership projection internals.
   - ADR 0016 preserved: provider-specific Postmark/Resend controller tests continue feeding provider-neutral inbound email handling; no provider boundary or HTTP client was changed.
   - ADR 0021 unaffected: no projection-publishing or read-model notification behavior was changed.