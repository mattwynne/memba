# Postmark email delivery

Memba has two Postmark-backed email paths:

- member-message email for club broadcasts;
- shared magic-link authentication email for members and Memba staff.

Each path opts in to real Postmark sending explicitly. Leaving the relevant
provider unset keeps routine local development and automated tests from sending
real email.

## Enable real Postmark sending

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

Do not set `MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark` in routine automated
test environments. Acceptance and domain tests should continue to use fake or
test adapters unless a manual smoke test explicitly needs real email.

When Postmark is selected, Memba fails clearly if the server token or from
address is missing. It does not silently fall back to fake delivery.

### Magic-link authentication email

Set these environment variables for each environment that should deliver real
magic-link sign-in email:

| Variable | Required? | Purpose |
| --- | --- | --- |
| `MEMBA_AUTH_EMAIL_PROVIDER=postmark` | Yes | Opts shared auth magic links into Postmark delivery. If unset or blank, Memba does not configure real Postmark auth delivery from environment variables. |
| `MEMBA_POSTMARK_SERVER_TOKEN` | Yes with Postmark | Shared Postmark server token used by Swoosh as the Postmark API key. Keep this secret out of the repository. |
| `MEMBA_AUTH_EMAIL_FROM_ADDRESS` | Yes with auth Postmark | Sender/from address for magic-link email. Use a verified Memba-controlled sending address such as `auth@mail.memba.io`. |
| `MEMBA_AUTH_EMAIL_MESSAGE_STREAM` | Yes with auth Postmark | Dedicated Postmark Message Stream ID for auth email. Use the exact stream ID configured in Postmark, for example `outbound-authentication`. |

Example local opt-in for a controlled real magic-link test:

```sh
export MEMBA_AUTH_EMAIL_PROVIDER=postmark
export MEMBA_POSTMARK_SERVER_TOKEN="postmark-server-token"
export MEMBA_AUTH_EMAIL_FROM_ADDRESS="auth@mail.memba.io"
export MEMBA_AUTH_EMAIL_MESSAGE_STREAM="outbound-authentication"
./bin/dev up
```

When auth Postmark delivery is selected, Memba fails clearly if the shared server
token, auth from address, or auth message stream is missing. It does not silently
send auth email through an unconfigured Postmark stream.

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

The shared magic-link auth stream does not require a new Memba webhook route.
Keep `POST /webhooks/postmark` configured for member-message delivery/open/bounce
events only. Do not point auth-stream delivery events at this route unless the
webhook handler is later extended to handle auth-email events without
member-message metadata.

## Correlation metadata

Outbound Postmark email includes Swoosh/Postmark metadata so webhook payloads can
be correlated to Memba records without parsing recipients, subjects, or bodies:

| Metadata key | Value |
| --- | --- |
| `memba_message_id` | Memba message aggregate ID |
| `memba_delivery_id` | Memba recipient delivery ID |
| `memba_club_id` | Club ID for the message |

The webhook handler correlates status updates by `memba_message_id` and
`memba_delivery_id` from the webhook `Metadata` object. `memba_club_id` is sent
with the email for diagnostics and end-to-end provider correlation.

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
