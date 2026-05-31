Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 004 Add required configuration for Postmark server token and sender/from address, with clear error reporting when real sending is enabled but configuration is incomplete.`

2. **Changes made**
   - Added `Memba.Messaging.DeliveryProviders.PostmarkConfig`.
     - Reads required env vars:
       - `MEMBA_POSTMARK_SERVER_TOKEN`
       - `MEMBA_POSTMARK_FROM_ADDRESS`
     - Trims values and treats blank values as missing.
     - Returns/raises clear configuration errors when Postmark is enabled but config is incomplete.
   - Updated `web/config/runtime.exs`.
     - When `MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark`, runtime now:
       - validates required Postmark config,
       - configures `Memba.Mailer` with `Swoosh.Adapters.Postmark`,
       - sets Postmark `api_key` from `MEMBA_POSTMARK_SERVER_TOKEN`,
       - stores the sender/from address for the Postmark provider,
       - configures Swoosh to use `Swoosh.ApiClient.Req`.
   - Updated `Memba.Messaging.DeliveryProviders.Postmark`.
     - It now validates required app config during delivery.
     - Missing config returns a hard, visible `{:error, {:postmark_configuration_error, message}}`.
     - Complete config still returns the existing later-slice placeholder failure instead of sending email.
   - Added/updated tests for:
     - environment config parsing,
     - missing config error messages,
     - provider-level missing-config behaviour,
     - successful required-config validation before later email-building work.

3. **Validation commands run**
   - `cd web && mix format --check-formatted ... && mix compile` — passed.
   - `cd web && MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark MEMBA_POSTMARK_SERVER_TOKEN=server-token MEMBA_POSTMARK_FROM_ADDRESS=messages@mail.memba.io mix run --no-start -e ...` — passed; confirmed Postmark provider, mailer adapter/API key/from config, and `Swoosh.ApiClient.Req`.
   - `cd web && MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark MEMBA_POSTMARK_SERVER_TOKEN=server-token mix run --no-start -e ':ok'` — failed as expected with a clear missing `MEMBA_POSTMARK_FROM_ADDRESS` error.
   - `git diff --check` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - `122 tests, 0 failures`.
   - Note: an initial direct `mix test --no-start ...` outside the dev-managed Postgres environment failed because the project test alias attempted DB setup without Postgres. The final `dev check` ran with required services and passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Add required configuration for Postmark server token and sender/from address, with clear error reporting when real sending is enabled but configuration is incomplete.`
   - To:
     - `- [x] 004 Add required configuration for Postmark server token and sender/from address, with clear error reporting when real sending is enabled but configuration is incomplete.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0004: No delivery-state ownership or aggregate changes.
   - ADR 0005: Existing resolved-recipient/provider boundary remains intact.
   - ADR 0006: No delivery status vocabulary or member-facing receipt changes.
   - ADR 0007: No Membership context coupling introduced.
   - ADR 0012: No open-tracking semantics changed; that remains for the later open-tracking task.