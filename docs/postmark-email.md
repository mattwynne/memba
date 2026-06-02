# Email delivery

Memba has Postmark-backed and Resend-backed email paths:

- member-message email for club broadcasts;
- shared magic-link authentication email for members and Memba staff.

Each path opts in to real provider sending explicitly. Leaving the relevant
provider unset keeps routine local development and automated tests from sending
real email.

## Enable real provider sending

### Member-message email

Set these environment variables for the environment that should send real email:

| Variable | Required? | Purpose |
| --- | --- | --- |
| `MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark` | Yes | Opts the environment into the Postmark delivery provider. If unset or blank, Memba keeps the configured default provider, which is fake in local/test defaults. |
| `MEMBA_POSTMARK_SERVER_TOKEN` | Yes with Postmark | Postmark server token used by Swoosh as the Postmark API key. Keep this secret out of the repository. |
| `MEMBA_POSTMARK_FROM_ADDRESS` | Yes with Postmark | Sender/from address for member-message email. Use a verified, monitored Memba-controlled sending address. |
| `MEMBA_POSTMARK_REPLY_TO_ADDRESS` | Recommended | Reply-To/contact address added to outbound email when configured. This inbox should be monitored by a human. |

Example local opt-in for a controlled real-send test:

```sh
export MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark
export MEMBA_POSTMARK_SERVER_TOKEN="postmark-server-token"
export MEMBA_POSTMARK_FROM_ADDRESS="messages@mail.memba.io"
export MEMBA_POSTMARK_REPLY_TO_ADDRESS="support@memba.io"
./bin/dev up
```

For a Resend fallback, set these instead:

| Variable | Required? | Purpose |
| --- | --- | --- |
| `MEMBA_MESSAGING_DELIVERY_PROVIDER=resend` | Yes | Opts the environment into the Resend delivery provider. |
| `MEMBA_RESEND_API_KEY` | Yes with Resend | Resend API key used by Swoosh. Keep this secret out of the repository. |
| `MEMBA_RESEND_FROM_ADDRESS` | Yes with Resend | Sender/from address for member-message email. Use a verified sender where possible; Resend's sandbox sender is only suitable for smoke tests. |
| `MEMBA_RESEND_REPLY_TO_ADDRESS` | Recommended | Reply-To/contact address added to outbound email when configured. |

Example local Resend opt-in:

```sh
export MEMBA_MESSAGING_DELIVERY_PROVIDER=resend
export MEMBA_RESEND_API_KEY="re_..."
export MEMBA_RESEND_FROM_ADDRESS="messages@mail.memba.io"
export MEMBA_RESEND_REPLY_TO_ADDRESS="support@memba.io"
./bin/dev up
```

Do not set a real delivery provider in routine automated test environments.
Acceptance and domain tests should continue to use fake or test adapters unless
a manual smoke test explicitly needs real email.

When a real provider is selected, Memba fails clearly if required credentials or
from-address configuration is missing. It does not silently fall back to fake
delivery.

### Magic-link authentication email

Set these environment variables for each environment that should deliver real
magic-link sign-in email:

| Variable | Required? | Purpose |
| --- | --- | --- |
| `MEMBA_AUTH_EMAIL_PROVIDER=postmark` or `resend` | Yes | Opts shared auth magic links into real provider delivery. If unset or blank, Memba does not configure real auth delivery from environment variables. |
| `MEMBA_POSTMARK_SERVER_TOKEN` | Yes with Postmark | Shared Postmark server token used by Swoosh as the Postmark API key. Keep this secret out of the repository. |
| `MEMBA_RESEND_API_KEY` | Yes with Resend | Resend API key used by Swoosh. Keep this secret out of the repository. |
| `MEMBA_AUTH_EMAIL_FROM_ADDRESS` | Yes with real auth email | Sender/from address for magic-link email. Use a verified Memba-controlled sending address such as `auth@mail.memba.io`. |
| `MEMBA_AUTH_EMAIL_MESSAGE_STREAM` | Yes | Dedicated auth stream/category. Postmark sends this as `MessageStream`; Resend uses it only as local categorisation. |

Example local opt-in for a controlled real magic-link test:

```sh
export MEMBA_AUTH_EMAIL_PROVIDER=postmark
export MEMBA_POSTMARK_SERVER_TOKEN="postmark-server-token"
export MEMBA_AUTH_EMAIL_FROM_ADDRESS="auth@mail.memba.io"
export MEMBA_AUTH_EMAIL_MESSAGE_STREAM="outbound-authentication"
./bin/dev up
```

For Resend auth email:

```sh
export MEMBA_AUTH_EMAIL_PROVIDER=resend
export MEMBA_RESEND_API_KEY="re_..."
export MEMBA_AUTH_EMAIL_FROM_ADDRESS="auth@mail.memba.io"
export MEMBA_AUTH_EMAIL_MESSAGE_STREAM="auth"
./bin/dev up
```

When real auth delivery is selected, Memba fails clearly if the provider token,
auth from address, or auth message stream/category is missing. It does not
silently send auth email through an unconfigured provider.

## Sender domain and addresses

For first production use, prefer a dedicated Memba-controlled sending subdomain
instead of the root domain, for example:

