Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `001 Inspect current authenticated club-site routes and the design references listed above.`

2. **Changes made**
   - Added `docs/iterations/011-member-facing-message-behaviour/inspection.md` documenting:
     - Current Phoenix route topology.
     - Current authenticated club-site behaviour at `GET /?club_id=...` and `POST /?club_id=...`.
     - Existing membership/messaging query seams.
     - Findings from the listed design references.
     - Gaps/constraints for later iteration tasks.
     - ADR conformance notes.
   - Updated `docs/iterations/011-member-facing-message-behaviour/todo.md` to check off only task `001`.

3. **Focused validation run**
   - `cd web && mix phx.routes MembaWeb.Router`
     - Confirmed current routes, including no member-facing `GET /messages/:message_id` route yet.
   - `git diff --check && git diff --cached --check`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `203 tests, 0 failures`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 001 Inspect current authenticated club-site routes and the design references listed above.`
   - To:
     - `- [x] 001 Inspect current authenticated club-site routes and the design references listed above.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read relevant accepted ADRs: 0001, 0003, 0004, 0005, 0006, and 0013.
   - Captured conformance implications in the new inspection notes, especially:
     - Phoenix remains the implementation surface.
     - Shared Cucumber scenarios should stay user-facing.
     - Existing message aggregate/projection model should be reused.
     - ADR 0006 simplified member receipt statuses must be preserved while operator diagnostics remain separate.