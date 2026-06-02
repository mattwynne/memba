Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 009 Update active operational/current-app documentation, especially Postmark email docs, to remove open-tracking instructions or claims.`

2. **Changes made**
   - `docs/postmark-email.md`
     - Removed Postmark `Open` from enabled webhook events.
     - Added explicit guidance not to enable Postmark `Open`/`Opened` events.
     - Updated Resend webhook guidance to exclude opened/open events.
     - Replaced “enables Postmark open tracking per email” with “does not request Postmark open tracking.”
     - Removed the manual smoke-test step that asked operators to open an email and confirm an open webhook.
     - Updated auth-stream webhook wording to avoid delivery/open/bounce language.
   - `docs/human-todo.md`
     - Removed instructions to enable opened webhooks and open tracking.
     - Added operational follow-up items to disable/remove open webhook events and keep Postmark open tracking disabled.
     - Removed the smoke-test step that asked for confirming an opened event reaches Memba.
     - Updated auth-stream webhook wording to avoid open-event language.
   - `docs/problem-domain-audit-2026-06-01.md`
     - Removed stale `EmailDeliveryOpened` references from the current/candidate email-delivery vocabulary.
   - `docs/iterations/017-remove-open-tracking/todo.md`
     - Checked off task 009 only.

3. **Focused validation**
   - `git diff --check`
     - Passed.
   - Focused changed-doc search:
     - `git grep -n -i -E 'opened|track_opens|open tracking|open-tracking|opens|not opened' -- docs/postmark-email.md docs/human-todo.md docs/problem-domain-audit-2026-06-01.md`
     - Remaining matches are explicit negative/current-policy statements such as “Do not enable…” and “does not request…”.
   - Obsolete-instruction search:
     - `git grep -n -i -E 'track_opens|enable[s]? .*open tracking|enable .*opened|opened event reaches|delivery/open|delivered, opened|opened, bounced' -- docs/postmark-email.md docs/human-todo.md docs/problem-domain-audit-2026-06-01.md`
     - Remaining matches are “Do not enable…” statements, not instructions to enable tracking.
   - Active top-level docs search excluding historical/vendored dirs:
     - Remaining changed-doc matches are explicit negative/current-policy statements.
     - One unrelated strategy prose match remains: “opens a positioning lane.”
   - Did **not** run `dev check` because this task is docs-only and project guidance says not to run it for docs-only edits; task 010 remains specifically for final test/dev-check validation.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 009 Update active operational/current-app documentation, especially Postmark email docs, to remove open-tracking instructions or claims.`
   - To:
     - `- [x] 009 Update active operational/current-app documentation, especially Postmark email docs, to remove open-tracking instructions or claims.`

5. **Todo splits/additions/reordering**
   - None in the iteration `todo.md`.
   - Added two operational human follow-up checklist items in `docs/human-todo.md` to disable/remove provider open tracking/webhook configuration if previously enabled.

6. **ADR conformance**
   - Reviewed relevant ADRs 0004, 0006, 0012, and 0016.
   - Older ADRs contain now-superseded opened-tracking assumptions; this docs task follows the approved iteration plan’s policy that Memba no longer requests, records, or exposes email opens.
   - Historical ADR files were left unchanged; current operational/current-app docs were updated to match the active iteration decision.