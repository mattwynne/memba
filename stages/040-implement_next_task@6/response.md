Implemented task 012 by adding regression coverage for provider failure after a committed admission.

1. Selected task

   `- [ ] 012 Keep provider side effects out of aggregates/projectors; committed membership must not be represented as rolled back if delivery fails.`

2. Changes

   Added a browser-facing integration test in [member_dashboard_admission_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_admission_live_test.exs:108) that forces the configured Swoosh adapter to return `{:error, :timeout}` and proves:

   - the provider handoff was attempted;
   - the admitted member remains active;
   - the refreshed Members view displays the new member;
   - the member is removed from the candidate picker;
   - the successful admission is not presented as an error.

   No production change was needed: the existing flow commits the aggregate command before invoking `GroupWelcomeEmail`, and its delivery result cannot alter membership state. No aggregate or projector references the mailer.

3. Focused validation

   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_admission_live_test.exs`
     - 5 tests, 0 failures.
   - `bin/mix format --check-formatted test/memba_web/live/member_dashboard_admission_live_test.exs`
     - passed.
   - `git diff --check`
     - passed.
   - Focused PhoenixTest browser harness covered the visible post-failure state.

4. Ready for independent review

   `- [ ] 012 Keep provider side effects out of aggregates/projectors; committed membership must not be represented as rolled back if delivery fails.`

5. Todo changes

   None. The selected task remains unchecked, and no tasks were split, added, or reordered.

6. ADR conformance

   - ADR 0002/0024: admission remains an authoritative Club aggregate command committed before email delivery.
   - ADR 0007: email handoff does not mutate Messaging or Membership aggregate state.
   - ADR 0009: projectors remain replay-safe and contain no provider calls.
   - ADR 0016: the failure test uses the existing switchable `Memba.Mailer` boundary.