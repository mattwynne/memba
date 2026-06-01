1. **Selected todo line**
   - `006 Add a presentation mapping for member receipt labels and Heroicons without changing internal projection values.`

2. **Changes made**
   - Added `MembaWeb.MemberReceiptPresentation`:
     - `sent` → `Sending`, `hero-clock`
     - `delivered` → `Delivered`, `hero-check-circle`
     - `delivery problem` → `Delivery problem`, `hero-exclamation-triangle`
     - `opened` → `Opened`, `hero-envelope-open`
   - Updated member message detail rendering to:
     - display member-facing labels/icons;
     - keep raw internal projection statuses in `data-receipt-status`;
     - expose `data-testid="receipt-status-icon"` and `data-icon-name` for browser assertions.
   - Updated `PageController` to present receipts before grouping/rendering.
   - Added focused unit tests for the presentation mapping.
   - Updated the existing member message detail controller test to assert labels and icons.
   - Extended the shared `<.icon>` component to allow global attrs so receipt icons can expose test/data attributes safely.

3. **Focused validation**
   - `cd web && mix format --check-formatted && mix compile --warnings-as-errors`
     - Passed.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'mix test test/memba_web/member_receipt_presentation_test.exs test/memba_web/controllers/page_controller_test.exs'`
     - Passed: `17 tests, 0 failures`.
   - `cd acceptance-tests && node --test test/member_message_steps.test.js test/member_harness.test.js`
     - Passed: `22 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `211 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Add a presentation mapping for member receipt labels and Heroicons without changing internal projection values.`
   - To:
     - `- [x] 006 Add a presentation mapping for member receipt labels and Heroicons without changing internal projection values.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR / architecture conformance**
   - Presentation-only change: no messaging projection values, commands, events, or persistence schemas were changed.
   - Member pages now show friendly labels/icons while retaining raw internal status values only in stable test/data attributes.
   - Used Phoenix’s `<.icon>` component for Heroicons, consistent with Phoenix 1.8 project guidance.
   - Staff/admin diagnostics routes were not changed.