- sending domain: `mail.memba.io`
- from address: `messages@mail.memba.io`
- reply-to/contact address: `support@memba.io` or another monitored shared inbox

In Postmark, add the sending domain and complete Postmark's required DNS setup
for SPF, DKIM, return-path/bounce handling, and any recommended DMARC alignment.
Wait for Postmark to verify the domain before enabling real sends.

Club-owned sender domains are intentionally deferred. Use one configured
Memba-controlled sender for this first real-send slice.

## Auth message stream

Magic-link authentication email must use a dedicated Postmark Message Stream so
operational metrics and sender reputation are separated from member broadcasts.

Create or confirm a Postmark Transactional Message Stream with this stream ID:

```text
outbound-authentication
```

Then set:

```sh
export MEMBA_AUTH_EMAIL_MESSAGE_STREAM="outbound-authentication"
```

If a different stream ID is chosen in Postmark, set
`MEMBA_AUTH_EMAIL_MESSAGE_STREAM` to that exact ID. Do not reuse the member
broadcast stream for auth email.

The Swoosh Postmark adapter sends this value as Postmark's `MessageStream`
provider option on every magic-link email.

## Webhook configuration

Configure the Postmark webhook URL for each deployed Memba environment:

```text
https://<memba-host>/webhooks/postmark
```

The route is `POST /webhooks/postmark` and accepts JSON webhook payloads. Enable
the Postmark events that Memba currently maps onto delivery state:

- `Delivery`
- `Open`
- `Bounce` for both transient/delayed and hard bounce outcomes
- `SpamComplaint`

Memba returns `202 Accepted` with `{"status":"accepted"}` when a webhook event is
processed. Unsupported or incomplete events return `422 Unprocessable Entity`.

Webhook signature verification is not part of this slice, so production exposure
should account for that follow-up security work.

For Resend, configure this webhook URL:

```text
https://<memba-host>/webhooks/resend
```

Enable Resend events for delivered, opened, bounced, complained/spam complaint,
and delivery-delayed events where available. Memba correlates member-message
Resend events using the `memba_message_id` and `memba_delivery_id` tags/headers
on outbound email.

The shared magic-link auth stream does not require a Memba webhook route. Keep
provider webhooks configured for member-message delivery/open/bounce events only.
Do not point auth-stream delivery events at these routes unless the webhook
handler is later extended to handle auth-email events without member-message
metadata.

## Correlation metadata

Outbound Postmark email includes Swoosh/Postmark metadata, and outbound Resend
email includes equivalent tags and headers, so webhook payloads can be correlated
to Memba records without parsing recipients, subjects, or bodies:

| Metadata key | Value |
| --- | --- |
| `memba_message_id` | Memba message aggregate ID |
| `memba_delivery_id` | Memba recipient delivery ID |
| `memba_club_id` | Club ID for the message |

The Postmark webhook handler correlates status updates by `memba_message_id` and
`memba_delivery_id` from the webhook `Metadata` object. The Resend webhook
handler correlates by the same keys from Resend tags or `X-Memba-*` headers.
`memba_club_id` is sent with the email for diagnostics and end-to-end provider
correlation.

## Outbound email behaviour

For member-message email, the Postmark provider:

- builds multipart email with the original message as plain text and a minimal,
  escaped HTML body;
- sets the configured sender/from address;
- sets the configured reply-to address when present;
- enables Postmark open tracking per email;
- sends through `Memba.Mailer` using Swoosh's Postmark adapter.

Postmark API, authentication, transport, configuration, or unexpected Swoosh
failures make the send command fail visibly. Recipient-specific outcomes after a
successful Postmark handoff remain webhook-driven and appear through Memba's
existing delivery status model.

Member-message email does not currently expose a runtime environment variable
for selecting a Postmark message stream. Magic-link authentication email does:
use `MEMBA_AUTH_EMAIL_MESSAGE_STREAM` as documented above.

## Manual smoke test

For a controlled environment only:

1. Verify the sending subdomain and sender address in Postmark.
2. Set the Postmark environment variables above.
3. Configure the environment-specific webhook URL in Postmark.
4. Send one member message to a controlled inbox.
5. Confirm Postmark accepts the email and the inbox receives it from the
   configured sender with the configured reply-to address.
6. Open the HTML email and confirm an open webhook reaches Memba.
7. Trigger or observe delivery/problem webhooks and confirm the message receipt
   and `/deliveries` overview update through Memba's delivery records.

For a controlled magic-link auth smoke test:

1. Verify the sending subdomain and auth sender address in Postmark.
2. Create or confirm the `outbound-authentication` Transactional Message Stream.
3. Set `MEMBA_AUTH_EMAIL_PROVIDER=postmark`,
   `MEMBA_POSTMARK_SERVER_TOKEN`, `MEMBA_AUTH_EMAIL_FROM_ADDRESS`, and
   `MEMBA_AUTH_EMAIL_MESSAGE_STREAM`.
4. Create a club member with a controlled recipient email, or use a `memba.io`
   staff email.
5. Visit `/auth`, submit the email address, and confirm Postmark accepts the
   email on the auth stream.
6. Confirm the inbox receives a magic-link email from the configured auth sender.
7. Follow the link and confirm the browser signs in and redirects to `/`.
