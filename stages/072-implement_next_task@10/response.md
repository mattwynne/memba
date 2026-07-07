Implemented the next unchecked task: **010**.

1. **Selected todo line**
   - `010 Update MemberMessageDetailLive tests: follow toggle reflects and changes following state via the existing events; the composer renders after the replies; original + replies show a timestamp.`

2. **Changes made**
   - Updated `web/test/memba_web/live/member_message_live/show_test.exs`
     - Added focused LiveView coverage that:
       - Verifies the compact follow toggle initially reflects `Not following`.
       - Triggers the existing `follow_conversation` event via `render_change/1`.
       - Verifies projected follow state changes to following and the toggle updates to checked / `unfollow_conversation`.
       - Triggers the existing `unfollow_conversation` event and verifies the state/toggle return to not-following.
       - Confirms legacy Follow / Stop-following buttons are absent.
     - Changed this test module to `async: false` because the follow/unfollow event path uses Commanded projectors that need shared SQL sandbox ownership.
   - Existing tests in the same file already cover:
     - Composer rendering after replies.
     - Original and reply timestamps.
   - Updated `docs/iterations/046-conversation-page-alignment/todo.md`
     - Checked off only task `010`.

3. **Validation**
   - Baseline focused test before patch:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs`
     - Passed: `12 tests, 0 failures`
   - First after-change focused run failed due SQL sandbox ownership from the new Commanded follow-event interaction; fixed by making the module non-async.
   - Final focused validation:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_message_live/show_test.exs`
     - Passed: `13 tests, 0 failures`
   - Formatting:
     - `cd web && mix format --check-formatted test/memba_web/live/member_message_live/show_test.exs`
     - Passed
   - Additional broad check attempted:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Failed in unrelated existing tests expecting `/` but receiving `/conversations`:
       - `MembaWeb.ClubSiteShellSurfacesTest`
       - `MembaWeb.MemberInvitationLive.SendTest`
       - `MembaWeb.Admin.ClubMemberInvitationsLive.NewTest`
     - I did not fix these because they are outside selected task `010`; final `dev check` remains task `012`.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 010 Update MemberMessageDetailLive tests...`
   - To:
     - `- [x] 010 Update MemberMessageDetailLive tests...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no ADRs, and no `docs/adr/*.md` files are present.
   - The change is test-only and scoped to the selected conversation-page verification task.
   - No acceptance feature files were changed.