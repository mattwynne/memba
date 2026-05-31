Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 003 Add configuration for selecting the Postmark provider only when explicitly configured, preserving the fake provider for tests and local defaults.`

2. **Changes made**
   - Added runtime provider selection via `MEMBA_MESSAGING_DELIVERY_PROVIDER` in `web/config/runtime.exs`.
     - Unset/blank env var leaves existing default config in place.
     - `postmark` selects `Memba.Messaging.DeliveryProviders.Postmark`.
     - `fake` explicitly selects `Memba.Messaging.DeliveryProviders.Fake`.
     - Unknown values raise a clear configuration error.
   - Added `Memba.Messaging.DeliveryProviderConfig` to parse and validate provider selection.
   - Added a minimal `Memba.Messaging.DeliveryProviders.Postmark` module implementing the existing provider behaviour and failing visibly for now instead of falling back to fake delivery. Later tasks will add token/from validation and real Swoosh delivery.
   - Added focused tests:
     - Provider config parsing/default behavior.
     - DeliveryProvider default fake behavior.
     - Explicit Postmark selection does not silently use fake.

3. **Validation commands run**
   - `cd web && mix compile` — passed.
   - `cd web && MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark mix run --no-start -e 'IO.inspect(Application.fetch_env!(:memba, :messaging_delivery_provider))'` — passed; printed `Memba.Messaging.DeliveryProviders.Postmark`.
   - `git diff --check` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - `118 tests, 0 failures`.
   - Note: an initial direct `mix test ...` attempt without the dev-managed Postgres service failed due missing DB; `dev check` reran the suite with required services and passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Add configuration for selecting the Postmark provider only when explicitly configured, preserving the fake provider for tests and local defaults.`
   - To:
     - `- [x] 003 Add configuration for selecting the Postmark provider only when explicitly configured, preserving the fake provider for tests and local defaults.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0004: No delivery-state ownership changes; provider selection only.
   - ADR 0005: Existing `DeliveryProvider.deliver/1` boundary remains unchanged.
   - ADR 0006: No delivery status vocabulary or member-facing status changes.
   - ADR 0007: No Membership coupling or storage access introduced.
   - ADR 0012: No open-tracking semantics changed; later Postmark tasks will add open tracking through the existing model.