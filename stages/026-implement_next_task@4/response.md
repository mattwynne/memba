1. **Selected todo line**
   - `- [ ] 004 Replace the sign-in email icon with the Memba sprig asset/component used elsewhere in Memba branding.`

2. **Changes made for this task only**
   - Updated `web/lib/memba/email_templates.ex`
     - Replaced the private email check-mark SVG helper with a Memba sprig SVG helper using the same sprig silhouette as `MembaWeb.Brand`.
     - Updated the shared email Memba mark call sites to use `memba_sprig_svg/3`.
     - This removes the check icon from sign-in emails while preserving the existing email-safe inline SVG/table treatment.
   - Updated `web/test/memba/accounts/auth_email_test.exs`
     - Added assertions that the sign-in email HTML includes the sprig leaf path.
     - Added a regression assertion that the old check-mark path is not present.

3. **Focused validation commands run and results**
   - Initial focused test after adding the assertion hit stale outer sandbox `PGHOST`/`DEVENV_*` environment before ExUnit ran; reran inside a clean devenv shell.
   - `bin/mix format --check-formatted lib/memba/email_templates.ex test/memba/accounts/auth_email_test.exs` — passed.
   - `bin/mix test test/memba/accounts/auth_email_test.exs` — passed: `8 tests, 0 failures`.
   - `dev check --quick` — passed: `757 tests, 0 failures`.
   - `git diff --check` — passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Replace the sign-in email icon with the Memba sprig asset/component used elsewhere in Memba branding.`
   - To:
     - `- [x] 004 Replace the sign-in email icon with the Memba sprig asset/component used elsewhere in Memba branding.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001 respected: change stays within the existing Phoenix/Elixir app.
   - ADR 0016 respected: no email provider boundary or Swoosh delivery behaviour changed.
   - ADR 0013 not materially affected: no browser/feature-test strategy changes; this task added focused ExUnit coverage for email rendering.