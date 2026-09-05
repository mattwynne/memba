Implemented task 005: unsupported routes and unknown club/group slugs continue through the existing inbound rejection flow.

1. Selected todo

   `005 Keep unsupported routes and unknown club/group slugs on the existing rejection path.`

2. Changes

   - Updated [inbound_club_destination.ex](/workspace/memba/web/lib/memba/messaging/inbound_club_destination.ex:145) to distinguish unknown groups internally from unrelated unsupported copied addresses.
   - Unknown groups retain the public `:unsupported_recipient_address` outcome; no new rejection reason, event shape, or projection value was introduced.
   - When an email includes an unrelated copied recipient followed by an unknown group route, the group address is now recorded as the rejected `to_address`.
   - Unknown clubs retain `:unknown_club_slug` and their existing precedence.
   - Clarified the public API documentation in [messaging.ex](/workspace/memba/web/lib/memba/messaging.ex:236).
   - Expanded focused coverage in [inbound_club_destination_test.exs](/workspace/memba/web/test/memba/messaging/inbound_club_destination_test.exs:127) for:
     - unknown group slugs in clubs with valid Everyone and Admin groups;
     - unrelated copied recipients;
     - `admin@unknown...` unknown-club routing.
   - Expanded the provider-neutral rejection-path coverage in [inbound_club_message_acceptance_test.exs](/workspace/memba/web/test/memba/messaging/inbound_club_message_acceptance_test.exs:1477), confirming rejection events/projections/emails and no message creation.

3. Validation

   - TDD red run: 34 tests, 2 expected failures demonstrating the copied-address masking bug.
   - Focused green run:
     - `dev test test/memba/messaging/inbound_club_destination_test.exs test/memba/messaging/inbound_club_message_acceptance_test.exs`
     - 34 tests, 0 failures.
   - `git diff --check`: passed.
   - `dev check --quick` ran 1,103 tests. Task-related tests and static/formatting phases passed, but the check is not fully clean: the previously documented `DevTestSupportControllerTest` database consistency timeout remains.
   - The unrelated failure reproduces in isolation: 6 tests, 1 failure in `DevTestSupportControllerTest`.

4. Todo check-off

   Checked only [task 005](/workspace/memba/docs/iterations/057-admin-group-email-conversations/todo.md:7):

   `- [x] 005 Keep unsupported routes and unknown club/group slugs on the existing rejection path.`

5. Todo structure

   No tasks were split, added, removed, or reordered.

6. ADR conformance

   - ADR 0007: destination resolution still uses Membership’s public club/group lookup APIs; Messaging does not query Membership projection storage directly.
   - ADRs 0002 and 0009: rejected inbound emails continue through the existing event-sourced command, event, and projection flow.
   - ADR 0016: routing and rejection behavior remain provider-neutral.
   - ADR 0003: no shared acceptance feature files or stakeholder scenarios were changed.
   - Tasks 006 onward remain untouched: no posting-policy, sender-authorisation, delivery, access-grant, or reply behavior changed.