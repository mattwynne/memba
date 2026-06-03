# Task 003: existing Postmark email inspection

Selected task:

> Inspect existing Postmark outbound member-message provider, Postmark delivery-status webhook controller, auth email Postmark configuration, and `docs/postmark-email.md`.

## Source context inspected

- Binding iteration plan:
  - `docs/iterations/020-migrate-production-email-to-postmark/plan.md`
- Binding ADR context:
  - `docs/adr/0016-use-resend-as-switchable-email-provider.md`
  - Nearby/current production and tooling ADRs: `0014`, `0017`, and `0018`
- Historical Postmark/auth iterations:
  - `docs/iterations/008-postmark-email-integration/plan.md`
  - `docs/iterations/010-shared-magic-link-auth/plan.md`
  - `docs/iterations/017-remove-open-tracking/plan.md`
- Existing Postmark member-message delivery code:
  - `web/lib/memba/messaging/email_delivery_providers/postmark.ex`
  - `web/lib/memba/messaging/email_delivery_providers/postmark_config.ex`
  - `web/lib/memba/messaging/email_delivery_provider.ex`
  - `web/lib/memba/messaging/email_delivery_provider_config.ex`
  - `web/config/config.exs`
  - `web/config/runtime.exs`
- Existing Postmark delivery-status webhook code:
  - `web/lib/memba_web/controllers/postmark_webhook_controller.ex`
  - `web/lib/memba_web/router.ex`
- Existing auth email Postmark configuration/code:
  - `web/lib/memba/accounts/auth_email_config.ex`
  - `web/lib/memba/accounts/auth_email.ex`
  - `web/config/runtime.exs`
- Existing operational docs:
  - `docs/postmark-email.md`
  - `docs/human-todo.md`
- Existing tests:
  - `web/test/memba/messaging/email_delivery_providers/postmark_test.exs`
  - `web/test/memba/messaging/email_delivery_providers/postmark_config_test.exs`
  - `web/test/memba/messaging/email_delivery_provider_config_test.exs`
  - `web/test/memba/messaging/email_delivery_provider_test.exs`
  - `web/test/memba_web/controllers/postmark_webhook_controller_test.exs`
  - `web/test/memba_web/router_test.exs`
  - `web/test/memba/accounts/auth_email_config_test.exs`
  - `web/test/memba/accounts/auth_email_test.exs`
- Local Swoosh Postmark adapter source:
  - `web/deps/swoosh/lib/swoosh/adapters/postmark.ex`

## Postmark outbound member-message provider

`Memba.Messaging.EmailDeliveryProviders.Postmark` implements the shared `EmailDeliveryProvider` behaviour and is selected by application/runtime configuration, not by message-sending code. It:

- accepts only `%EmailDeliveryRequest{channel: :email}`;
- validates the active Postmark mailer/provider config through `PostmarkConfig.from_application_env/0`;
- builds a Swoosh email with:
  - `from` display name of `"#{sender_name} via Memba"` and the configured Postmark sender address;
  - `reply_to` set to the original member sender's name/address from the delivery request;
  - recipient name/address from the delivery request;
  - original subject;
  - original body as `text_body`;
  - a minimal escaped HTML body generated from the text body;
  - Postmark/Swoosh provider option `:metadata`.

The provider metadata is exactly:

```elixir
%{
  "memba_message_id" => request.message_id,
  "memba_delivery_id" => request.delivery_id,
  "memba_club_id" => request.club_id
}
```

`Swoosh.Adapters.Postmark` maps `put_provider_option(:metadata, map)` to the Postmark `"Metadata"` payload object. The existing webhook controller expects those same keys under `"Metadata"`, so this remains the core outbound-to-webhook correlation contract.

The provider deliberately normalizes hard failures visibly:

- missing runtime/app config returns `{:error, {:postmark_configuration_error, message}}`;
- Swoosh/API errors return `{:error, {:postmark_delivery_error, reason}}`;
- exceptions from delivery/config validation return `{:error, {:postmark_delivery_exception, module, message}}`;
- unsupported channels return `{:error, {:unsupported_delivery_channel, channel}}`.

