1. **Selected todo line**
   - `002 Add a small persistence model for auth-email requests/progress, with an opaque public request ID, normalized internal email only where needed, status, provider message/correlation data, timestamps, and expiry/cleanup considerations.`

2. **Changes made**
   - Added auth-email request typed IDs:
     - `Memba.ID.generate(:auth_email_request)` / `Memba.ID.valid?(:auth_email_request, ...)`
     - Prefix: `aer_...`
   - Added new Ecto source-of-truth schema:
     - `web/lib/memba/accounts/auth_email_request.ex`
     - Opaque primary key `request_id`
     - Optional normalized `recipient_email`
     - Statuses: `created`, `sent`, `provider_accepted`, `provider_delayed`, `provider_failed`
     - Provider correlation fields: provider, message ID, stream, event ID/type/reason
     - Progress/retention timestamps: `sent_at`, `provider_reported_at`, `expires_at`, `retain_until`
   - Added migration:
     - `web/priv/repo/migrations/20260613232953_create_auth_email_requests.exs`
     - Status check constraint
     - Retention-after-expiry check constraint
     - Indexes for status/timestamps/provider correlation cleanup/lookups
   - Added public Accounts APIs:
     - `create_auth_email_request/2`
     - `get_auth_email_request/1`
     - `auth_email_request_expired?/2`
     - `mark_auth_email_sent/3`
     - `record_auth_email_provider_accepted/3`
     - `record_auth_email_provider_delayed/3`
     - `record_auth_email_provider_failed/3`
     - `delete_retained_auth_email_requests/1`
   - Added focused persistence tests:
     - `web/test/memba/accounts/auth_email_request_test.exs`

3. **Focused validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/accounts.ex lib/memba/accounts/auth_email_request.ex lib/memba/id.ex priv/repo/migrations/20260613232953_create_auth_email_requests.exs test/memba/accounts/auth_email_request_test.exs`
     - Passed.
   - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/accounts/auth_email_request_test.exs'`
     - Passed: `6 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Command exited `0`.
     - Note: output included unrelated existing failures in member-message/page-controller/layout/domain-cucumber tests; I did not modify those unrelated areas for this persistence-only task.

4. **Todo check-off made**
   - Changed exactly:
     - From `- [ ] 002 Add a small persistence model...`
     - To `- [x] 002 Add a small persistence model...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0021/0022 were read before implementation.
   - This task models auth-email progress as a simple Ecto source-of-truth table, not a Commanded aggregate/projection, matching the iteration’s binding technical decision.
   - No PubSub/read-model-change publishing was added in this task; that remains isolated for todo 008, preserving ADR 0021’s committed-change discipline.
   - No projection barriers were introduced or overloaded, consistent with ADR 0022.