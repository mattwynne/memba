1. **Selected todo line**
   - `003 Build the delivery page template per delivery-details.html: header (subject / sender / inserted_at), summary bar + legend, grouped recipients (problems expanded, delivered collapsed).`

2. **Changes made for this task only**
   - Updated `web/lib/memba_web/live/member_message_delivery_live/show.ex`:
     - Replaced the scaffold with a delivery-details-style template.
     - Added header content showing:
       - `Delivery — “subject”`
       - sender name
       - formatted `inserted_at` in a `<time>` element
       - recipient/member count
     - Added delivery summary section:
       - `delivery-summary`
       - proportional `delivery-bar`
       - `delivery-legend`
     - Added grouped recipient sections:
       - Delivery problems first and expanded by default via `<details open>`.
       - Delivered group collapsed by default via `<details>` without `open`.
       - Recipient rows use the `recipient` / `recipient__*` class structure.
     - Kept delivery data/status values unchanged; display copy maps `"delivery problem"` to `"Didn't go through"` for the refreshed UI.
   - Updated `web/test/memba_web/live/member_message_delivery_live/show_test.exs`:
     - Added assertions for the new header/meta, summary bar, legend, expanded problem group, and collapsed delivered group.

3. **Focused validation commands run and results**
   - TDD failing check after adding expectations:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_delivery_live/show_test.exs`
     - Failed as expected before implementation.
   - Focused passing check:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_delivery_live/show_test.exs`
     - Passed: `2 tests, 0 failures`.
   - Formatting check:
     - `cd web && mix format --check-formatted lib/memba_web/live/member_message_delivery_live/show.ex test/memba_web/live/member_message_delivery_live/show_test.exs`
     - Passed.
   - Full browser-facing/UI validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance suite: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Build the delivery page template per ...`
   - To:
     - `- [x] 003 Build the delivery page template per ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan did not explicitly reference ADR files, and no `docs/adr/` files were present to read.
   - This task remains aligned with the previously validated architecture:
     - Phoenix/LiveView UI surface retained.
     - Existing member delivery presentation model/status values reused.
     - No delivery business logic or status computation changed.
     - The delivery details page remains URL-addressable on the already-added member route.