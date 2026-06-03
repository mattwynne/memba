# Task 002: iteration 019 inbound email inspection

Selected task:

> Inspect iteration 019's provider-neutral inbound email API, idempotency model, rejection-email path, Resend inbound parser/controller, provider selection, and tests.

## Source context inspected

- Iteration 019 plan and implementation notes:
  - `docs/iterations/019-inbound-club-messages-by-email/plan.md`
  - `docs/iterations/019-inbound-club-messages-by-email/implementation-notes.md`
- Binding ADR context:
  - `docs/adr/0016-use-resend-as-switchable-email-provider.md`
  - Nearby/current production and tooling ADRs: `0014`, `0017`, and `0018`
- Core inbound Messaging modules:
  - `web/lib/memba/messaging.ex`
  - `web/lib/memba/messaging/inbound_email.ex`
  - `web/lib/memba/messaging/inbound_email_attachment.ex`
  - `web/lib/memba/messaging/inbound_email_body.ex`
  - `web/lib/memba/messaging/inbound_email_receipt.ex`
  - `web/lib/memba/messaging/inbound_club_destination.ex`
  - `web/lib/memba/messaging/inbound_club_sender.ex`
  - `web/lib/memba/messaging/inbound_club_authorization.ex`
  - `web/lib/memba/messaging/inbound_club_rejection_email.ex`
  - `web/lib/memba/messaging/router.ex`
- Inbound events, projections, and schema:
  - `web/lib/memba/messaging/events/inbound_email_received.ex`
  - `web/lib/memba/messaging/events/inbound_club_email_accepted.ex`
  - `web/lib/memba/messaging/events/inbound_club_email_rejected.ex`
  - `web/lib/memba/messaging/projectors/inbound_email_source.ex`
  - `web/lib/memba/messaging/projections/inbound_email_source.ex`
  - `web/priv/repo/migrations/20260603034844_create_messaging_inbound_email_sources_projection.exs`
- Resend inbound adapter/routing:
  - `web/lib/memba_web/resend_inbound_email_parser.ex`
  - `web/lib/memba_web/controllers/resend_webhook_controller.ex`
  - `web/lib/memba_web/controllers/resend_inbound_webhook_controller.ex`
  - `web/lib/memba_web/resend_webhook_signature.ex`
  - `web/lib/memba_web/router.ex`
- Provider selection:
  - `web/lib/memba/messaging/email_delivery_provider.ex`
  - `web/lib/memba/messaging/email_delivery_provider_config.ex`
  - `web/config/config.exs`
  - `web/config/runtime.exs`
- Relevant tests:
  - `web/test/memba/messaging/inbound_email_api_test.exs`
  - `web/test/memba/messaging/inbound_email_dispatch_test.exs`
  - `web/test/memba/messaging/inbound_email_receipt_test.exs`
  - `web/test/memba/messaging/inbound_email_events_test.exs`
  - `web/test/memba/messaging/inbound_email_source_projection_test.exs`
  - `web/test/memba/messaging/inbound_club_destination_test.exs`
  - `web/test/memba/messaging/inbound_club_sender_test.exs`
  - `web/test/memba/messaging/inbound_club_authorization_test.exs`
  - `web/test/memba/messaging/inbound_email_body_test.exs`
  - `web/test/memba/messaging/inbound_club_message_acceptance_test.exs`
  - `web/test/memba_web/resend_inbound_email_parser_test.exs`
  - `web/test/memba_web/controllers/resend_inbound_webhook_controller_test.exs`
  - `web/test/memba/messaging/email_delivery_provider_config_test.exs`
  - `web/test/memba/messaging/email_delivery_provider_test.exs`

## Provider-neutral inbound email API

Iteration 019 established `Memba.Messaging.receive_inbound_club_email_command/1` and `Memba.Messaging.receive_inbound_club_email/2` as the provider-neutral boundary.

Provider adapters should translate their payloads into attrs accepted by `Memba.Messaging.InboundEmail.new/1`:

- `provider`
- `provider_message_id`
- optional `provider_event_id`
- `from_address`
- `recipient_addresses`
- `subject`
- optional `text_body`
- optional `html_body`
- optional `attachments`

`InboundEmail.new/1` accepts atom- and string-keyed attrs, normalizes provider and email addresses, validates required fields, and converts attachment metadata into `Memba.Messaging.InboundEmailAttachment` structs. `InboundEmail.identity/1` derives the deterministic aggregate id:

