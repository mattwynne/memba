Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 008 Update Memba staff delivery views/tests to remove opened status expectations while preserving delivered/problem visibility.`

2. **Changes made**
   - `web/lib/memba_web/live/admin/deliveries_live/index.ex`
     - Removed the `status_class("opened")` styling branch so the staff deliveries view no longer treats `opened` as a current display status.
   - `web/test/memba_web/live/deliveries_live_test.exs`
     - Added coverage proving a historic `opened` staff delivery projection row is rendered as `delivered`.
     - The test also proves the staff deliveries overview does not expose `data-delivery-status='opened'`, opened text, or legacy opened reason text.
     - Existing delivered/problem visibility coverage remains in place.
   - `docs/iterations/017-remove-open-tracking/todo.md`
     - Checked off task 008 only.

3. **Focused validation**
   - `cd web && mix format --check-formatted lib/memba_web/live/admin/deliveries_live/index.ex test/memba_web/live/deliveries_live_test.exs`
     - Passed.
   - `devenv shell -O services.postgres.port:int 15432 -- bash -lc '... mix test test/memba_web/live/deliveries_live_test.exs'`
     - Passed: `2 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `380 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - Note: a direct focused `mix test` attempt outside the devenv Postgres environment failed with connection refused; rerunning inside devenv passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 008 Update Memba staff delivery views/tests to remove opened status expectations while preserving delivered/problem visibility.`
   - To:
     - `- [x] 008 Update Memba staff delivery views/tests to remove opened status expectations while preserving delivered/problem visibility.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Reviewed relevant accepted ADRs:
     - ADR 0001: keeps implementation in Phoenix/LiveView.
     - ADR 0013: preserves feature-style PhoenixTest coverage for user-visible staff behaviour.
     - ADR 0004/0009: leaves aggregate/projection boundaries intact.
     - ADR 0006/0012 include older opened assumptions, but the approved iteration plan supersedes those product assumptions; this change removes opened from current staff-facing display while preserving historic compatibility through existing normalization.