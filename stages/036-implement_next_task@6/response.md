1. **Selected todo line**
   - `- [ ] 006 Inspect inbound club-message rejection email construction and the email request/provider shape for display-name support.`

2. **Changes made**
   - Updated `docs/iterations/031-brand-email-navigation-polish/todo.md` only.
   - Added the inspection finding for task 006:
     - Rejection emails are built in `web/lib/memba/messaging/inbound_club_rejection_email.ex`.
     - Delivery is triggered through `Memba.Messaging.reject_first_inbound_club_email/5-6`.
     - Resolved club rejections already pass `club_name: destination.club_name`; unknown/unsupported destination rejections do not have club context.
     - Current `from_address/1` preserves the configured sender address and normalizes to a named Swoosh tuple.
     - Postmark, Resend, and local/test delivery paths support named `from` tuples, so task 007 can change only the display name to sanitized `<club name> via Memba` while preserving sender address, reply-to, threading, copy, and provider metadata/tags.

3. **Focused validation commands run**
   - `git diff --check`
     - Passed.
   - `git diff -- docs/iterations/031-brand-email-navigation-polish/todo.md`
     - Reviewed the selected check-off and finding note.
   - `git status --short`
     - Shows only the intended todo edit plus existing untracked `.fabro/tmp/`.

   I did not run `dev check` because this was a docs/inspection-only task with no code, config, dependency, migration, acceptance-test, executable example, or app-behaviour change.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 006 Inspect inbound club-message rejection email construction and the email request/provider shape for display-name support.`
   - To:
     - `- [x] 006 Inspect inbound club-message rejection email construction and the email request/provider shape for display-name support.`

5. **Todo splits/additions/reordering**
   - No splits, additions, or reordering.
   - Added only a finding note under task 006.

6. **ADR conformance evidence**
   - Read relevant ADRs:
     - ADR 0016: confirms email delivery must remain behind Swoosh/Mailer provider boundaries and Resend/Postmark remain switchable.
     - ADR 0004: confirms message deliverability aggregate boundaries remain separate from this email-rendering/provider-shape inspection.
   - This task made no architecture or behaviour changes; the finding confirms the next implementation can stay within the existing Swoosh/Mailer boundary and preserve provider switchability.