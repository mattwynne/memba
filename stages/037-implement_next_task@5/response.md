Task 005 is checked off. Final state has only the new regression tests plus that single todo-line check-off.1. **Selected todo line**
   - `005 Preserve and test fallback behaviour: no same-club header match remains the existing club-wide inbound message path; non-members, ambiguous senders, unsupported bodies/attachments, unknown clubs, and malformed provider payloads keep using existing rejection behaviour.`

2. **Changes made**
   - Added focused regression coverage in `web/test/memba/messaging/inbound_club_message_acceptance_test.exs`:
     - Unknown reply headers still create a new club-wide message.
     - Reply headers pointing to another club do not create cross-club replies and instead fall back to a new message for the addressed club.
     - Recognized reply headers do not bypass current-member authorization.
     - Recognized reply headers do not bypass unsupported-attachment rejection.
   - No production code changes were needed; existing rejection and parser coverage for blank/html-only bodies, unknown senders/clubs, malformed provider payloads, and related fallback paths remains intact and was covered by the quick check suite.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba/messaging/inbound_club_message_acceptance_test.exs` — passed.
   - `PATH="$PWD/bin:$PATH" bin/mix compile --warnings-as-errors` — passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/messaging/inbound_club_message_acceptance_test.exs` — attempted, but blocked by sandbox Postgres readiness/socket mismatch:
     - `Postgres did not become ready at PGHOST=/tmp/devenv/postgres PGPORT=15432`
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed:
     - `883 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly task `005` from `- [ ]` to `- [x]`.

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0004/0005: tests verify fallback continues through existing message aggregate/send-message delivery flow rather than adding alternate delivery paths.
   - ADR 0007: authorization remains through existing Membership public APIs and bounded-context boundary; no direct Membership storage coupling added.
   - ADR 0016: provider-neutral inbound behaviour is tested without adding provider-specific domain branching.
   - ADR 0022: tests use strong consistency/read-model assertions rather than sleeps or timing-based negative checks.