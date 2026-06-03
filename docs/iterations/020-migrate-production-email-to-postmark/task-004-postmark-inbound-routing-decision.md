# Task 004: Postmark inbound routing decision

Selected task:

> Determine the cleanest Postmark inbound routing shape. Prefer keeping inbound-email handling separate from outbound delivery-status webhooks if Postmark's dashboard supports separate inbound and delivery-status webhook URLs; otherwise make the shared Postmark route dispatch safely by payload shape.

## Decision

Use a separate Postmark inbound webhook route:

```text
POST /webhooks/postmark/inbound
```

Keep the existing Postmark delivery-status route unchanged:

```text
POST /webhooks/postmark
```

Future implementation tasks should add a dedicated `MembaWeb.PostmarkInboundWebhookController` for the inbound route instead of adding inbound-email payload dispatch to `MembaWeb.PostmarkWebhookController`.

## Why this is the cleanest shape

Postmark supports configuring inbound and delivery-status webhooks separately:

- Postmark's inbound webhook URL is an **Inbound Message Stream** setting. The docs state there is one inbound webhook URL per Inbound Message Stream, configured from the Server's Inbound Message Stream settings or through the `InboundHookUrl` server API field.
- Postmark delivery webhooks are configured from a Server's **Message Stream** Webhooks tab or through the Webhooks API. The delivery webhook setup enables delivery/bounce/spam/open/click/subscription triggers for a webhook URL and message stream.
- The Webhooks API is explicitly for Transactional or Broadcast Message Streams, while the inbound hook is configured as an inbound stream/server setting. This makes separate URLs a supported dashboard/API shape rather than an app-side workaround.

That means Memba does not need a shared Postmark route that guesses payload intent. Keeping the routes distinct better matches:

- the iteration acceptance criterion that Postmark delivery-status webhooks remain distinct from Postmark inbound-email webhooks in routing, documentation, and tests;
- the existing `/webhooks/postmark` code and tests, which are delivery-status-specific;
- ADR 0016's boundary rule: provider-specific webhook parsing stays at the web/controller edge while domain APIs remain provider-neutral.

## Route/controller implications for later tasks

Task 005 should implement the inbound side with this shape:

```text
POST /webhooks/postmark/inbound -> MembaWeb.PostmarkInboundWebhookController.create/2
```

The controller should:

1. parse a Postmark inbound JSON payload;
2. translate it to the provider-neutral inbound email attrs;
3. call `Memba.Messaging.receive_inbound_club_email/2`;
4. return an accepted response for successfully processed or duplicate provider retries;
5. return an operator-readable error for malformed/unsupported inbound payloads.

The existing route should remain delivery-status-only:

```text
POST /webhooks/postmark -> MembaWeb.PostmarkWebhookController.create/2
```

No route-level environment provider switch is needed. Inbound provider selection remains route/payload based so Resend can stay available at `/webhooks/resend` while Postmark inbound is added at `/webhooks/postmark/inbound`.

## Payload-shape facts carried forward

Postmark's inbound webhook payload includes enough provider-neutral data for later parser/idempotency work:

- stable inbound message id: `MessageID`;
- stream marker: `MessageStream`, commonly `"inbound"`;
- sender: `From` and structured `FromFull`;
- recipients: `To`, `ToFull`, `Cc`, `CcFull`, `Bcc`, `BccFull`, and `OriginalRecipient`;
- bodies: `TextBody`, `HtmlBody`, and optional `StrippedTextReply`;
- headers: `Headers`, including SpamAssassin headers;
- attachments: `Attachments` with `Name`, `ContentType`, `ContentLength`, and base64 `Content`.

Task 005 should use `MessageID` as the first-choice `provider_message_id` unless parser tests reveal a better stable field from realistic payloads. Attachment rejection can be detected from the `Attachments` array metadata without decoding content.

## Operational facts carried forward

To preserve addresses such as `kmc@clubs.memba.io`, the production runbook should configure Postmark inbound domain forwarding for the `clubs.memba.io` subdomain:

```text
MX clubs.memba.io -> inbound.postmarkapp.com, priority 10
```

Postmark's inbound domain forwarding docs recommend using a separate subdomain for inbound forwarding and document `inbound.postmarkapp.com` as the MX target. The later docs/runbook tasks should tell Matt to set the inbound stream webhook URL to:

```text
https://<memba-host>/webhooks/postmark/inbound
```

while retaining the delivery-status webhook URL:

```text
https://<memba-host>/webhooks/postmark
```

## Authentication/security note

The existing Postmark delivery-status controller does not perform provider webhook authentication. ADR 0016 records webhook authenticity as a follow-up concern. This task does not expand the slice into a security iteration.

If Postmark dashboard/API configuration allows HTTP basic authentication or custom headers for delivery webhooks, later work may document or preserve those settings for delivery-status webhooks. I did not find an equivalent small, already-configured authentication mechanism for the inbound hook in the existing codebase, so the inbound route decision does not depend on auth changes.

## Sources inspected

- Local plan and prior inspection artifacts:
  - `docs/iterations/020-migrate-production-email-to-postmark/plan.md`
  - `docs/iterations/020-migrate-production-email-to-postmark/task-002-iteration-019-inbound-inspection.md`
  - `docs/iterations/020-migrate-production-email-to-postmark/task-003-postmark-existing-email-inspection.md`
- Binding ADR/context:
  - `docs/adr/0016-use-resend-as-switchable-email-provider.md`
  - `docs/adr/0014-use-fly-io-for-production-hosting.md`
  - `docs/adr/0017-treat-release-state-as-a-first-class-production-artifact.md`
  - `docs/adr/0018-let-devenv-process-compose-own-dev-services.md`
- Existing route/controller/tests:
  - `web/lib/memba_web/router.ex`
  - `web/lib/memba_web/controllers/postmark_webhook_controller.ex`
  - `web/test/memba_web/router_test.exs`
- Postmark upstream docs, inspected because project-local docs do not include Postmark dashboard/API details:
  - `https://postmarkapp.com/developer/webhooks/inbound-webhook`
  - `https://postmarkapp.com/developer/webhooks/delivery-webhook`
  - `https://postmarkapp.com/developer/webhooks/webhooks-overview`
  - `https://postmarkapp.com/developer/api/webhooks-api`
  - `https://postmarkapp.com/developer/user-guide/inbound/inbound-domain-forwarding`
