1. **Selected todo line**
   - `003 Route GET /messages/:message_id through the existing :browser and :club_member_required pipelines to the LiveView while preserving the same URL shape and club_id query parameter.`

2. **Changes made**
   - Updated `web/lib/memba_web/router.ex`
     - Replaced the controller route with:
       - `live "/messages/:message_id", MemberMessageLive.Show, :show`
     - Kept it inside the existing scope using:
       - `pipe_through [:browser, :club_member_required]`
     - Added a member `live_session` that mounts current identity data.
   - Updated `web/lib/memba_web/live/member_message_live/show.ex`
     - Added route-compatible mount handling for `message_id` path params and `club_id` query params.
     - Reused the existing member message template rendering path so the routed page keeps existing public behaviour while now being LiveView-backed.
     - Preserved existing not-found behaviour for message/club mismatches via `Phoenix.Router.NoRouteError`.
   - Updated `web/test/memba_web/router_test.exs`
     - Now asserts `/messages/:message_id` routes to `MembaWeb.MemberMessageLive.Show` through `[:browser, :club_member_required]`.
   - Updated `web/test/memba_web/live/member_message_live/show_test.exs`
     - Added a routed LiveView test proving the URL shape and `club_id` query parameter reach the LiveView.

3. **Validation commands run**
   - `cd /workspace/memba/web && mix format --check-formatted lib/memba_web/router.ex lib/memba_web/live/member_message_live/show.ex test/memba_web/router_test.exs test/memba_web/live/member_message_live/show_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `219 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Route GET /messages/:message_id ...`
   - To:
     - `- [x] 003 Route GET /messages/:message_id ...`

5. **Todo splits/additions/reordering**
   - None.
   - Task `004` remains unchecked; I only added the minimal LiveView compatibility needed for the route switch to preserve existing passing behaviour.

6. **ADR conformance**
   - ADR 0015: member message detail is now LiveView-backed.
   - ADR 0013: added/updated automated routing and LiveView tests for the user-facing route.
   - ADR 0006: member-facing receipt vocabulary remains unchanged and still uses existing presentation mapping.
   - No acceptance feature files were changed.