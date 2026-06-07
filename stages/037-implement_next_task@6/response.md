1. **Selected todo line**
   - `006 Update web/lib/memba/onboarding/welcome_email.ex to use the compatible group-led welcome/sign-in variant and pass the converted club as context.`

2. **Changes made**
   - Updated `web/lib/memba/onboarding/welcome_email.ex`:
     - Builds a sanitized welcome context from the converted club and requester.
     - Uses a group-led sender display name: `{club name} via Memba`.
     - Keeps the welcome subject shape as `Welcome to {club} on Memba` to preserve existing acceptance expectations.
     - Replaces bare HTML with the shared v2 email shell/components:
       - group header;
       - card/heading/body;
       - primary button plus fallback URL;
       - one-use/expiry reassurance;
       - Memba trust footer;
       - no hard-coded support mailbox.
     - Preserves existing auth email config, provider options, sign-in token generation, and member-home callback URL behaviour.
   - Updated `web/test/memba/onboarding/welcome_email_test.exs`:
     - Verifies group-led sender/context.
     - Verifies v2 HTML structure/copy, fallback URL, trust footer, and no bare `<html><body>` template.
     - Verifies callback URL still works and is escaped in HTML.
     - Adds coverage for escaping/sanitizing requester and club names containing HTML-like text and header newlines.
   - Checked off only todo `006`.

3. **Focused validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/onboarding/welcome_email.ex test/memba/onboarding/welcome_email_test.exs`
     - Passed.
   - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/onboarding/welcome_email_test.exs`
     - Passed: `2 tests, 0 failures`.
   - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/onboarding_conversion_test.exs test/memba_web/live/admin/requests_live/index_test.exs`
     - Passed: `13 tests, 0 failures`.
   - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `577 tests, 0 failures`.
   - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" dev check`
     - Passed: ExUnit `577 tests, 0 failures`; acceptance `44 scenarios, 291 steps passed`.
   - `git diff --check`
     - Passed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 006 Update web/lib/memba/onboarding/welcome_email.ex to use the compatible group-led welcome/sign-in variant and pass the converted club as context.`
   - To:
     - `- [x] 006 Update web/lib/memba/onboarding/welcome_email.ex to use the compatible group-led welcome/sign-in variant and pass the converted club as context.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No `docs/adr/*.md` files were present/referenced for this task.
   - The change follows the iteration plan constraints:
     - no provider selection/configuration changes;
     - no DNS/sender-domain changes;
     - no token lifetime/auth policy changes;
     - provider metadata/options preserved;
     - welcome email now uses the shared v2-compatible email rendering system with club context.