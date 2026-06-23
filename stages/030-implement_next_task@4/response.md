Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 004 Keep the row link target unchanged (the conversation/message-detail route).`

2. **Changes made**
   - Updated `web/test/memba_web/live/member_dashboard_live_test.exs` with focused coverage for a grouped conversation row:
     - Asserts the row link remains `/messages/#{root_message.message_id}`.
     - Refutes linking to the reply message id (`/messages/#{reply.message_id}`).
   - No production code changes were needed; the template already preserved:
     - `href={member_message_path(message_row.message_id, @selected_club, club_id_source)}`

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba_web/live/member_dashboard_live_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/member_dashboard_live_test.exs`
     - Hit the known sandbox Postgres readiness/socket mismatch.
   - `devenv shell -- bin/mix test test/memba_web/live/member_dashboard_live_test.exs`
     - Passed: `18 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed.
     - Acceptance summary: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Keep the row link target unchanged (the conversation/message-detail route).`
   - To:
     - `- [x] 004 Keep the row link target unchanged (the conversation/message-detail route).`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR/project conformance evidence**
   - The plan explicitly referenced no ADR files; no `docs/adr/*.md` or nested ADR Markdown files were present to read.
   - Preserved the existing Phoenix route/helper path for the member conversation/message-detail route.
   - Added focused LiveView test coverage using stable selectors, consistent with local LiveView testing guidance.
   - Did not touch acceptance feature files or introduce new dependencies/HTTP clients.