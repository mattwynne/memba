Implemented task 011. Welcome emails are now sent only when the authenticated admission command reports a new `:member_added` transition.

1. Selected task

   `- [ ] 011 Send only after a confirmed new membership transition, not on projection replay, duplicate requests or ordinary group reads.`

2. Changes

   - Updated [member_dashboard_live.ex](/workspace/memba/web/lib/memba_web/live/member_dashboard_live.ex:121) to:
     - inspect the authoritative `CustomGroupAdmission.transition`;
     - deliver the welcome only for `:member_added`;
     - treat `:already_member` as an email no-op;
     - resolve the recipient’s primary email and actor through Membership’s public APIs;
     - generate the normal authenticated group URL through `ClubSite`.
   - Added focused coverage in [member_dashboard_admission_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_admission_live_test.exs:67), proving:
     - opening/reading the group sends no welcome;
     - a confirmed admission sends exactly one welcome to the target’s primary address;
     - the email contains the authenticated group link;
     - replaying the same admission request produces no second welcome.
   - No aggregate, event, projector, acceptance feature, or todo changes were made.

3. Validation

   - TDD red phase confirmed the welcome was initially absent.
   - `dev test test/memba_web/live/member_dashboard_admission_live_test.exs test/memba/membership/group_welcome_email_test.exs`
     - 7 tests, 0 failures.
   - `bin/mix format --check-formatted lib/memba_web/live/member_dashboard_live.ex test/memba_web/live/member_dashboard_admission_live_test.exs`
     - passed.
   - `dev check --quick`
     - 1,437 tests, 0 failures.
   - `git diff --check`
     - passed.

4. Task remains unchecked for independent review

   `- [ ] 011 Send only after a confirmed new membership transition, not on projection replay, duplicate requests or ordinary group reads.`

5. Todo changes

   None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

   - ADR 0002/0024: the Club aggregate remains the admission consistency boundary; delivery is gated by its committed transition result.
   - ADR 0007: no Messaging aggregate or projection is accessed or mutated.
   - ADR 0016: delivery continues through the switchable, provider-neutral `Memba.Mailer` composer.
   - ADR 0021/0022: the code uses the explicit command result with strong consistency and does not infer a new transition from a projection preflight.