### Member-message configuration

`Memba.Messaging.EmailDeliveryProviderConfig` recognizes:

- `MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark`
- `MEMBA_MESSAGING_DELIVERY_PROVIDER=resend`
- `MEMBA_MESSAGING_DELIVERY_PROVIDER=fake`
- unset/blank as `:default`

`runtime.exs` configures Postmark member-message sending when `MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark`:

- `Memba.Mailer` adapter: `Swoosh.Adapters.Postmark`
- `Memba.Mailer` `api_key`: `MEMBA_POSTMARK_SERVER_TOKEN`
- provider config from:
  - `MEMBA_POSTMARK_FROM_ADDRESS` (required)
  - `MEMBA_POSTMARK_REPLY_TO_ADDRESS` (optional)
- Swoosh API client: `Swoosh.ApiClient.Req`

`PostmarkConfig` fails clearly when selected Postmark delivery lacks `MEMBA_POSTMARK_SERVER_TOKEN` or `MEMBA_POSTMARK_FROM_ADDRESS`; the missing-config message points operators back to `MEMBA_MESSAGING_DELIVERY_PROVIDER`.

### Existing coverage

`postmark_test.exs` already proves:

- multipart text/HTML payload construction;
- HTML escaping;
- configured Postmark sender/from address;
- reply-to set to the member sender;
- recipient, subject, and body mapping;
- metadata keys for message, delivery, and club correlation;
- no `:track_opens` provider option;
- no Swoosh handoff when required Postmark config is missing;
- visible Swoosh/API/exception errors.

`postmark_config_test.exs`, `email_delivery_provider_config_test.exs`, and `email_delivery_provider_test.exs` cover provider selection and clear missing Postmark config failures.

### Carry-forward observations for later tasks

- `config/config.exs` still contains default Postmark config keys `message_stream: "outbound-member-broadcasts"` and `track_links: "None"`, but the current runtime path for `MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark` only installs `from` and optional `reply_to`, and `Postmark.deliver/1` only sets `:metadata`.
- The local Swoosh adapter supports `:message_stream` (`"MessageStream"`) and `:track_links` (`"TrackLinks"`) provider options. Member-message Postmark delivery does not currently set either option.
- Iteration 020 acceptance criteria and docs/runbook tasks name an outbound member-message stream. Task 009 should therefore verify whether the current no-message-stream behaviour is intentional or add the missing provider option/configuration with tests.
- Iteration 017 removed open tracking, and current tests assert no `:track_opens`. Do not reintroduce open tracking while adding any stream/link options.

## Postmark delivery-status webhook controller

The current route is:

```text
POST /webhooks/postmark -> MembaWeb.PostmarkWebhookController.create/2
```

It is mounted under the JSON `:api` pipeline in `MembaWeb.Router`.

`PostmarkWebhookController` currently handles outbound delivery-status events only. It maps the normalized Postmark `RecordType` to the shared Messaging status APIs:

| Postmark shape | Memba status API |
| --- | --- |
| `RecordType` `Delivery` or `Delivered` | `Messaging.report_email_delivery_delivered/1` |
| `RecordType` `Bounce` with transient/delayed type/name | `Messaging.report_email_delivery_delayed/1` |
| `RecordType` `Delayed`, `Delay`, or non-transient `Bounce` as applicable | delayed/bounced based on normalization |
| `RecordType` `Bounce` hard/non-transient | `Messaging.report_email_delivery_bounced/1` |
| `RecordType` `SpamComplaint` or `Spam` | `Messaging.report_email_delivery_spam_complaint/1` |
| `RecordType` `Open` or `Opened` | rejected as unsupported |

Correlation values are read first from the webhook `"Metadata"` map:

- `"memba_message_id"` or related fallback names;
- `"memba_delivery_id"` or related fallback names.

There are fallback reads from top-level fields such as `"MessageID"` and `"DeliveryID"`, but the main contract is metadata from outbound sends. The status-reporting command layer is still provider-neutral.

Successful processing returns HTTP `202` with `{"status":"accepted"}`. Unsupported or incomplete events return HTTP `422` with an operator-readable detail.

