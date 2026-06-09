1. **Selected todo line**
   - `009 Preserve Staff request inbox and notification behaviour for verified submitted requests.`

2. **Changes made**
   - Updated `web/test/memba_web/live/admin/requests_live/index_test.exs`.
   - Added a regression test that:
     - submits `/get-started` as a signed-in verified identity;
     - proves the saved active request uses the verified identity email, not a forged typed email;
     - asserts the Staff new-request notification email is sent with the expected request details and admin request link;
     - opens the Staff active requests inbox and verifies the submitted request appears with requester, email, club, note, reject action, and convert action.
   - Added `alias MembaWeb.IdentityAuth` for the test session setup.

3. **Focused validation commands/results**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba_web/live/admin/requests_live/index_test.exs`
     - Passed.
   - Initial direct focused test hit the known sandbox Postgres readiness path mismatch.
   - Retried focused test successfully:
     - `devenv shell -- bash -lc 'cd web && mix test test/memba_web/live/admin/requests_live/index_test.exs:112 --seed 0'`
     - Passed: `10 tests, 0 failures, 9 excluded`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed after fixing the test assertion callback return value: `747 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 009 Preserve Staff request inbox and notification behaviour for verified submitted requests.`
   - To:
     - `- [x] 009 Preserve Staff request inbox and notification behaviour for verified submitted requests.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No `docs/adr/*.md` files were present.
   - The change is focused test coverage for the selected plan item and preserves the existing Staff notification/inbox behaviour for verified submitted onboarding requests.