Implemented the next unchecked task.

1. **Selected todo line**
   - `- [ ] 001 Inspect the post-iteration-009 route structure and admin pipeline.`

2. **Changes made**
   - Added `docs/iterations/010-shared-magic-link-auth/route-inspection.md` documenting:
     - current public, admin, webhook, and dev route structure,
     - current `:staff_browser` pipeline plugs,
     - absence of existing auth/staff gates,
     - admin LiveView namespace/layout seams,
     - constraints for later auth work, especially preserving `POST /webhooks/postmark`.
   - Updated only the selected todo line in `todo.md`.

3. **Validation commands/results**
   - `cd web && mix phx.routes` — passed; confirmed current route table.
   - `cd web && mix test test/memba_web/router_test.exs` — attempted, but direct test run failed because Postgres was not running at `/tmp/devenv/postgres/.s.PGSQL.5432`.
   - `bin/dev check` — passed: `137 tests, 0 failures`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 001 Inspect the post-iteration-009 route structure and admin pipeline.`
   - To:
     - `- [x] 001 Inspect the post-iteration-009 route structure and admin pipeline.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Reviewed relevant accepted ADRs:
     - ADR 0001: Phoenix remains the core web stack.
     - ADR 0013: Existing web-test approach remains unchanged.
     - ADR 0007: No changes were made that couple auth inspection to Membership/Messaging internals.
   - This task was documentation/inspection only; no behavior or architecture changes were introduced.