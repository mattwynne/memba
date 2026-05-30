Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `005 Build MembaWeb.ClubsLive.Index, MembaWeb.ClubsLive.Show, and MembaWeb.MessagesLive.Show with simple forms/actions for club creation, person creation, membership, club message sending, and receipt viewing.`

2. **Changes made**
   - Built real LiveView browser surfaces:
     - `MembaWeb.ClubsLive.Index`
       - Lists clubs.
       - Creates clubs via `Memba.Membership.create_club/2`.
       - Links to club show pages.
     - `MembaWeb.ClubsLive.Show`
       - Shows a club.
       - Creates people via `Memba.Membership.create_person/2`.
       - Adds active members via `Memba.Membership.add_member/2`.
       - Sends club messages via `Memba.Messaging.send_club_message/2`.
       - Lists people, members, and sent messages.
     - `MembaWeb.MessagesLive.Show`
       - Shows message subject/body.
       - Shows addressed recipients.
       - Shows recipient delivery records.
       - Shows member-facing receipt statuses.
   - Added narrowly scoped public query APIs needed by the LiveViews:
     - `Memba.Membership.list_clubs/0`
     - `Memba.Membership.list_people/0`
     - `Memba.Messaging.list_messages_for_club/1`
   - Updated no-CRUD guard tests to allow those query APIs while still rejecting CRUD-style helpers.
   - Used LiveView streams for rendered collections with explicit DOM IDs.

3. **Focused validation run**
   - `cd web && mix format --check-formatted ...`
     - Passed.
   - `cd web && MIX_ENV=test mix compile --warnings-as-errors`
     - Passed.
   - Focused tests:
     - `MIX_ENV=test mix test test/memba_web/live/browser_acceptance_harness_test.exs test/memba/membership/no_crud_spike_test.exs test/memba/messaging/no_crud_spike_test.exs`
     - Passed: `10 tests, 0 failures`.
   - Required project gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `104 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Build ...`
   - To:
     - `- [x] 005 Build ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0013 respected: PhoenixTest LiveView coverage now passes against real LiveView routes.
   - ADR 0010 respected: no shared `.feature` files were edited.
   - ADR 0007 respected: Membership and Messaging remain separate bounded contexts; LiveViews call public context APIs rather than crossing into private projection storage directly.
   - ADR 0011 respected: LiveViews generate caller-supplied UUIDs for clubs, people, memberships, and messages before dispatch.