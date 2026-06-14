Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `009 Add tests for known/unknown submissions, metadata, webhook correlation, duplicate webhook idempotency, live update behaviour, expiry, fallback timing, and privacy-preserving copy.`

2. **Changes made**
   - Added focused test coverage for:
     - Duplicate provider progress idempotency and no duplicate PubSub notification.
     - Duplicate Postmark auth-stream delivered webhook idempotency.
     - Check-email fallback copy staying hidden before the 60-second threshold.
     - Expired check-email request rendering neutral expired guidance.
     - Known/unknown check-email pages preserving privacy by omitting submitted emails and account-existence wording.
   - Added a small implementation fix required by the duplicate-idempotency tests:
     - Duplicate auth-email provider progress events with the same status, provider event ID, and provider event type now return the existing persisted request without rewriting timestamps.
     - Duplicate no-op updates do not publish a second auth-email progress PubSub notification.

3. **Focused validation**
   - Initial preferred wrapper command failed due the known sandbox PGHOST mismatch:
     - `PATH="$PWD/bin:$PATH" bin/mix test ...`
     - Failure: `Postgres did not become ready at PGHOST=/tmp/devenv/postgres PGPORT=15432`
   - Re-ran focused tests inside `devenv shell`:
     - `cd web && mix test test/memba/accounts/auth_email_request_test.exs test/memba/accounts/auth_email_test.exs test/memba_web/controllers/auth_controller_test.exs test/memba_web/controllers/postmark_webhook_controller_test.exs`
     - Result: `57 tests, 0 failures`
   - Formatted touched Elixir files:
     - `cd web && mix format lib/memba/accounts.ex test/memba/accounts/auth_email_request_test.exs test/memba_web/controllers/auth_controller_test.exs test/memba_web/controllers/postmark_webhook_controller_test.exs`
   - Re-ran focused tests after formatting:
     - Result: `57 tests, 0 failures`
   - `git diff --check`
     - Result: passed
   - Broad quick validation attempted:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: failed with unrelated existing failures outside this task, including `DomainCucumberRunnerTest`, `LayoutsTest`, `PageControllerTest`, and `MemberMessageDetailTest`. Representative focused re-run confirmed those failures are deterministic but unrelated to the selected auth-email progress task.

4. **Todo check-off made**
   - Changed exactly:
     - From: `- [ ] 009 Add tests for known/unknown submissions, metadata, webhook correlation, duplicate webhook idempotency, live update behaviour, expiry, fallback timing, and privacy-preserving copy.`
     - To: `- [x] 009 Add tests for known/unknown submissions, metadata, webhook correlation, duplicate webhook idempotency, live update behaviour, expiry, fallback timing, and privacy-preserving copy.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0021: duplicate no-op progress events do not emit extra committed-change notifications; real committed updates still publish after persistence commits.
   - ADR 0022: no projection barrier or read-your-writes mechanism was introduced or conflated with PubSub.
   - Privacy: new tests assert check-email pages do not expose submitted email addresses or account-existence wording; PubSub payload remains narrow and opaque.