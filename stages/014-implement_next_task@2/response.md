Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 002 Decide the smallest provider shape: likely Memba.Messaging.DeliveryProviders.Postmark implementing Memba.Messaging.DeliveryProvider and using Memba.Mailer/Swoosh.`

2. **Changes made**
   - Added `docs/iterations/008-postmark-email-integration/provider-shape.md`.
   - Documented the chosen smallest provider shape:
     - Add `Memba.Messaging.DeliveryProviders.Postmark`.
     - Implement existing `Memba.Messaging.DeliveryProvider`.
     - Use one `DeliveryRequest` per `deliver/1` call.
     - Build `Swoosh.Email`.
     - Deliver via `Memba.Mailer.deliver/1`.
     - Use Swoosh/Postmark provider options for metadata and open tracking in later tasks.
     - Avoid adding new ports, behaviours, direct HTTP code, batching, retries, process managers, or domain events.
   - Confirmed local Swoosh/Postmark API support from checked-in dependency source:
     - `:metadata`
     - `:track_opens`
     - `Swoosh.ApiClient.Req`
     - `Memba.Mailer.deliver/1` return shape.
   - Updated `todo.md` to check off only task `002`.

3. **Focused validation**
   - `git diff --check` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed.
     - ExUnit: `112 tests, 0 failures`.
     - Command exited `0`.
     - Devenv manager emitted the usual shutdown SIGKILL after successful completion.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 002 Decide the smallest provider shape: likely Memba.Messaging.DeliveryProviders.Postmark implementing Memba.Messaging.DeliveryProvider and using Memba.Mailer/Swoosh.`
   - To:
     - `- [x] 002 Decide the smallest provider shape: likely Memba.Messaging.DeliveryProviders.Postmark implementing Memba.Messaging.DeliveryProvider and using Memba.Mailer/Swoosh.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0004: Keeps delivery state owned by the message aggregate and correlated by Memba IDs, not Postmark IDs.
   - ADR 0005: Preserves the existing channel-neutral `DeliveryRequest` provider boundary.
   - ADR 0006: Leaves member-facing status simplification unchanged; provider outcomes remain webhook-driven.
   - ADR 0007: Does not couple Messaging to Membership storage or queries.
   - ADR 0012: Supports opened-at-least-once tracking without introducing counts or extra telemetry.