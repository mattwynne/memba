# Task 001 inspection: outbound email delivery handoff paths

Selected todo:

> 001 Inspect current outbound send paths and tests.

## Current synchronous browser/inbound send path

- `web/lib/memba/messaging.ex`
  - `Memba.Messaging.send_club_message/2` builds a `SendMessage` command, dispatches it, then synchronously calls `deliver_to_provider/1`.
  - `deliver_to_provider/1` looks up the club, iterates the resolved command recipients, builds an `EmailDeliveryRequest` for each recipient, calls `EmailDeliveryProvider.deliver/1`, and stops at the first provider error.
  - `email_delivery_request/3` uses the already-resolved recipient data plus `Membership.get_person/1`, `Membership.get_person_primary_email/1`, and `Membership.get_club/1` data to build provider requests.
  - This is the boundary the iteration needs to move behind the async dispatcher/manual retry path.
- Browser compose caller:
  - `web/lib/memba_web/live/member_message_live/new.ex` calls `Messaging.send_club_message(attrs, consistency: :strong)` from `send_current_member_message/2`.
  - It treats `:ok` and `{:ok, _}` as accepted and logs/returns `{:error, reason}` otherwise.
- Accepted inbound club-message caller:
  - `Memba.Messaging.receive_inbound_club_email/2` eventually reaches `accept_first_inbound_club_email/5`.
  - That calls `send_inbound_club_message/6`, which calls the same `send_club_message/2` path and converts a non-error result to `:ok`.
  - Only after the club message send succeeds does it record `InboundClubEmailAccepted`.

## Current delivery projections/read models

- `web/lib/memba/messaging/projectors/email_delivery.ex`
  - `EmailDeliveryCreated` inserts `Memba.Messaging.Projections.EmailDelivery` rows into `messaging_email_deliveries`.
  - New rows currently have `channel: "email"` and `status: "sent"`.
  - The schema currently stores only IDs, recipient name/address, channel, status, and timestamps.
- `web/lib/memba/messaging/projectors/member_email_delivery.ex`
  - `EmailDeliveryCreated` inserts member-facing rows with `status: "sent"`.
  - Provider/webhook events map to the ADR 0006 member vocabulary: `delivered` or `delivery problem`.
  - `EmailDeliveryOpened` is a no-op replay shim only.
- `web/lib/memba/messaging/projectors/memba_staff_email_delivery.ex`
  - `EmailDeliveryCreated` inserts staff/operator rows with detailed `status: "sent"` and `reason: nil`.
  - Provider/webhook events preserve detailed staff statuses/reasons: `delivered`, `delayed`, `bounced`, and `spam complaint`.
  - `EmailDeliveryOpened` is also a no-op replay shim only.
- Current migrations for the three delivery tables define free-text `status` columns and no status check constraints.
- `Memba.ReadModelChanges.publish/4` is already called from projector `after_update/3` callbacks, and PubSub is started before projectors in `Memba.Application`.

## Provider seams and tests

- Provider port:
  - `web/lib/memba/messaging/email_delivery_provider.ex` delegates `deliver/1` to `Application.get_env(:memba, :messaging_email_delivery_provider, Memba.Messaging.EmailDeliveryProviders.Fake)`.
- Providers:
  - `Fake` records `%EmailDeliveryRequest{}` values in an Agent for assertions.
  - `Local` sends through `Memba.Mailer`, records `LocalDeliveryFacts`, and is used by browser acceptance/dev support.
  - `Postmark` and `Resend` both build Swoosh emails through the shared member-message email rendering boundary and return `:ok | {:error, reason}`.
  - `ResendAdapter` is the custom Swoosh adapter for Resend API header shape.
  - `web/test/support/messaging/email_delivery_providers/unavailable.ex` returns `{:error, :unavailable}` for failure-path tests.
- Configuration:
  - `web/config/config.exs` defaults messaging provider to `Fake`.
  - `web/config/test.exs` uses `Local` for browser acceptance unless tests override it.
  - `web/config/runtime.exs` selects fake/local/Postmark/Resend from runtime config.
  - `DevTestSupportController` can switch the local test/dev messaging provider between `fake` and `local`.

## Tests that currently encode synchronous-provider behaviour

- `web/test/memba/messaging/send_club_message_test.exs`
  - Expects `send_club_message/2` to synchronously populate `Fake.deliveries/0`.
  - Expects provider handoff failure to make `send_club_message/2` return an error while projections already show `sent`.
  - These tests will need to change in later tasks to assert accepted command + pending delivery work, not inline provider delivery.
- `web/test/memba/messaging/inbound_club_message_acceptance_test.exs`
  - The accepted inbound flow test currently expects `Fake.deliveries/0` to be populated during `receive_inbound_club_email/2`.
  - Duplicate inbound handling asserts no new outbound deliveries by comparing `Fake.deliveries/0`.
- `web/test/memba/messaging/message_projection_test.exs`
  - Expects `EmailDeliveryCreated` to project `EmailDelivery` rows with `status: "sent"`.
- `web/test/memba/messaging/member_email_delivery_projection_test.exs`
  - Expects member-facing delivery rows to start as `status: "sent"`.
- `web/test/memba/messaging/memba_staff_email_delivery_projection_test.exs`
  - Expects staff delivery rows to start as `status: "sent"` and preserve webhook diagnostic statuses/reasons.
- Provider adapter tests under `web/test/memba/messaging/email_delivery_providers/` exercise request-to-provider rendering/adapter behaviour and should stay useful once the dispatcher builds the same request shape.
- Controller and acceptance plumbing tests under `web/test/memba_web/controllers/*inbound*_test.exs`, `web/test/features/step_definitions/messaging_steps.exs`, and `acceptance-tests/features/support/member_message.js` assume accepted inbound/browser sends cause local/fake provider facts during the send call.

## Implementation notes for subsequent tasks

- Moving provider delivery out of `Memba.Messaging` will require a focused collaborator or dispatcher to build the same `%EmailDeliveryRequest{}` from persisted delivery/message/member/club data instead of from the in-memory `SendMessage` command.
- The dispatcher can subscribe to `Memba.ReadModelChanges.topic()` and filter for `Memba.Messaging.Projectors.EmailDelivery` changes sourced from `EmailDeliveryCreated`.
- Claiming and status updates should use the `messaging_email_deliveries` row as the outbox/handoff record, as required by the plan.
- Member-facing projections should avoid raw infrastructure failure detail; staff/operator projections or the core `EmailDelivery` read model are the appropriate places for exact dispatch diagnostics.
- Rejection emails use `InboundClubRejectionEmail.deliver/5` directly through `Memba.Mailer`; this iteration plan targets accepted outbound club-message deliveries, not rejection-email delivery.

## ADR conformance notes

- ADR 0002/0009: keep message decisions/events in Commanded aggregates and read models in Ecto projections.
- ADR 0004/0005/0007: the message aggregate still owns message/delivery events, while Messaging resolves recipients through Membership public query APIs.
- ADR 0006: member-facing delivery status should remain simplified; detailed provider/dispatch diagnostics belong to staff/operator or operational read models.
- ADR 0016: both Postmark and Resend remain switchable provider adapters behind the provider port.
- ADR 0021/0022: read-model-change PubSub is the right committed-projection signal for async nudges; projection barriers remain separate read-your-writes synchronization.
