Implemented next unchecked task.

1. **Selected todo line**
   - `015 Update inbound email sender resolution so pending/unverified known addresses are rejected rather than accepted as member identity.`

2. **Changes made**
   - Added `Membership.get_verified_person_by_email/1`.
     - Same normalization/privacy behavior as existing email lookup.
     - Returns a Person only when the matching `PersonEmailAddress.verified_at` is present.
     - Invalid, blank, unknown, and pending/unverified addresses return `nil`.
   - Updated `Memba.Messaging.InboundClubSender` to resolve senders through the verified-email lookup.
     - Verified primary/alternate addresses still resolve.
     - Pending/unverified known addresses are rejected as `:unknown_sender`, avoiding account-state leakage.
   - Added focused tests:
     - Resolver test for rejecting a pending known address.
     - Full inbound receive-path test proving a pending known sender is rejected, no club message is created, and an inbound rejection is recorded/sent.

3. **Validation commands run**
   - TDD/failing first:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/messaging/inbound_club_sender_test.exs test/memba/messaging/inbound_club_message_acceptance_test.exs`
     - Failed as expected: pending known address was still resolved/accepted.
   - Formatting:
     - `cd web && mix format lib/memba/membership.ex lib/memba/messaging/inbound_club_sender.ex test/memba/messaging/inbound_club_sender_test.exs test/memba/messaging/inbound_club_message_acceptance_test.exs`
     - Passed.
   - Focused tests after implementation/format:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/messaging/inbound_club_sender_test.exs test/memba/messaging/inbound_club_message_acceptance_test.exs`
     - Passed: `27 tests, 0 failures`.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `996 tests, 0 failures`.
   - Full validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `109 scenarios (109 passed)`, `783 steps (783 passed)`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 015 Update inbound email sender resolution so pending/unverified known addresses are rejected rather than accepted as member identity.`
   - To:
     - `- [x] 015 Update inbound email sender resolution so pending/unverified known addresses are rejected rather than accepted as member identity.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read ADR 0015 and ADR 0023 as required by the plan.
   - This task does not add member UI, LiveView routing, or URL-addressable state, so it does not conflict with either ADR.
   - Messaging continues to use Membership’s public API instead of coupling directly to Membership projection storage, preserving the bounded-context boundary while enforcing the new verified-address identity rule.