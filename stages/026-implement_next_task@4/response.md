Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `004 Update projections/read models and loaders so current status lists, summaries, and grouping functions do not include opened.`

2. **Changes made**
   - Removed `EmailDeliveryOpened` handling from current member and Memba-staff email delivery projectors so replay/current projection output no longer writes `"opened"`.
   - Added query-layer normalization for legacy `"opened"` projection rows:
     - member-facing rows are returned as `"delivered"`;
     - Memba-staff rows are returned as `"delivered"` with `reason: nil`.
   - Updated projection/read-model docs to describe the current status vocabularies.
   - Updated member receipt summary/grouping presentation:
     - removed `"opened"` from status ordering and summaries;
     - coalesced legacy `"opened"` input to `"delivered"`;
     - changed delivered copy from “arrived, not opened yet” to “arrived”.
   - Updated dashboard receipt-glance summary to report delivered counts instead of opened counts.
   - Updated affected projection, loader, presentation, controller, and LiveView tests to assert no opened summary/group/segment is produced from current loaders/status grouping.

3. **Focused validation**
   - `mix format --check-formatted ...` for changed files: passed.
   - Focused tests inside devenv/Postgres:
     - `mix test test/memba/messaging/member_email_delivery_projection_test.exs test/memba/messaging/memba_staff_email_delivery_projection_test.exs test/memba_web/member_email_delivery_presentation_test.exs test/memba_web/member_message_detail_loader_test.exs test/memba_web/member_dashboard_presentation_test.exs test/memba_web/live/member_message_live/show_test.exs test/memba_web/live/member_dashboard_live_test.exs test/memba_web/controllers/member_message_detail_test.exs`
     - Result: `45 tests, 0 failures`.
   - Required full gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `357 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Update projections/read models and loaders so current status lists, summaries, and grouping functions do not include opened.`
   - To:
     - `- [x] 004 Update projections/read models and loaders so current status lists, summaries, and grouping functions do not include opened.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Preserved ADR 0004’s message-aggregate/read-model shape.
   - Preserved ADR 0007’s Messaging bounded-context query API boundary.
   - Preserved ADR 0009’s Commanded Ecto projection architecture.
   - Updated behavior to align with the validated iteration plan’s newer policy over ADR 0006/0012’s old opened vocabulary, while retaining legacy opened compatibility by coercing historic projection rows to delivered rather than requiring migration/backfill.