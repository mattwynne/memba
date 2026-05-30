Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `004 Add thin public context APIs following the existing pattern rather than dispatching Commanded commands from the web layer directly:`

2. **Changes made**
   - Added public Membership context command APIs in `web/lib/memba/membership.ex`:
     - `Memba.Membership.create_club/1,2`
     - `Memba.Membership.create_person/1,2`
     - `Memba.Membership.add_member/1,2`
   - These build existing command structs and dispatch through `Memba.Membership.App`.
   - `add_member/1,2` prevents a duplicate active `{club_id, person_id}` membership via the public Membership query boundary before dispatch.
   - Added public Messaging status-report APIs in `web/lib/memba/messaging.ex`:
     - `report_delivery_delivered/1,2`
     - `report_delivery_delayed/1,2`
     - `report_delivery_bounced/1,2`
     - `report_delivery_spam_complaint/1,2`
     - `report_delivery_opened/1,2`
   - These build existing delivery-report command structs and dispatch through `Memba.Messaging.App`.
   - Public APIs accept atom-keyed or string-keyed attrs for upcoming LiveView/controller use.
   - Added tests:
     - `web/test/memba/membership/public_api_test.exs`
     - `web/test/memba/messaging/status_report_api_test.exs`
   - Updated the Membership no-CRUD guard test to allow the now-plan-approved command-style context APIs while still rejecting CRUD-style Repo helpers.

3. **Focused validation**
   - `cd web && MIX_ENV=test mix compile --warnings-as-errors`
     - Passed.
   - `cd web && mix format lib/memba/membership.ex lib/memba/messaging.ex test/memba/membership/public_api_test.exs test/memba/messaging/status_report_api_test.exs --check-formatted`
     - Passed.
   - Focused public API tests with dev-managed Postgres:
     - `mix test test/memba/membership/public_api_test.exs test/memba/messaging/status_report_api_test.exs`
     - Passed: `5 tests, 0 failures`.
   - Related Membership/Messaging tests:
     - `mix test test/memba/membership test/memba/messaging`
     - Passed: `80 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - Required project gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Failed only on the existing pending browser harness TDD failures for task 005:
       - missing `#clubs-index`
       - missing `#message-show`

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Add thin public context APIs following the existing pattern rather than dispatching Commanded commands from the web layer directly:`
   - To:
     - `- [x] 004 Add thin public context APIs following the existing pattern rather than dispatching Commanded commands from the web layer directly:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0010 respected: no `.feature` files were edited.
   - ADR 0013 respected: no web feature-test approach was weakened; existing PhoenixTest browser failures remain for the later LiveView task.
   - ADR 0007 respected: Membership and Messaging remain separate contexts; Messaging status APIs dispatch only Messaging commands.
   - ADR 0011 respected: public APIs require caller-supplied UUID identities and `add_member/1,2` enforces duplicate active membership prevention at the application-service/query boundary.