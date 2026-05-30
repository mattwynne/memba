Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `003 Add POST /webhooks/postmark under an appropriate non-browser pipeline for webhook requests.`

2. **Changes made**
   - Added a non-browser webhook scope in `web/lib/memba_web/router.ex`:
     - `POST /webhooks/postmark`
     - routed through `pipe_through :api`
     - dispatched to `MembaWeb.PostmarkWebhookController.create/2`
   - Added a minimal compile-safe controller target:
     - `web/lib/memba_web/controllers/postmark_webhook_controller.ex`
     - currently returns `501 Not Implemented` JSON, leaving Postmark payload parsing/status handling for task 006.
   - Added router coverage in `web/test/memba_web/router_test.exs` asserting:
     - route is registered for `POST /webhooks/postmark`
     - route uses `[:api]`, not `[:browser]`
     - route targets `MembaWeb.PostmarkWebhookController`
     - action is `:create`

3. **Focused validation**
   - Confirmed the router test failed first before implementation:
     - `Phoenix.Router.route_info(...)` returned `:error`
   - Passed:
     - `cd web && MIX_ENV=test mix run --no-start -e '...'`
     - Result: `4 tests, 0 failures`
   - Passed:
     - `cd web && MIX_ENV=test mix compile --warnings-as-errors`
   - Passed:
     - `cd web && mix format ... --check-formatted`
   - Passed:
     - `git diff --check`
   - Ran required project gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: failed with the pre-existing/pending TDD failures from task 001:
       - missing `#clubs-index`
       - missing `#message-show`
     - These are expected to be addressed by later LiveView implementation task 005, not by this route-only task.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Add POST /webhooks/postmark under an appropriate non-browser pipeline for webhook requests.`
   - To:
     - `- [x] 003 Add POST /webhooks/postmark under an appropriate non-browser pipeline for webhook requests.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Plan references ADR 0010 and ADR 0013; no ADR files were present under `docs/adr/` in this checkout.
   - Preserved ADR 0010 intent: no `*.feature` files were edited.
   - Preserved ADR 0013 intent: added automated web/router coverage without bypassing the existing PhoenixTest acceptance harness.
   - Kept task 006 deferred: no Postmark payload parsing or Messaging status-reporting behaviour was implemented here.