### Existing coverage

`postmark_webhook_controller_test.exs` uses realistic Postmark-shaped payloads with `"MessageStream"`, `"Metadata"`, `"MessageID"`, recipient fields, delivery fields, bounce fields, and spam complaint fields. It proves:

- delivered webhook events update member and staff delivery records;
- delayed, bounced, and spam complaint events update delivery-problem statuses and reasons;
- open/opened events are rejected and do not mutate delivery state;
- unsupported record types return `422`;
- the endpoint accepts JSON at `/webhooks/postmark`.

`router_test.exs` proves `POST /webhooks/postmark` routes through the API pipeline to `PostmarkWebhookController.create/2`.

### Carry-forward observations for inbound routing

- The existing `/webhooks/postmark` route is delivery-status-specific in code, tests, and current docs.
- The controller dispatches only by delivery-status `RecordType`; it has no inbound-email payload parser or payload-shape dispatch today.
- Iteration 020 acceptance criterion says Postmark delivery-status webhooks remain distinct from Postmark inbound-email webhooks in routing, documentation, and tests. Task 004 should therefore prefer a separate inbound route if Postmark dashboard setup supports it.
- There is no Postmark webhook authentication/signature verification in this controller. ADR 0016 explicitly leaves webhook authenticity as a follow-up concern unless a small existing mechanism can be preserved.

## Auth email Postmark configuration

Auth magic-link email uses the shared `Memba.Accounts.AuthEmail` builder and `Memba.Mailer`, not the member-message delivery provider. `Memba.Accounts.AuthEmailConfig` controls provider selection and validates provider-specific runtime config.

`MEMBA_AUTH_EMAIL_PROVIDER=postmark` selects Postmark auth email in `runtime.exs` and requires:

- `MEMBA_POSTMARK_SERVER_TOKEN`;
- `MEMBA_AUTH_EMAIL_FROM_ADDRESS`;
- `MEMBA_AUTH_EMAIL_MESSAGE_STREAM`.

When Postmark auth email is selected, runtime config installs:

- `Memba.Mailer` adapter: `Swoosh.Adapters.Postmark`
- `Memba.Mailer` `api_key`: `MEMBA_POSTMARK_SERVER_TOKEN`
- `Memba.Accounts.AuthEmail` config:
  - `provider: :postmark`
  - `from: MEMBA_AUTH_EMAIL_FROM_ADDRESS`
  - `message_stream: MEMBA_AUTH_EMAIL_MESSAGE_STREAM`
- Swoosh API client: `Swoosh.ApiClient.Req`

`AuthEmail.deliver_sign_in_link/2` builds text and HTML magic-link bodies and applies Postmark categorization with:

```elixir
put_provider_option(email, :message_stream, config.message_stream)
```

The local Swoosh Postmark adapter maps `:message_stream` to the Postmark `"MessageStream"` field.

Resend auth email remains supported through `MEMBA_AUTH_EMAIL_PROVIDER=resend`, `MEMBA_RESEND_API_KEY`, `MEMBA_AUTH_EMAIL_FROM_ADDRESS`, and `MEMBA_AUTH_EMAIL_MESSAGE_STREAM`; Resend gets tags instead of a Postmark message stream.

### Existing coverage

`auth_email_config_test.exs` already proves:

- required Postmark auth config is read and trimmed from environment;
- missing `MEMBA_POSTMARK_SERVER_TOKEN`, `MEMBA_AUTH_EMAIL_FROM_ADDRESS`, and `MEMBA_AUTH_EMAIL_MESSAGE_STREAM` are reported clearly;
- `MEMBA_AUTH_EMAIL_PROVIDER` supports `postmark` and `resend`, rejects unsupported values, and treats unset/blank as default.

`auth_email_test.exs` proves:

- Postmark auth emails use configured sender/from;
- text and HTML magic-link bodies contain the callback URL;
- Postmark provider options include the configured `message_stream`;
- local/test auth email can use Swoosh test/local config without a Postmark server token;
- missing auth email config prevents Swoosh handoff;
- Swoosh delivery failures are visible.

### Carry-forward observation

