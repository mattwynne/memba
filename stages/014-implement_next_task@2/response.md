1. **Selected todo line**
   - `002 Read ADR 0015 (docs/adr/0015-use-liveview-for-member-application-pages.md) and apply it to the member dashboard.`

2. **Changes made**
   - Added ADR application notes:
     - `docs/iterations/014-member-dashboard-liveview-polish/task-002-adr-0015-application.md`
   - The note records how ADR 0015 applies to the dashboard:
     - signed-in selected-club home is a member app surface and should become `MembaWeb.MemberDashboardLive`;
     - `GET /?club_id=<club_id>` remains the user-visible URL;
     - controller/public rendering remains only for dispatch/logged-out marketing handling;
     - auth/not-found/public behaviours must be preserved;
     - later LiveView tests should prove the architecture boundary.
   - No application behavior was changed in this task.

3. **Focused validation commands run**
   - `git diff --check` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed.
     - ExUnit result: `243 tests, 0 failures`.
   - Final `git diff --check` after todo check-off — passed.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 002 Read ADR 0015 (...) and apply it to the member dashboard.`
   - To:
     - `- [x] 002 Read ADR 0015 (...) and apply it to the member dashboard.`

5. **Todo splits/additions/reordering**
   - No todo items were split, added, deleted, or reordered.

6. **ADR conformance evidence**
   - Read accepted ADR 0015.
   - Applied it in the task note by explicitly classifying the signed-in club home/member dashboard as a member application page that should be LiveView-backed.
   - Preserved ADR 0015’s exception for logged-out marketing/static pages by keeping public club handling outside the member-dashboard LiveView requirement.