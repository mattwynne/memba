1. **Selected todo line**
   - `- [ ] 001 Update web/lib/memba_web/router.ex:`

2. **Changes made**
   - Updated `web/lib/memba_web/router.ex`:
     - Added a new `:staff_browser` pipeline mirroring the browser plugs.
     - Kept public controller routes under `/`.
     - Moved existing LiveView routes under `/admin`:
       - `/admin/clubs`
       - `/admin/clubs/:club_id`
       - `/admin/deliveries`
       - `/admin/messages/:message_id`
     - Removed the old public harness LiveView routes from `/clubs`, `/deliveries`, and `/messages`.
     - Left `POST /webhooks/postmark` unchanged.
   - Updated `web/test/memba_web/router_test.exs` to assert the new `/admin/*` route table entries and `[:staff_browser]` pipeline.
   - Updated verified route references and test visits that became invalid after removing the old routes, so the codebase could compile and pass `dev check`:
     - LiveView internal links now use `/admin/*`.
     - Homepage operational/admin links now point to `/admin/clubs` and are labelled as staff/admin.
     - Existing feature-style web tests now visit `/admin/*`.

3. **Validation commands run**
   - `cd web && mix test test/memba_web/router_test.exs`
     - Failed because Postgres was not running outside the repo’s `bin/dev` wrapper.
   - `PATH="$PWD/bin:$PATH" dev check`
     - First run failed on verified-route warnings after old routes were removed.
     - Second run failed on existing tests still visiting removed public harness routes.
     - Final run passed:
       - `132 tests, 0 failures`
       - Exit code `0`

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 001 Update web/lib/memba_web/router.ex:`
   - To:
     - `- [x] 001 Update web/lib/memba_web/router.ex:`

5. **Todo splits/additions/reordering**
   - None.
   - I did make minimal route/link/test path updates that overlap later todo intent because removing the old routes made verified routes and existing tests fail under `dev check`. Those updates were necessary to complete the router task while leaving the codebase green.

6. **ADR conformance evidence**
   - No ADR was explicitly referenced by the plan.
   - Inspected relevant accepted ADRs:
     - ADR 0001: continues using Phoenix/Phoenix LiveView for the web surface.
     - ADR 0013: existing PhoenixTest-style web tests were preserved and updated only for path changes.
   - No acceptance feature files were modified.