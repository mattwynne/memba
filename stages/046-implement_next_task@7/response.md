Implemented task 013 and left it unchecked for independent review.

1. Selected task

   `- [ ] 013 Reuse default operational/error handling; do not build a notification framework, bespoke retry UI or delivery-status feature.`

2. Changes

   - Updated [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex:124) to log welcome-email delivery failures using the application’s existing `Logger.warning/2` convention.
   - Included club, group, membership, recipient, and actor IDs as structured log metadata.
   - Preserved the successful membership result and refreshed UI when email delivery fails.
   - Extended [member_dashboard_admission_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_admission_live_test.exs:109) to prove the failure is logged while the member remains visible and no error flash or delivery-status UI is introduced.
   - Added no notification framework, retry mechanism, persistence, or new UI.

3. Focused validation

   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_admission_live_test.exs`
     - 5 tests, 0 failures.
   - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/group_welcome_email_test.exs`
     - 3 tests, 0 failures.
   - `bin/mix format --check-formatted lib/memba_web/live/member_dashboard_live.ex test/memba_web/live/member_dashboard_admission_live_test.exs`
     - Passed.
   - `git diff --check`
     - Passed.

   Full `dev check` was not run because task 016 explicitly owns the final gate.

4. Ready for review

   `- [ ] 013 Reuse default operational/error handling; do not build a notification framework, bespoke retry UI or delivery-status feature.`

5. Todo changes

   None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

   - ADR 0002/0024: membership remains committed through the Club command boundary before email handoff.
   - ADR 0007: no Messaging or Membership domain state was added for welcome delivery.
   - ADR 0009: no projector or replay behavior was changed.
   - ADR 0016: delivery continues through the switchable `Memba.Mailer` boundary; failures use ordinary operational logging.