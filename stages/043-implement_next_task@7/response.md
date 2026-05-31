1. **Selected todo line**
   - `- [ ] 007 Add route tests asserting old harness paths return 404 (not redirects).`

2. **Changes made**
   - Updated `web/test/memba_web/router_test.exs`.
   - Switched the test module to `MembaWeb.ConnCase` so route requests can be exercised through the endpoint.
   - Added coverage for removed harness paths:
     - `/clubs`
     - `/clubs/club-123`
     - `/deliveries`
     - `/messages/message-123`
   - Each path now asserts:
     - response status/content is the normal 404: `"Not Found"`
     - no redirect `Location` header is present.

3. **Validation commands run**
   - `PATH="$PWD/bin:$PATH" dev exec --dir web -- mix test test/memba_web/router_test.exs`
     - Failed: `dev` has no `exec --dir` support.
   - `cd web && mix test test/memba_web/router_test.exs`
     - Failed: Postgres was not running outside the dev wrapper.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `137 tests, 0 failures`.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 007 Add route tests asserting old harness paths return 404 (not redirects).`
   - To:
     - `- [x] 007 Add route tests asserting old harness paths return 404 (not redirects).`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR / plan conformance**
   - No ADRs are explicitly referenced by this plan.
   - The change directly satisfies acceptance criteria for old harness URLs returning 404 with no redirects.
   - No acceptance feature files were changed.
   - No routes, redirects, fake club resolution, or member-facing routing were introduced.