Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `001 Inspect current Membership person command/event/aggregate/projector/projection code, Accounts lookup code, Messaging recipient resolution, seeds, fixtures, staff/admin LiveViews, and acceptance support that assume a single email field.`

2. **Changes made**
   - Added durable inspection notes:
     - `docs/iterations/016-person-email-addresses/task-001-inspection.md`
   - The notes inventory current single-email assumptions across:
     - Membership command/event/aggregate/router/projector/projection/query API
     - Accounts sign-in/token lookup flow
     - Messaging recipient resolution
     - Staff/admin LiveView person creation/display
     - migrations, seeds, fixtures, test helpers
     - Elixir and browser Cucumber support
   - Updated:
     - `docs/iterations/016-person-email-addresses/todo.md`

3. **Focused validation**
   - Ran:
     - `git diff -- docs/iterations/016-person-email-addresses/todo.md docs/iterations/016-person-email-addresses/task-001-inspection.md`
     - `git status --short`
     - `git diff --check -- docs/iterations/016-person-email-addresses/todo.md docs/iterations/016-person-email-addresses/task-001-inspection.md`
   - Result:
     - Diff/status confirmed only the intended todo update and new inspection note.
     - `git diff --check` passed with no whitespace errors.
   - I did **not** run `dev check` because this was a docs/todo-only inspection task, and repo guidance says not to run it for docs-only changes unless explicitly requested.

4. **Todo check-off made**
   - Changed exactly this line:
     - `- [ ] 001 ...`
   - To:
     - `- [x] 001 ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Reviewed and reflected relevant constraints from:
     - ADR 0002: keep Membership behaviour command/event/aggregate based.
     - ADR 0007: Messaging must depend on Membership public query APIs, not projection storage.
     - ADR 0009: continue using Commanded Ecto projections.
     - ADR 0010: shared Cucumber feature/step-definition layout.
     - ADR 0011: person identity remains caller-generated `person_id`, not email.
     - ADR 0013: use PhoenixTest/feature-style web testing where suitable.
     - ADR 0015: LiveView conventions for app surfaces.