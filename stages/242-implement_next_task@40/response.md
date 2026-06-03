Implemented task 011 and checked it off in `docs/iterations/019-inbound-club-messages-by-email/todo.md`.

Changes made:
- Added `AcceptInboundClubEmail` command for recording accepted inbound club emails on the inbound email aggregate.
- Routed the new command through `Memba.Messaging.Router`.
- Extended `InboundEmailReceipt` to emit/apply `InboundClubEmailAccepted`.
- Updated `Messaging.receive_inbound_club_email/2` to reuse the existing `send_club_message/2` flow so accepted inbound email creates the normal message, recipient delivery records, projections, and outbound provider deliveries.
- Added focused acceptance-style messaging test coverage for the inbound accepted path.
- Updated the Messaging app command registry test for the new command.

Validation:
- Focused messaging tests passed:
  - `mix test test/memba/messaging/app_test.exs test/memba/messaging/inbound_club_message_acceptance_test.exs test/memba/messaging/inbound_email_dispatch_test.exs test/memba/messaging/inbound_email_receipt_test.exs test/memba/messaging/inbound_email_source_projection_test.exs test/memba/messaging/send_club_message_test.exs`
  - `18 tests, 0 failures`
- Formatting passed:
  - `mix format --check-formatted`
- Full validation passed:
  - `PATH="$PWD/bin:$PATH" dev check`
  - `432 tests, 0 failures`
  - `31 scenarios passed`

Note: I did not commit changes.