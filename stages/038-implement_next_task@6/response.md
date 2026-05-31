Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 006 Enable universal Postmark open tracking for member-message emails through the supported Swoosh/Postmark mechanism.`

2. **Changes made**
   - Updated `web/lib/memba/messaging/delivery_providers/postmark.ex`
     - Adds `put_provider_option(:track_opens, true)` to every Postmark member-message email.
     - This uses Swoosh’s supported Postmark provider option, which maps to Postmark’s `TrackOpens` API field.
   - Updated `web/test/memba/messaging/delivery_providers/postmark_test.exs`
     - Existing provider payload test now proves `track_opens: true` is set alongside correlation metadata.
   - Updated `docs/iterations/008-postmark-email-integration/todo.md`
     - Checked off only task `006`.

3. **Focused validation commands run**
   - `cd web && mix format --check-formatted` — passed.
   - `cd web && mix compile --warnings-as-errors` — passed.
   - `cd web && MIX_ENV=test mix run --no-start -e ...` — passed; verified the Postmark provider emits a Swoosh test email with `track_opens: true` and metadata.
   - `cd web && MIX_ENV=test mix run --no-start -e ...` — passed; verified `Swoosh.Adapters.Postmark` maps `:track_opens` to Postmark API JSON field `"TrackOpens": true`.
   - `PATH="$PWD/bin:$PATH" dev check` — passed: `124 tests, 0 failures`.
   - `git diff --check` — passed.
   - Note: a direct `mix test ...` attempt outside the dev-managed Postgres environment failed because Postgres was not running; the required `dev check` ran successfully with services.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 006 Enable universal Postmark open tracking for member-message emails through the supported Swoosh/Postmark mechanism.`
   - To:
     - `- [x] 006 Enable universal Postmark open tracking for member-message emails through the supported Swoosh/Postmark mechanism.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0012: Preserved opened-as-boolean semantics; this only enables provider open tracking and does not introduce counts/timestamps.
   - ADR 0004: Delivery state remains owned by the message aggregate; no state-machine changes.
   - ADR 0005: Provider still consumes existing resolved-recipient `DeliveryRequest`s.
   - ADR 0006: No delivery status vocabulary changes.
   - No acceptance feature files were modified.