Member-message delivery and auth email both configure the single `Memba.Mailer` at runtime. The intended production cutover sets both to Postmark, which is coherent. Mixed-provider runtime combinations should be treated carefully because the later auth-email runtime block can override `Memba.Mailer` adapter/API-key config installed by the member-message block.

## Existing `docs/postmark-email.md`

The current document is a general "Email delivery" page for Postmark and Resend, not yet a complete iteration 020 production cutover runbook. It already covers:

- explicit opt-in to real provider sending;
- member-message Postmark variables:
  - `MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark`
  - `MEMBA_POSTMARK_SERVER_TOKEN`
  - `MEMBA_POSTMARK_FROM_ADDRESS`
  - `MEMBA_POSTMARK_REPLY_TO_ADDRESS`
- Resend member-message fallback variables;
- auth email variables:
  - `MEMBA_AUTH_EMAIL_PROVIDER=postmark` or `resend`
  - `MEMBA_POSTMARK_SERVER_TOKEN`
  - `MEMBA_RESEND_API_KEY`
  - `MEMBA_AUTH_EMAIL_FROM_ADDRESS`
  - `MEMBA_AUTH_EMAIL_MESSAGE_STREAM`
- dedicated auth stream guidance for `outbound-authentication`;
- sender domain guidance for `mail.memba.io`;
- delivery-status webhook URL:
  - `https://<memba-host>/webhooks/postmark`
- delivery-status events to enable and open events to avoid;
- Resend webhook URL:
  - `https://<memba-host>/webhooks/resend`
- correlation metadata keys for outbound member messages;
- current outbound Postmark behaviour, including no open tracking;
- basic manual smoke tests for member-message send and magic-link auth.

The document currently does not cover the full iteration 020 production setup:

- Postmark inbound club-message routing for `clubs.memba.io`;
- required inbound DNS/MX setup;
- an inbound webhook URL distinct from the delivery-status URL;
- Postmark inbound payload/idempotency fields;
- rejection-email smoke testing through Postmark;
- complete Fly secret cutover and Resend rollback instructions.

Those gaps align with later tasks 004, 012, and 013 and should not be silently considered done by this inspection task.

## Human todo/runbook status

`docs/human-todo.md` contains older checklist sections for:

- iteration 008 Postmark member-message setup;
- iteration 010 Postmark auth magic-link setup.

It already records several completed Postmark setup steps, including the member broadcast stream `outbound-member-broadcasts`, sending domain `mail.memba.io`, verified sender settings, delivery-status webhook URL, and Postmark metadata confirmation. It does not yet contain the full iteration 020 inbound/cutover/rollback runbook. Task 013 should update or supplement it.

## ADR conformance

- ADR 0016 is preserved by the inspected implementation: Postmark and Resend remain switchable at runtime, with provider-specific webhook parsing/configuration at the boundary and shared Messaging/Accounts APIs behind them.
- ADR 0014 and ADR 0017 reinforce that production Fly secrets, webhook URLs, smoke tests, and release-state checks must be documented explicitly in later runbook tasks.
- ADR 0018 was reviewed because validation uses `bin/dev`; this task did not change process-compose/devenv orchestration.

## Decisions carried forward for Postmark inbound/cutover tasks

- Keep the existing Postmark delivery-status route/controller behaviour intact while adding inbound support.
- Prefer a distinct Postmark inbound webhook route and docs if Postmark supports separate inbound and delivery-status webhook URLs.
- Reuse outbound metadata keys exactly as existing tests document them: `memba_message_id`, `memba_delivery_id`, and `memba_club_id`.
- Preserve no-open-tracking behaviour from iteration 017.
- Verify or fix member-message Postmark `MessageStream` handling in task 009 before claiming the outbound member-message stream is fully configured by code.
- Keep auth Postmark configuration tied to `MEMBA_AUTH_EMAIL_PROVIDER=postmark`, `MEMBA_POSTMARK_SERVER_TOKEN`, `MEMBA_AUTH_EMAIL_FROM_ADDRESS`, and `MEMBA_AUTH_EMAIL_MESSAGE_STREAM`.
