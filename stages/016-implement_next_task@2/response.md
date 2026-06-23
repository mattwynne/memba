Implemented the next unchecked task.

1. **Selected todo line**
   - `- [ ] 002 Update MemberDashboardPresentation to build its message rows from`

2. **Changes made**
   - Updated `MembaWeb.MemberDashboardPresentation` to load conversations via `Messaging.list_conversations_for_club/1` instead of raw messages.
   - Changed dashboard message row presentation to use conversation/root-message data:
     - subject
     - originator id/name/initials
     - original send date/label
     - reply count
     - latest replier id/name
     - reply activity label (`"No replies yet"` or `"N replies · latest from …"`)
   - Removed home-row receipt/delivery-glance query and presentation fields from `MemberDashboardPresentation`.
   - Updated `MemberDashboardPresentationTest` to cover:
     - grouping replies under one conversation row
     - reply count
     - latest replier
     - ordering by original/root send time
     - no-replies label
     - absence of receipt-glance fields

3. **Focused validation**
   - Added tests first; initial run failed against the old implementation as expected.
   - `devenv shell -- bin/mix format --check-formatted lib/memba_web/member_dashboard_presentation.ex test/memba_web/member_dashboard_presentation_test.exs`
     - Passed.
   - `devenv shell -- bin/mix test test/memba_web/member_dashboard_presentation_test.exs`
     - Passed: `3 tests, 0 failures`.
   - I used `devenv shell -- ...` because the preferred direct `PATH="$PWD/bin:$PATH" bin/mix ...` path hit a local Postgres readiness/socket issue in this sandbox.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Update MemberDashboardPresentation to build its message rows from`
   - To:
     - `- [x] 002 Update MemberDashboardPresentation to build its message rows from`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001 / Phoenix: kept the change inside the existing Phoenix application presentation layer.
   - ADR 0002 / CQRS: continued reading from projected read models through query APIs; no command/write-side behavior changed.
   - ADR 0007: `MemberDashboardPresentation` depends on public `Messaging` and `Membership` APIs rather than crossing into Messaging projection storage directly.
   - ADR 0009: uses the conversation read model query added over Commanded Ecto projections; no projection mechanics changed.
   - ADR 0015: preserved the existing LiveView dashboard boundary; this task only reshapes the presentation data consumed by that surface.