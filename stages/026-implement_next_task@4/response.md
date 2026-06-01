Implemented the next unchecked task.

1. **Selected todo line**
   - `004 Build/refine member club home at GET /?club_id=<club_id>:`

2. **Changes made**
   - Refined member club home at `GET /?club_id=<club_id>`:
     - Recent messages now render as member-facing rows with links to `/messages/:message_id?club_id=<club_id>`.
     - Active members now show a summary card/count plus stable member rows.
     - Inline compose area now follows the wireframe direction more closely:
       - recipient summary showing all active members;
       - “From” sender field defaulted to the signed-in member when possible;
       - subject/body placeholders;
       - submit button remains accessible as “Send club message” for existing browser step support.
   - Updated controller assigns for:
     - active member count;
     - current member;
     - member initials;
     - member names by id;
     - newest-first message display.
   - Extended `PageControllerTest` to prove:
     - active member summary/list rendering;
     - compose form/action and default sender;
     - recent message detail links using the member route shape.

3. **Focused validation**
   - `cd web && mix format --check-formatted`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `203 tests, 0 failures`.
   - `cd acceptance-tests && node --test test/member_message_steps.test.js test/member_harness.test.js`
     - Passed: `22 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Build/refine member club home at GET /?club_id=<club_id>:`
   - To:
     - `- [x] 004 Build/refine member club home at GET /?club_id=<club_id>:`    

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: kept the work within Phoenix controller/HEEx conventions.
   - ADR 0003 / ADR 0010: did not edit locked shared `.feature` files.
   - ADR 0013: added/updated Phoenix web tests for user-facing page behaviour.
   - ADR 0006: did not change internal delivery status/projection values; this task only refined the club home surface.