Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `012 Restyle /admin/deliveries consistently without changing delivery semantics.`

2. **Changes made**
   - Updated `web/lib/memba_web/live/admin/deliveries_live/index.ex`
     - Restyled `/admin/deliveries` to match the staff operations visual direction used by Clubs/People/Messages.
     - Added:
       - `data-admin-page="deliveries"` on the page root.
       - `#deliveries-summary-cards` summary section.
       - `#deliveries-summary-total`.
       - `#deliveries-diagnostics-note`.
       - `#deliveries-table-card`.
     - Preserved existing diagnostics semantics:
       - same query: `Messaging.list_operator_deliveries()`;
       - same stream;
       - same table columns;
       - same delivery row IDs/data attributes used by tests and acceptance support;
       - same raw staff statuses and provider reason text.
     - Updated status chip styling only; did not change status values.
   - Updated `web/test/memba_web/live/deliveries_live_test.exs`
     - Added assertions for the new stable page structure/selectors.
     - Existing assertions for raw detailed statuses, provider reasons, row count, and opened→delivered behaviour remain intact.
   - Updated `docs/iterations/021-staff-area-redesign/todo.md`
     - Checked off only task `012`.

3. **Focused validation commands/results**
   - Formatting check:
     - `cd /repos/mattwynne/memba && PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/live/admin/deliveries_live/index.ex test/memba_web/live/deliveries_live_test.exs`
     - Passed.
   - Focused delivery tests:
     - Initial `bin/mix test ...` hit a sandbox Postgres readiness/env mismatch before tests ran.
     - Re-ran inside devenv shell:
       - `cd /repos/mattwynne/memba && PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd web && mix test test/memba_web/live/deliveries_live_test.exs'`
       - Passed: `2 tests, 0 failures`.
   - Full required check for browser-facing LiveView change:
     - `cd /repos/mattwynne/memba && PATH="$PWD/bin:$PATH" dev check`
     - Passed:
       - ExUnit: `524 tests, 0 failures`
       - Acceptance: `34 scenarios (34 passed), 215 steps (215 passed)`
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 012 Restyle /admin/deliveries consistently without changing delivery semantics.`
   - To:
     - `- [x] 012 Restyle /admin/deliveries consistently without changing delivery semantics.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: Work remains in Phoenix/LiveView.
   - ADR 0004: Delivery diagnostics remain tied to existing message/delivery projections; no aggregate or delivery-state changes.
   - ADR 0006: Staff-facing detailed statuses/provider reasons remain visible; no simplification to member-facing vocabulary on the staff page.
   - ADR 0007: No Membership/Messaging boundary changes.
   - ADR 0009: No projection/query plumbing changes.
   - ADR 0013: Browser-facing behaviour remains covered with Phoenix/PhoenixTest-style tests.