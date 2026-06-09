1. **Selected todo line**
   - `012 Add or update domain/context tests proving request creation requires a verified identity email and does not create membership-domain records.`

2. **Changes made**
   - Updated `Memba.Onboarding.Request.create_changeset/2` so request creation:
     - no longer trusts `requester_email` from typed attrs;
     - requires `opts[:verified_identity_email]`;
     - stores the normalized verified identity email as both `requester_email` and `normalized_requester_email`;
     - errors with `requester_email: "must be verified"` when no verified identity email is supplied.
   - Updated `MembaWeb.PageController` to pass `verified_identity_email` when creating `/get-started` requests.
   - Added/updated domain/context tests in `web/test/memba/onboarding_test.exs` proving:
     - typed requester email is ignored in favor of verified identity email;
     - request creation without verified identity email is rejected;
     - verified request submission creates no membership-domain projection records and grants no active clubs.
   - Updated direct test fixtures/callers to pass the verified identity email:
     - `web/test/memba/onboarding_conversion_test.exs`
     - `web/test/memba_web/live/admin/requests_live/index_test.exs`
   - Minimal Cucumber domain step helper update in:
     - `web/test/features/step_definitions/request_account_steps.exs`
     - This was needed because `dev check --quick` runs existing domain Cucumber scenarios that create onboarding requests directly.

3. **Focused validation commands/results**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted ...`
     - Passed after formatting fixes.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba/onboarding_test.exs test/memba/onboarding_conversion_test.exs --seed 0`
     - Hit sandbox PGHOST readiness mismatch.
   - `devenv shell -- bash -lc 'cd web && mix test test/memba/onboarding_test.exs test/memba/onboarding_conversion_test.exs --seed 0'`
     - Passed: `16 tests, 0 failures`.
   - `devenv shell -- bash -lc 'cd web && mix test test/memba_web/controllers/page_controller_test.exs test/memba_web/live/admin/requests_live/index_test.exs --seed 0'`
     - Passed: `50 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `750 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 012 Add or update domain/context tests proving request creation requires a verified identity email and does not create membership-domain records.`
   - To:
     - `- [x] 012 Add or update domain/context tests proving request creation requires a verified identity email and does not create membership-domain records.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Reviewed ADRs `0002`, `0003`, and `0011`.
   - The onboarding request remains an explicitly chosen Ecto source-of-truth model; membership-domain command/event conversion behaviour is unchanged.
   - Existing domain Cucumber step plumbing remains aligned with ADR 0003’s domain-layer acceptance boundary by calling the domain/context API with verified identity data.
   - Caller-generated typed IDs remain unchanged and consistent with ADR 0011.