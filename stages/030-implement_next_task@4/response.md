Implemented task 004: inbound email destinations now resolve `<group-slug>@<club-slug>.clubs.memba.io` to both the destination club and its club-scoped group.

1. Selected todo

   `004 Generalise inbound destination resolution from the hard-coded everyone local part to a group-slug lookup on the existing <club-slug>.clubs.memba.io host.`

2. Changes

   - Updated [inbound_club_destination.ex](/workspace/memba/web/lib/memba/messaging/inbound_club_destination.ex:1) to:
     - normalize the email local part as a group email slug;
     - resolve the club through `Membership.get_club_by_slug/1`;
     - resolve the group through `Membership.get_group_by_email_slug/2`;
     - return `group_id`, `group_email_slug`, and `group_name` alongside the existing club details;
     - preserve configured-domain, copied-recipient, and normalized-address behavior.
   - Updated the public API documentation in [messaging.ex](/workspace/memba/web/lib/memba/messaging.ex:236).
   - Added focused Everyone/Admin and club-scoping coverage in [inbound_club_destination_test.exs](/workspace/memba/web/test/memba/messaging/inbound_club_destination_test.exs:8).
   - Updated the authorization test destination fixture for the expanded resolved-destination contract.

3. Validation

   - TDD red run: expected compilation failure because `InboundClubDestination` did not yet expose group fields.
   - `dev test test/memba/messaging/inbound_club_destination_test.exs test/memba/messaging/inbound_club_authorization_test.exs`
     - 14 tests, 0 failures.
   - `dev test test/memba/messaging/inbound_club_message_acceptance_test.exs test/memba/messaging/inbound_email_api_test.exs test/memba/messaging/no_crud_spike_test.exs`
     - 31 tests, 0 failures.
   - `git diff --check`
     - Passed.
   - `dev check --quick`
     - Ran 1,103 tests; one unrelated failure remains in `DevTestSupportControllerTest` due to the previously documented database sandbox/consistency timeout.
     - The failure reproduces independently. All task-related tests and formatting/static phases passed.

4. Todo check-off

   Checked only [task 004](/workspace/memba/docs/iterations/057-admin-group-email-conversations/todo.md:6):

   `- [x] 004 Generalise inbound destination resolution from the hard-coded everyone local part to a group-slug lookup on the existing <club-slug>.clubs.memba.io host.`

5. Todo changes

   No tasks were split, added, removed, or reordered.

6. ADR conformance

   - ADR 0007: Messaging uses Membership’s public club and group lookup APIs and contains no direct Membership projection/schema queries.
   - ADRs 0002 and 0005: this remains application-service resolution; no aggregate responsibilities, recipient resolution, commands, or events were changed.
   - ADR 0011: existing deterministic group identities are returned from Membership rather than regenerated in Messaging.
   - Existing rejection outcomes remain in place; the more comprehensive rejection-path coverage remains task 005.