```text
inbound-email:<provider>:<provider_message_id>
```

Postmark inbound should therefore map its stable inbound message id into `provider_message_id`, set `provider` to `"postmark"`, and preserve only provider-neutral attachment metadata needed by the existing rejection rule.

## Idempotency model

Inbound retry/idempotency is command-side and event-sourced:

- `Memba.Messaging.Router` routes `ReceiveInboundEmail`, `AcceptInboundClubEmail`, and `RejectInboundClubEmail` to `Memba.Messaging.InboundEmailReceipt`, identified by `:inbound_email_id`.
- The first `ReceiveInboundEmail` emits `InboundEmailReceived`.
- Duplicate `ReceiveInboundEmail` for the same `{provider, provider_message_id}` returns no events.
- `Messaging.receive_inbound_club_email/2` treats an `ExecutionResult` with no events as a duplicate and returns the existing aggregate status/message/rejection state without re-posting or re-sending rejection email.
- Accepted/rejected outcomes are recorded in the same inbound aggregate stream with `InboundClubEmailAccepted` or `InboundClubEmailRejected`.
- `messaging_inbound_email_sources` is a support/audit projection driven by accepted/rejected events, with a defensive unique index on `{provider, provider_message_id}`. The projection is not the idempotency source of truth.

This model is already provider-neutral. Postmark support should reuse it by choosing a stable Postmark provider message id and should not add Postmark-specific duplicate checks outside this API.

## Accepted/rejected business flow

`Messaging.receive_inbound_club_email/2` handles the first provider message through shared business rules:

1. Record receipt in the inbound aggregate.
2. Resolve destination with `InboundClubDestination.resolve/1`.
   - Current accepted address shape: `<club-slug>@<configured inbound domain>`.
   - Default inbound domain is configured as `clubs.memba.io`.
   - Unknown slugs and unsupported recipients become typed rejection reasons.
3. Resolve sender with `InboundClubSender.resolve/1`.
   - Uses `Membership.get_person_by_email/1`, so primary and alternate person email addresses are supported.
4. Authorize active club membership with `InboundClubAuthorization.authorize/2`.
5. Reject attachments before message creation.
6. Normalize plain text with `InboundEmailBody.normalize_text_body/1`.
   - HTML is ignored; there is no HTML-to-text conversion.
   - Common signatures and quoted prior content are stripped conservatively.
   - Missing/blank usable plain text is rejected.
7. Accepted mail calls the existing `send_club_message/2` path, so inbound messages create the same message events, delivery records, and provider handoffs as browser-composed messages.
8. Accepted/rejected outcomes are recorded with `AcceptInboundClubEmail` or `RejectInboundClubEmail`.

Postmark-specific code should stop at parsing/translation plus controller dispatch. The accepted/rejected behaviour should remain in this provider-neutral path.

## Rejection-email path

Rejected inbound mail calls `Memba.Messaging.InboundClubRejectionEmail.deliver/4` after the rejection event is recorded.

Important details for the Postmark migration:

- It sends through `Memba.Mailer`, not through `send_club_message/2`, so no club message or member delivery records are created for rejections.
- The selected real provider comes from `:memba, :messaging_email_delivery_provider`.
- From/reply-to are selected from the configured messaging provider module:
  - Resend provider config when Resend is selected.
  - Postmark provider config when Postmark is selected.
  - Local/fallback paths prefer Postmark, then Resend, with a hard-coded fallback from address.
- Provider options are provider-aware while keeping delivery through Swoosh:
  - Resend gets `:tags`.
  - Other providers, including Postmark, get `:metadata` containing inbound identity and rejection reason.
- Duplicate rejected inbound messages return the existing rejected aggregate state and do not call this delivery path again.

Task 011 should later add/verify explicit Postmark-selected rejection-email tests, but the root path is already provider-selectable.

## Resend inbound parser/controller shape

`MembaWeb.ResendInboundEmailParser.parse/1` accepts `email.received` payloads and translates them to provider-neutral attrs:

- `provider: "resend"`
- `provider_message_id` from `data.email_id`, falling back to `data.id`
- `provider_event_id` from payload `id` or `event_id`
- `from_address` from `data.from`
- `recipient_addresses` combined from `data.to`, `data.cc`, and `data.bcc`
- `subject` from `data.subject`
- required `text_body` from `data.text`
- optional `html_body` from `data.html`
- attachment metadata from `data.attachments`
- `headers` is passed through in the returned map but is not currently part of the `InboundEmail` struct

