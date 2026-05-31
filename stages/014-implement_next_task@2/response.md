1. **Selected todo line**
   - `- [ ] 001a Reconcile the missing post-iteration-009 admin route structure before auth gates: move the existing harness LiveViews under /admin/*, introduce a :staff_browser seam, update links/tests, and preserve POST /webhooks/postmark.`

2. **Changes made**
   - Added a `:staff_browser` router pipeline.
   - Moved existing harness LiveViews into the admin namespace:
     - `MembaWeb.Admin.ClubsLive.Index`
     - `MembaWeb.Admin.ClubsLive.Show`
     - `MembaWeb.Admin.DeliveriesLive.Index`
     - `MembaWeb.Admin.MessagesLive.Show`
   - Rehomed routes under `/admin/*`:
     - `/admin/clubs`
     - `/admin/clubs/:club_id`
     - `/admin/deliveries`
     - `/admin/messages/:message_id`
   - Removed old public harness routes from `/clubs`, `/deliveries`, and `/messages/*`.
   - Updated internal LiveView links and homepage links to point at `/admin/*`.
   - Preserved `POST /webhooks/postmark` unchanged through the `:api` pipeline.
   - Updated Phoenix tests and acceptance support/unit tests for the new admin paths.
   - Did not edit acceptance `.feature` files.

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed.
     - `133 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" mix phx.routes`
     - Confirmed `/admin/*` LiveView routes and unchanged `POST /webhooks/postmark`.
   - `cd acceptance-tests && npm_config_cache=/tmp/npm-cache npm run test:config`
     - Passed.
     - `27 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 001a Reconcile the missing post-iteration-009 admin route structure before auth gates: move the existing harness LiveViews under /admin/*, introduce a :staff_browser seam, update links/tests, and preserve POST /webhooks/postmark.`
   - To:
     - `- [x] 001a Reconcile the missing post-iteration-009 admin route structure before auth gates: move the existing harness LiveViews under /admin/*, introduce a :staff_browser seam, update links/tests, and preserve POST /webhooks/postmark.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Plan referenced no explicit ADRs.
   - Re-checked relevant accepted ADRs:
     - ADR 0001: Phoenix remains the core web stack.
     - ADR 0013: PhoenixTest remains used for feature-style web tests.
   - No new HTTP clients were introduced.
   - No acceptance feature files were changed.