# Postmark email delivery

Memba sends real member-message email through Postmark only when an environment
explicitly opts in. Leaving the Postmark provider unset keeps the default fake
delivery provider, which is required for deterministic local development and
automated tests.

## Enable real Postmark sending

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

No environment variable currently selects a Postmark message stream. Use the
Postmark account/server defaults for this slice unless a later iteration adds
message-stream configuration.

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
