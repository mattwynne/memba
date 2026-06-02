Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 007 Update member LiveViews/presentation modules/tests to remove opened receipt segments, groups, toggles, counts, data attributes, and copy.`

2. **Changes made**
   - `web/lib/memba_web/member_email_delivery_presentation.ex`
     - Removed `opened` from current member-facing status order, labels, icons, and descriptions.
     - Reworded delivered copy from “arrived, not opened yet” to “delivered to their inbox”.
     - Folded historic `"opened"` projection rows into current `"delivered"` presentation so member UI never exposes opened.
   - `web/lib/memba_web/member_dashboard_presentation.ex`
     - Changed dashboard receipt glance copy from opened-count wording to delivered-count wording.
   - `web/lib/memba_web/controllers/page_html.ex`
     - Removed opened-specific UI color/tint helpers.
   - `web/lib/memba_web/controllers/page_html/message.html.heex`
     - Updated receipt group ordering copy to omit opened.
   - Updated member-facing tests:
     - `web/test/memba_web/member_email_delivery_presentation_test.exs`
     - `web/test/memba_web/member_dashboard_presentation_test.exs`
     - `web/test/memba_web/member_message_detail_loader_test.exs`
     - `web/test/memba_web/controllers/member_message_detail_test.exs`
     - `web/test/memba_web/live/member_message_live/show_test.exs`
     - `web/test/memba_web/live/member_dashboard_live_test.exs`
   - Tests now prove opened receipts are not rendered as member-facing segments, groups, toggles, counts, data attributes, icons, or copy, while historic opened rows are displayed as Delivered.

3. **Focused validation**
   - `cd web && mix format --check-formatted ...`
     - Passed for changed Elixir files.
   - Direct focused `mix test ...` was attempted, but cannot run outside the dev wrapper in this sandbox because the Postgres socket is unavailable.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `379 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - Search review:
     - `grep -RInE "opened|open tracking|not opened|arrived|hero-envelope-open" web/lib/memba_web web/test/memba_web`
     - Remaining member-facing matches are compatibility/test assertions proving historic opened rows are folded away or opened selectors are absent. Staff/admin and provider webhook matches are for other iteration tasks.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 007 Update member LiveViews/presentation modules/tests to remove opened receipt segments, groups, toggles, counts, data attributes, and copy.`
   - To:
     - `- [x] 007 Update member LiveViews/presentation modules/tests to remove opened receipt segments, groups, toggles, counts, data attributes, and copy.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Reviewed relevant ADRs:
     - ADR 0001 Phoenix core app.
     - ADR 0015 LiveView for member application pages.
     - ADR 0013 PhoenixTest for feature-style web tests.
     - ADR 0004 message deliverability aggregate boundary.
     - ADR 0006 simplified member-facing delivery status.
     - ADR 0012 opened status assumptions.
     - ADR 0016 provider boundary.
   - This task preserves LiveView/member-page architecture and the provider/domain boundaries.
   - ADRs 0006/0012 contain older opened assumptions; the approved iteration plan intentionally supersedes those current product assumptions.