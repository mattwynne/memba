Implemented task 006.

1. **Selected todo line**
   - `006 Make the @iteration-041 scenarios executable; remove/narrow @todo-*.`

2. **Changes made**
   - Added executable `@iteration-041` scenarios to `acceptance-tests/features/club_message_replies.feature`:
     - Member replies by email and followers receive the reply.
     - Email to the club address without reply headers starts a new club-wide message.
     - Non-member email reply is rejected.
     - Reply headers from another club do not create a cross-club reply.
   - Added browser Cucumber support in:
     - `acceptance-tests/features/step_definitions/member_message_steps.js`
     - `acceptance-tests/features/support/member_message.js`
   - Added domain Cucumber support in:
     - `web/test/features/step_definitions/messaging_steps.exs`
   - Extended Resend inbound acceptance payload support to include headers for `In-Reply-To`.
   - Added deterministic acceptance helpers to record inbound email replies and assert that conversations do **not** contain unintended replies.
   - Checked off todo item 006 only.

3. **Validation commands/results**
   - `node --check acceptance-tests/features/support/member_message.js && node --check acceptance-tests/features/step_definitions/member_message_steps.js` — passed.
   - `PATH="$PWD/bin:$PATH" bin/mix format test/features/step_definitions/messaging_steps.exs` — passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/features/domain_cucumber_acceptance_test.exs --only domain_cucumber` — attempted, blocked by sandbox Postgres socket/readiness mismatch.
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed: `887 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev acceptance -- --tags @iteration-041` — passed after one synchronization fix: `4 scenarios, 46 steps`.
   - `PATH="$PWD/bin:$PATH" dev check` — passed, including browser acceptance: `95 scenarios, 640 steps`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Make the @iteration-041 scenarios executable; remove/narrow @todo-*.`  
       to
     - `- [x] 006 Make the @iteration-041 scenarios executable; remove/narrow @todo-*.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0003 / 0010: Added shared Cucumber scenarios runnable by both the Elixir/domain runner and browser runner.
   - ADR 0004 / 0005: Scenarios exercise the existing message aggregate and resolved-recipient delivery flow.
   - ADR 0007: No new Messaging-to-Membership storage coupling in production code; acceptance setup follows existing test-support patterns.
   - ADR 0016: Inbound reply headers remain provider-neutral in the domain, with Resend-specific shape handled at the acceptance/webhook boundary.
   - ADR 0021 / 0022: Browser assertions use existing committed UI/local-delivery waits and no sleeps; negative no-reply assertions query the read model after strong webhook handling or positive UI confirmation.