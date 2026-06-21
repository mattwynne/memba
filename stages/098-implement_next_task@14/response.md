Blocked on the selected task.

1. **Selected todo line**
   - `014 After Matt confirms Postmark/DNS are configured for \`*.clubs.memba.io\`, run the production inbound smoke test and record/report the result.`

2. **Changes made**
   - No code/config/test/doc changes.
   - I did **not** run the production smoke test because the external prerequisites are not met/available in this environment.

3. **Validation / checks run**
   - `git status --short`
     - Result: only untracked `.fabro/tmp/`; no tracked worktree changes.
   - Checked required smoke-test environment variables without printing secret values:
     - `MEMBA_SMOKE_STAFF_EMAIL`: missing
     - `MEMBA_SMOKE_FASTMAIL_PASSWORD` / `SMOKE_TEST_EMAIL_PASSWORD`: missing
     - `MEMBA_SMOKE_UNKNOWN_EMAIL`: missing
     - optional Postmark/JMAP tokens also missing
   - Checked DNS via Node:
     - `clubs.memba.io` has MX: `inbound.postmarkapp.com`
     - `test.clubs.memba.io` returned `ENODATA`
   - This indicates the wildcard/subdomain MX prerequisite for `*.clubs.memba.io` is not currently observable from this environment.

4. **Todo check-off**
   - None. I did **not** change:
     - `- [ ] 014 ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No ADRs were explicitly referenced by the iteration plan.
   - I preserved the plan constraint that Matt performs external Postmark/DNS setup and did not mutate Postmark/DNS from the implementation agent.

**Needed to complete task 014:** Matt’s confirmation that Postmark/DNS wildcard inbound is configured for `*.clubs.memba.io`, plus the required smoke-test environment variables/secrets for Fastmail/staff/unknown sender access.