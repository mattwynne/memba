Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 005 Sweep the codebase for any remaining CRUD spike artefacts and remove`

2. **Changes made**
   - Added `web/test/memba/messaging/no_crud_spike_test.exs`.
   - The new regression sweep verifies:
     - `Memba.Messaging` exposes command/query APIs, not CRUD mutation helpers.
     - The `Message` write model remains a Commanded aggregate, not an Ecto schema/changeset.
     - Messaging migrations use prefixed projection tables, not bare CRUD tables like `messages` or `deliveries`.
     - Legacy generated Messaging CRUD web/controller/live/fixture files are absent.
   - No conflicting CRUD source artefacts were found that needed deletion.

3. **Validation run**
   - `cd web && mix format --check-formatted test/memba/messaging/no_crud_spike_test.exs` — passed.
   - Focused test with managed Postgres:
     - `mix test test/memba/messaging/no_crud_spike_test.exs`
     - Result: `4 tests, 0 failures`.
   - Required project gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `93 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Sweep the codebase for any remaining CRUD spike artefacts and remove`
   - To:
     - `- [x] 005 Sweep the codebase for any remaining CRUD spike artefacts and remove`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0004: the test enforces `Message` remains the aggregate owning delivery state, not an Ecto CRUD schema.
   - ADR 0006: member-facing receipt projection tables remain read-side projection storage only.
   - ADR 0012: no opened analytics/count/timestamp model was introduced.
   - ADR 0002/0009 alignment: command/event write side and Ecto projection read side remain separated; no CRUD mutation path was added.