Implemented the next unchecked task.

1. **Selected todo line**
   - `- [ ] 004 Update projections/read models and loaders so current status lists, summaries, and grouping functions do not include opened.`

2. **Changes made**
   - Updated Messaging projectors so historic `EmailDeliveryOpened` events project as `delivered`, not `opened`:
     - `web/lib/memba/messaging/projectors/member_email_delivery.ex`
     - `web/lib/memba/messaging/projectors/memba_staff_email_delivery.ex`
   - Added read-model query normalization in `web/lib/memba/messaging.ex` so any existing/historic projection row with status `"opened"` is returned as `"delivered"`:
     - member-facing delivery getters/lists;
     - Memba-staff delivery getters/lists;
     - operator delivery overview.
   - Added projection/read-model tests proving:
     - historic opened events map to delivered;
     - stored historic opened rows are normalized to delivered through current query APIs.
   - Updated member message detail/live tests that seed legacy `"opened"` rows so they now expect those rows to appear in delivered groups/counts via the loader/read-model normalization.
   - Checked off only task `004` in `docs/iterations/017-remove-open-tracking/todo.md`.

3. **Focused validation**
   - `mix test test/memba/messaging/member_email_delivery_projection_test.exs test/memba/messaging/memba_staff_email_delivery_projection_test.exs`
     - `12 tests, 0 failures`
   - `mix test test/memba_web/controllers/member_message_detail_test.exs test/memba_web/live/member_message_live/show_test.exs`
     - `11 tests, 0 failures`
   - `mix format --check-formatted ...`
     - passed
   - `PATH="$PWD/bin:$PATH" dev check`
     - `377 tests, 0 failures`
   - `git diff --check`
     - passed

4. **Todo check-off made**
   - Changed:
     - `- [ ] 004 Update projections/read models and loaders so current status lists, summaries, and grouping functions do not include opened.`
   - To:
     - `- [x] 004 Update projections/read models and loaders so current status lists, summaries, and grouping functions do not include opened.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Preserved ADR 0004’s one-message aggregate boundary.
   - Preserved ADR 0007’s Messaging bounded-context query/API boundary.
   - Preserved ADR 0009’s Commanded Ecto projection architecture.
   - Treated ADR 0012’s opened tracking decision as superseded by this approved iteration plan while keeping historic `EmailDeliveryOpened` compatibility by mapping it to delivered instead of exposing opened as current behaviour.