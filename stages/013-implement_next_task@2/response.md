1. **Selected todo line**
   - `002 Introduce MembaWeb.MemberMessageLive.New, routed at GET /messages/new through the existing browser/member auth pipeline. Use the route helper/path ~p"/messages/new?club_id=#{club.id}" in templates/tests rather than inventing a bespoke named helper.`

2. **Changes made**
   - Added `MembaWeb.MemberMessageLive.New` at:
     - `web/lib/memba_web/live/member_message_live/new.ex`
   - Routed `GET /messages/new` through the existing `[:browser, :club_member_required]` member LiveView session in:
     - `web/lib/memba_web/router.ex`
   - Added route coverage proving `/messages/new` maps to `MembaWeb.MemberMessageLive.New` through the required club-member pipeline:
     - `web/test/memba_web/router_test.exs`
   - Added LiveView coverage proving the new compose shell renders in `<Layouts.club_site>` and that the routed path uses:
     - `~p"/messages/new?club_id=#{alice.club_id}"`
     - `web/test/memba_web/live/member_message_live/new_test.exs`

3. **Validation**
   - Final successful command:
     - `PATH="$PWD/bin:$PATH" dev check`
   - Result:
     - Passed
     - `233 tests, 0 failures`

4. **Todo check-off**
   - Changed:
     - `- [ ] 002 Introduce ...`
   - To:
     - `- [x] 002 Introduce ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Read relevant accepted ADRs:
     - ADR 0001: Phoenix is the core application framework.
     - ADR 0013: PhoenixTest/LiveView-style coverage for web behaviour.
     - ADR 0015: member application pages should use LiveView by default.
   - The new compose entry point is a LiveView member application surface, routed through the existing member auth pipeline, consistent with those ADRs.