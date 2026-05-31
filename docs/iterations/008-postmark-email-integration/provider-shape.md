# Postmark provider shape decision

Selected todo: `002 Decide the smallest provider shape: likely Memba.Messaging.DeliveryProviders.Postmark implementing Memba.Messaging.DeliveryProvider and using Memba.Mailer/Swoosh.`

Status: decided

## Decision

Add a single concrete provider module:

- `Memba.Messaging.DeliveryProviders.Postmark`
- Implements the existing `Memba.Messaging.DeliveryProvider` behaviour.
- Accepts one `Memba.Messaging.DeliveryRequest` at a time through the existing
  `deliver/1` callback.
- Builds a `Swoosh.Email` and hands it to `Memba.Mailer.deliver/1`.

Do **not** add a second provider port, a Postmark-specific behaviour, a process
manager, batching, retries, or provider-specific domain events in this slice.
The existing provider port remains the boundary between the Messaging
application service and outbound transport.

## Provider responsibilities

The Postmark provider owns only outbound email payload construction and delivery
handoff:

1. Validate that the request is an email delivery request.
2. Read provider-specific settings from Memba application configuration.
3. Build a multipart `Swoosh.Email` from the `DeliveryRequest`.
4. Put Postmark-specific options on the email through Swoosh provider options.
5. Call `Memba.Mailer.deliver/1`.
6. Return `:ok` only when Swoosh accepts the email for delivery; return
   `{:error, reason}` for configuration, transport, authentication, or API
   errors.

Recipient-specific outcomes after a successful handoff, such as delivered,
opened, bounced, delayed, or spam complaint, remain webhook-driven and continue
to flow through the existing `POST /webhooks/postmark` path.

## Swoosh/Postmark API shape confirmed

Local Swoosh source confirms `Swoosh.Adapters.Postmark`:

- is configured on the existing `Memba.Mailer` with `adapter:
  Swoosh.Adapters.Postmark` and required `api_key`;
- sends through `Memba.Mailer.deliver/1`, which returns
  `{:ok, result}` or `{:error, reason}`;
- maps `put_provider_option(:metadata, map)` to Postmark `Metadata`;
- maps `put_provider_option(:track_opens, true)` to Postmark `TrackOpens`;
- supports other provider options such as `:message_stream`, `:track_links`,
  and `:inline_css`.

Swoosh's Req API client is available as `Swoosh.ApiClient.Req`, so the
real-send configuration should use that rather than adding direct HTTP calls or
another HTTP dependency.

## Configuration shape left for the next tasks

Later configuration tasks should select this provider only through explicit
configuration. Local development and automated tests should continue to default
to `Memba.Messaging.DeliveryProviders.Fake`.

The provider should fail clearly when selected without required real-send
configuration instead of silently falling back to fake delivery.

## Delivery request shape

The current `DeliveryRequest` already has the fields required for recipient,
subject, text body, message ID, and delivery ID. It does not yet carry
`club_id`, which the iteration plan requires for Postmark metadata. The smallest
future change is to add `club_id` to `DeliveryRequest` and populate it from the
already-available `SendMessage.club_id`; no new membership query or aggregate
lookup is needed.

## Explicit non-decisions for this slice

- Do not persist the Postmark provider message ID unless a later task discovers
  an existing trivial place for it.
- Do not introduce retries, background jobs, batching, suppression handling, or
  bounce policy automation.
- Do not change the delivery state machine or member-facing status vocabulary.
- Do not change acceptance feature files.
- Do not add direct Postmark HTTP code; Swoosh owns provider API interaction.

## ADR conformance

- ADR 0004: Delivery state remains owned by the message aggregate and correlated
  by Memba message/delivery identifiers, not by Postmark message IDs.
- ADR 0005: The provider consumes already-resolved recipient deliveries through
  the existing channel-neutral `DeliveryRequest` boundary.
- ADR 0006: Provider-specific outcomes remain webhook inputs to the existing
  detailed statuses; member-facing simplification is unchanged.
- ADR 0007: The provider does not query or mutate Membership data and does not
  couple Messaging to Membership storage.
- ADR 0012: Open tracking is enabled to support the existing idempotent
  opened-at-least-once model; the provider does not introduce open counts or
  client telemetry.
