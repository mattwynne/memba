Implemented the next unchecked task.

1. **Selected todo line**
   - `011 Update docs/postmark-email.md and any production cutover/runbook text that describes inbound club-message email.`

2. **Changes made**
   - Updated `docs/postmark-email.md`:
     - Canonical inbound address is now `everyone@<club-slug>.clubs.memba.io`.
     - Postmark inbound setup now documents `*.clubs.memba.io` wildcard inbound domain/MX.
     - Examples now use `everyone@kmc.clubs.memba.io` / `everyone@test.clubs.memba.io`.
     - Documented that only `everyone` is accepted, unknown club subdomains and unsupported local parts are rejected, and old flat addresses like `kmc@clubs.memba.io` are rejected.
     - Updated local Postmark inbound smoke payload/local dev examples to the new shape.
   - Updated `docs/iterations/020-migrate-production-email-to-postmark/postmark-production-cutover-runbook.md`:
     - Production cutover checklist now uses `*.clubs.memba.io`.
     - Manual inbound smoke and rollback checks now use `everyone@test.clubs.memba.io` / known club subdomains.
     - Rollback language now describes the wildcard namespace.

3. **Focused validation**
   - `grep ... docs/postmark-email.md docs/iterations/020-migrate-production-email-to-postmark/postmark-production-cutover-runbook.md`
     - Confirmed remaining old flat-address mention is only the intentional rejection note.
   - `git diff --check -- docs/postmark-email.md docs/iterations/020-migrate-production-email-to-postmark/postmark-production-cutover-runbook.md`
     - Passed.
   - Final `git diff --check`
     - Passed.
   - Did **not** run `dev check` because this task is docs-only and the project guide says not to run it for docs-only edits unless requested.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 011 Update docs/postmark-email.md and any production cutover/runbook text that describes inbound club-message email.`
   - To:
     - `- [x] 011 Update docs/postmark-email.md and any production cutover/runbook text that describes inbound club-message email.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0016: preserved distinct Postmark inbound endpoint documentation and Resend rollback/fallback framing.
   - ADR 0017: kept production cutover/smoke checks explicit rather than relying on local tests.
   - ADR 0020: kept production smoke guidance aligned with controlled Memba/Fastmail-style smoke operations; smoke-test code/docs remain for the next task.