The routed endpoint is currently shared:

```text
POST /webhooks/resend -> MembaWeb.ResendWebhookController.create/2
```

`ResendWebhookController` dispatches by event type: normalized `email.received` is routed to `ResendInboundEmailParser` and `Messaging.receive_inbound_club_email/2`; other recognized Resend events remain outbound delivery-status events. Signature verification uses `MembaWeb.ResendWebhookSignature` when a signing secret is configured.

There is also a `MembaWeb.ResendInboundWebhookController` module with similar inbound-only handling, but the router points `/webhooks/resend` at `ResendWebhookController`. Current controller tests exercise `/webhooks/resend`, so the shared route is the effective implementation to preserve for Resend regression testing.

## Provider selection

Member-message delivery provider selection remains switchable:

- Default application config uses `Memba.Messaging.EmailDeliveryProviders.Fake` for deterministic local/test behaviour.
- `MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark` selects `Memba.Messaging.EmailDeliveryProviders.Postmark`.
- `MEMBA_MESSAGING_DELIVERY_PROVIDER=resend` selects `Memba.Messaging.EmailDeliveryProviders.Resend`.
- `MEMBA_MESSAGING_DELIVERY_PROVIDER=fake` is also supported.
- `runtime.exs` configures Swoosh `Postmark` or `Resend` adapters with `Swoosh.ApiClient.Req` when a real provider is selected.

Inbound provider selection is currently route/payload based rather than an environment-selected inbound provider. That is consistent with iteration 020's goal to keep Resend available as a fallback while adding a separate Postmark inbound webhook route or safe Postmark-specific dispatcher.

## Existing test coverage to preserve and extend

Provider-neutral tests already cover:

- Building the provider-neutral command and normalizing attrs.
- Command routing to `InboundEmailReceipt`.
- Inbound receipt/accept/reject event behaviour.
- Inbound source projection from accepted/rejected events.
- Destination resolution for club slugs and unsupported recipients.
- Sender resolution across primary/alternate addresses.
- Active-membership authorization.
- Plain-text normalization, quote/signature stripping, and HTML-ignore policy.
- Accepted inbound mail creating normal club messages and delivery records.
- Rejection cases for attachments, missing/blank/HTML-only plain text, unknown senders, non-members, inactive members, and unknown club slugs.
- Duplicate accepted and duplicate rejected inbound retries avoiding duplicate messages, outbound deliveries, and rejection emails.

Resend-specific tests cover:

- Realistic `email.received` parser translation.
- `email_id`/`id` provider-message-id fallback.
- Unsupported event types and malformed fields.
- Controller dispatch from `/webhooks/resend` to the provider-neutral API.
- Accepted, rejected, duplicate, signed, unsigned, and malformed inbound webhook paths.

Provider-selection tests cover:

- Explicit fake/Postmark/Resend member-message provider selection.
- Unknown provider rejection.
- Default fake provider behaviour.
- Postmark and Resend Swoosh payload construction/configuration failure paths.

Iteration 020 should add analogous Postmark inbound parser/controller tests while reusing the provider-neutral tests instead of duplicating the business rules.

## ADR conformance

- ADR 0016 requires Resend and Postmark to remain first-class switchable providers with provider-specific parsers at the boundary and shared domain APIs behind them. The inspected iteration 019 implementation follows that shape: Resend parsing is isolated, while Messaging owns inbound business rules and idempotency.
- ADR 0014 and ADR 0017 reinforce that production email, Fly secrets, webhooks, and smoke tests must be explicit operational artifacts. Later iteration 020 documentation/runbook tasks should name the Postmark secrets, webhook URLs, and smoke checks rather than relying on implicit code behaviour.
- ADR 0018 was reviewed because validation uses `bin/dev`; this inspection did not alter process-compose/devenv service orchestration.

## Decisions carried forward for Postmark tasks

- Reuse `Messaging.receive_inbound_club_email/2` for Postmark accepted/rejected behaviour.
- Use `provider: "postmark"` plus a stable Postmark inbound message id as `provider_message_id`.
- Preserve separate Postmark delivery-status handling and add inbound routing without weakening existing `/webhooks/resend` behaviour.
- Keep Resend parser/controller tests as regression coverage while adding Postmark-specific parser/controller tests.
