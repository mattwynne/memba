Implemented the next unchecked task.

1. **Selected todo line**
   - `005 Re-map the member delivery-status colours to sage/warning/error in the member presentation/helper used by the receipt mini-bars and the message-read breakdown card (e.g. the member status_bg_class/MemberEmailDeliveryPresentation path), without touching the staff delivery path. Apply status_badge where a pill is the right element.`

2. **Changes made**
   - Updated `MembaWeb.MemberEmailDeliveryPresentation` to provide member-only design-system mapping:
     - Delivered → sage bar/text/tint + `success` badge tone
     - Sending → warning bar/text/tint + `warning` badge tone
     - Delivery problem → error bar/text/tint + `error` badge tone
   - Updated `PageHTML` member delivery helpers to delegate to `MemberEmailDeliveryPresentation`.
   - Updated member message receipt rows to use `<.status_badge>` for the status pill while preserving the existing visible `receipt-status-icon` selector used by acceptance coverage.
   - Updated tests for:
     - Member delivery colour/tone mapping.
     - Club-home receipt mini-bar classes.
     - Message detail receipt summary bar classes.
     - Message detail receipt status badge usage.
     - Staff/admin diagnostic delivery classes remaining unchanged.
   - No acceptance feature files were changed.

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted ...` — passed.
   - Focused tests:
     - `bin/mix test test/memba_web/member_email_delivery_presentation_test.exs test/memba_web/live/member_message_live/show_test.exs test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/admin_diagnostics_live_test.exs`
     - Passed: `36 tests, 0 failures`.
   - `git diff --check` — passed.
   - Full `PATH="$PWD/bin:$PATH" dev check` — passed:
     - `801 tests, 0 failures`
     - `82 scenarios (82 passed), 493 steps (493 passed)`
   - `PATH="$PWD/bin:$PATH" dev down` — completed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Re-map the member delivery-status colours...`
   - to:
     - `- [x] 005 Re-map the member delivery-status colours...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No ADR was explicitly referenced by the plan.
   - Checked relevant accepted ADRs:
     - ADR 0006: member-facing delivery statuses stay simplified while staff keeps detailed delivery/status information. This task changed only member presentation colours/badge rendering and added a staff-path unchanged assertion.
     - ADR 0015: member application pages use LiveView. This task stayed on the existing member LiveView/template path and did not introduce new controller-rendered member app surfaces.