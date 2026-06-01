1. **Selected todo line**
   - `005 Build message-row receipt glance data in MembaWeb.MemberDashboardPresentation using existing member receipt projections and MembaWeb.MemberReceiptPresentation where useful:`

2. **Changes made**
   - Updated `web/lib/memba_web/member_dashboard_presentation.ex`
     - Made `present_message_rows/2` public/testable.
     - Added per-row receipt glance fields:
       - `receipt_status_counts`
       - `receipt_segments`
       - `receipt_glance_copy`
       - `has_receipt_glance?`
     - Kept receipt status vocabulary sourced from `MemberReceiptPresentation`.
     - Added `sent_at` and `sent_at_label` based on `message.inserted_at`.
     - Omits timestamp label when `inserted_at` is unavailable.
   - Updated `web/test/memba_web/member_dashboard_presentation_test.exs`
     - Added assertions for receipt counts, mini-bar segment widths, glance copy, and receipt-glance availability.
     - Added timestamp metadata assertions.
     - Added coverage that rows without `inserted_at` have no timestamp label.

3. **Validation run**
   - Focused presentation test:
     - `mix test test/memba_web/member_dashboard_presentation_test.exs`
     - Result: `3 tests, 0 failures`
   - Focused dashboard tests:
     - `mix test test/memba_web/member_dashboard_presentation_test.exs test/memba_web/live/member_dashboard_live_test.exs`
     - Result: `6 tests, 0 failures`
   - Formatting:
     - `cd web && mix format --check-formatted`
     - Result: passed
   - Full required check:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `249 tests, 0 failures`
   - Whitespace/status:
     - `git diff --check`
     - Result: passed

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Build message-row receipt glance data...`
   - To:
     - `- [x] 005 Build message-row receipt glance data...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0015 requires member application pages, including the club home/member dashboard, to use LiveView by default.
   - This task preserves the existing `MemberDashboardLive` route flow and improves the LiveView-backed dashboard’s presentation data model without reverting to controller rendering.