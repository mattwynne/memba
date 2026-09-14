Implemented the group-welcome email composer and left task 010 unchecked for independent review.

1. Selected task

   `- [ ] 010 Add a small provider-neutral group-welcome composer using Memba.EmailTemplates and the existing Memba.Mailer handoff conventions.`

2. Changes made

   - Added [group_welcome_email.ex](/workspace/memba/web/lib/memba/membership/group_welcome_email.ex:1), which:
     - composes multipart text and HTML welcome emails with `Memba.EmailTemplates`;
     - uses the configured Postmark, Resend, or local messaging sender;
     - hands delivery to `Memba.Mailer`;
     - sends to the normalized verified-primary address supplied by the caller;
     - includes group/club branding, authenticated group URL, history-access copy, and explicit “old emails aren’t resent” copy;
     - supports admin self-add wording;
     - provides the group inbound address as `Reply-To`;
     - emits Postmark-compatible metadata or Resend tags;
     - sanitizes header values and escapes dynamic HTML.
   - Added [group_welcome_email_test.exs](/workspace/memba/web/test/memba/membership/group_welcome_email_test.exs:1) covering Postmark and Resend composition, mailer handoff, self-add wording, content, links, recipient normalization, metadata, escaping, header injection protection, and invalid delivery data.
   - Deliberately did not wire delivery into admission handling; transition gating, duplicate suppression, and replay behavior remain task 011.
   - No acceptance feature files were changed.

3. Validation

   - TDD red phase: 3 tests failed because `GroupWelcomeEmail` was absent.
   - `dev test test/memba/membership/group_welcome_email_test.exs`: 3 tests, 0 failures.
   - `bin/mix format --check-formatted ...`: passed.
   - New-file and repository diff checks: passed.
   - `dev check --quick`: 1,436 tests, 0 failures.

4. Task remains unchecked

   `- [ ] 010 Add a small provider-neutral group-welcome composer using Memba.EmailTemplates and the existing Memba.Mailer handoff conventions.`

5. Todo changes

   None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

   - ADR 0016: provider selection remains runtime-switchable; both Postmark and Resend use Swoosh through the shared `Memba.Mailer` boundary.
   - ADR 0007: the composer does not mutate Messaging state or access its aggregates/projections.
   - No aggregate, projector, or event-handler side effects were introduced; admission-triggered delivery remains a later application-boundary task.