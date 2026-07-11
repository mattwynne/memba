Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `010 Add/update Phoenix/LiveView/rendered tests for: no \`Prefer email?\` card on desktop club home;`

2. **Changes made**
   - Updated `web/test/memba_web/live/member_dashboard_live_test.exs`
   - Strengthened the existing club-home “inbound email card” test so it now verifies absence of the removed `Prefer email?` card/copy in both:
     - mounted LiveView `/conversations`
     - rendered GET `/conversations`
   - Added rendered assertions for absence of:
     - `#member-dashboard-inbound-email`
     - `#member-dashboard-inbound-email-link`
     - `data-inbound-address='kmc@clubs.memba.io'`
     - `mailto:kmc@clubs.memba.io`
     - visible text `Prefer email?`
     - visible text `You can also send a club-wide message to`

3. **Focused validation run**
   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`
     - Passed: `30 tests, 0 failures`
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed on final diff: `960 tests, 0 failures`
   - `git diff --check`
     - Passed

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 010 Add/update Phoenix/LiveView/rendered tests for: no \`Prefer email?\` card on desktop club home;`
   - To:
     - `- [x] 010 Add/update Phoenix/LiveView/rendered tests for: no \`Prefer email?\` card on desktop club home;`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No ADRs were explicitly referenced by this plan/task.
   - Scope stayed limited to Phoenix/LiveView/rendered test coverage for an already-implemented presentation-only removal.
   - No routing, permissions, data model, migrations, acceptance feature files, or UI implementation were changed.