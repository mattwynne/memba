1. **Selected todo line**
   - `- [ ] 003 Update all internal verified routes and links:`

2. **Changes made for this task**
   - Audited current Phoenix verified route/link usage in `web/lib/memba_web`.
   - Confirmed the relevant internal links already use admin paths:
     - Club list/detail: `/admin/clubs`, `/admin/clubs/:club_id`
     - Message diagnostics: `/admin/messages/:message_id`
     - Delivery overview route is under `/admin/deliveries`
   - No code/config/test changes were necessary because prior completed routing work had already updated these route/link references.
   - Updated only the task check-off in `docs/iterations/009-routing-and-liveview-surface-split/todo.md`.

3. **Focused validation commands run**
   - Static stale-link audit:
     - Checked for stale `~p"/clubs"`, `~p"/messages"`, and `~p"/deliveries"` route/link references under `web/lib/memba_web`.
     - Result: no stale public harness verified route/link references found.
   - Full validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: passed — `132 tests, 0 failures`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 003 Update all internal verified routes and links:`
   - To:
     - `- [x] 003 Update all internal verified routes and links:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001 respected: kept the Phoenix/Phoenix LiveView routing/link structure.
   - ADR 0013 respected: existing PhoenixTest-style web coverage remains intact; no feature files were changed.
   - No temporary club resolver or member-facing production routes were introduced.