1. **Selected todo line**
   - `007 Add LiveView state for collapsed groups:`

2. **Changes made**
   - Added LiveView state in `MembaWeb.MemberMessageLive.Show`:
     - initializes `:expanded_receipt_groups` as an empty `MapSet`;
     - handles `toggle_receipt_group` events server-side;
     - toggles the clicked status key without custom JavaScript.
   - Updated the member message receipt template:
     - receipt group headers are now accessible buttons;
     - each button has stable IDs, `phx-click`, `phx-value-status`, `aria-expanded`, and `aria-controls`;
     - visible groups are collapsed by default;
     - recipient rows are rendered only when their group is expanded;
     - chevron icon reflects expanded/collapsed state.
   - Added/updated tests:
     - new LiveView test proves groups are collapsed by default, expand on click, and collapse again;
     - existing ConnCase/static-render tests now expect collapsed default state and no recipient rows in the initial DOM.

3. **Validation run**
   - `cd web && mix format --check-formatted ...`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed.
     - Final result: `227 tests, 0 failures`.
   - Also attempted direct focused `mix test test/memba_web/live/member_message_live/show_test.exs`; it could not connect to unmanaged Postgres at `/tmp/devenv/postgres/.s.PGSQL.5432`, so final validation used `dev check`, which starts required services and passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 007 Add LiveView state for collapsed groups:`
   - To:
     - `- [x] 007 Add LiveView state for collapsed groups:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR / architecture conformance**
   - No `docs/adr/` files were present to read for this repo.
   - Implementation follows the plan and project guidance:
     - Phoenix LiveView server-side event handling;
     - HEEx/Tailwind only;
     - no custom JavaScript;
     - existing route/layout surface preserved;
     - operator-only fields remain unexposed;
     - acceptance feature files were not changed.