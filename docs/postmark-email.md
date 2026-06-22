# Email delivery

Memba has Postmark-backed and Resend-backed email paths:

- member-message email for club broadcasts;
- shared magic-link authentication email for members and Memba staff;
- inbound club-message email sent to `everyone@<club-slug>.clubs.memba.io`.

One environment-wide provider setting, `MEMBA_EMAIL_PROVIDER`, selects the
outbound email provider for both member messages and magic-link authentication.
Leaving it unset preserves the configured environment default. Automated tests
should use local/fake delivery; manual development may use a real provider so it
acts like production.

## Production Postmark setup at a glance

Postmark should be configured with distinct production responsibilities:

| Email path | Postmark setup | Memba configuration |
| --- | --- | --- |
| Outbound member broadcasts and rejection emails | Default transactional stream `outbound`; verified sender such as `messages@mail.memba.io`; delivery-status webhook on the same stream | `MEMBA_EMAIL_PROVIDER=postmark`, `MEMBA_POSTMARK_SERVER_TOKEN`, `MEMBA_MESSAGING_FROM_ADDRESS`, optional `MEMBA_MESSAGING_REPLY_TO_ADDRESS` for rejection/contact replies |
| Magic-link authentication | Dedicated auth Transactional Message Stream, recommended ID `outbound-authentication`; verified sender such as `auth@mail.memba.io` | `MEMBA_EMAIL_PROVIDER=postmark`, `MEMBA_POSTMARK_SERVER_TOKEN`, `MEMBA_AUTH_EMAIL_FROM_ADDRESS`, `MEMBA_AUTH_EMAIL_MESSAGE_STREAM` |
| Inbound club messages | Inbound Message Stream for `*.clubs.memba.io`; wildcard MX for `*.clubs.memba.io` points to Postmark inbound; inbound webhook URL configured on the inbound stream | No runtime provider variable. Postmark sends JSON to `POST /webhooks/postmark/inbound`, and Memba derives the club from the recipient host, such as `kmc` from `everyone@kmc.clubs.memba.io`. |

Keep these Postmark paths separate. Delivery-status webhooks for outbound member
messages go to `POST /webhooks/postmark`; inbound email webhooks go to
`POST /webhooks/postmark/inbound`; auth email does not currently require a Memba
webhook.

## Enable real provider sending

Set these environment variables for the environment that should send real email:

| Variable | Required? | Purpose |
| --- | --- | --- |
| `MEMBA_EMAIL_PROVIDER=postmark` or `resend` | Yes for real email | Selects the one outbound provider for member-message and auth email. If unset or blank, Memba keeps the configured environment default. |
| `MEMBA_POSTMARK_SERVER_TOKEN` | Yes with Postmark | Postmark server token used by Swoosh as the Postmark API key. Keep this secret out of the repository. |
| `MEMBA_RESEND_API_KEY` | Yes with Resend | Resend API key used by Swoosh. Keep this secret out of the repository. |
| `MEMBA_MESSAGING_FROM_ADDRESS` | Yes with real email | Sender/from address for member-message email. Use a verified, monitored Memba-controlled sending address. |
| `MEMBA_MESSAGING_REPLY_TO_ADDRESS` | Recommended | Reply-To/contact address available to provider-backed rejection/contact email when configured. This inbox should be monitored by a human. Member broadcasts reply to the member sender. |
| `MEMBA_AUTH_EMAIL_FROM_ADDRESS` | Yes with real email | Sender/from address for magic-link email. Use a verified Memba-controlled sending address such as `auth@mail.memba.io`. |
| `MEMBA_AUTH_EMAIL_MESSAGE_STREAM` | Yes with real email | Dedicated auth stream/category. Postmark sends this as `MessageStream`; Resend uses it as local categorisation. |

Example local Postmark configuration for production-like manual development:

```sh
export MEMBA_POSTMARK_SERVER_TOKEN="postmark-dev-server-token"
export MEMBA_MESSAGING_FROM_ADDRESS="messages@mail-dev.memba.io"
export MEMBA_MESSAGING_REPLY_TO_ADDRESS="support@memba.io"
export MEMBA_AUTH_EMAIL_FROM_ADDRESS="auth@mail-dev.memba.io"
export MEMBA_AUTH_EMAIL_MESSAGE_STREAM="outbound-authentication"
export MEMBA_CLUB_INBOUND_EMAIL_DOMAIN="clubs-dev.memba.io"
./bin/dev up
```

`MEMBA_EMAIL_PROVIDER` is not a secret. Do not put it in `.local/secrets.envrc`;
`bin/dev up` sets local development to Postmark. Use `MEMBA_DEV_EMAIL_PROVIDER`
when you need to override that local command default.

Example production Postmark configuration:

```sh
export MEMBA_EMAIL_PROVIDER=postmark
export MEMBA_POSTMARK_SERVER_TOKEN="postmark-production-server-token"
export MEMBA_MESSAGING_FROM_ADDRESS="messages@mail.memba.io"
export MEMBA_MESSAGING_REPLY_TO_ADDRESS="support@memba.io"
export MEMBA_AUTH_EMAIL_FROM_ADDRESS="auth@mail.memba.io"
export MEMBA_AUTH_EMAIL_MESSAGE_STREAM="outbound-authentication"
./bin/dev up
```

Do not set a real delivery provider in routine automated test environments.
Acceptance and domain tests should continue to use fake or test adapters unless
a manual smoke test explicitly needs real email.

When a real provider is selected, Memba fails clearly if required credentials,
messaging sender, auth sender, or auth stream/category configuration is missing.
It does not silently fall back to fake delivery.

### Production Postmark environment variables

For production, all outbound real email paths use Postmark. Set or confirm these
deployment secrets/config values together:

```text
MEMBA_EMAIL_PROVIDER=postmark
MEMBA_POSTMARK_SERVER_TOKEN=<Postmark server token>
MEMBA_MESSAGING_FROM_ADDRESS=messages@mail.memba.io
MEMBA_MESSAGING_REPLY_TO_ADDRESS=<monitored reply/contact address>
MEMBA_AUTH_EMAIL_FROM_ADDRESS=auth@mail.memba.io
MEMBA_AUTH_EMAIL_MESSAGE_STREAM=outbound-authentication
```

There is no separate `MEMBA_POSTMARK_INBOUND_*` setting. Inbound provider
selection is route-based: Postmark calls `/webhooks/postmark/inbound`, while
Resend remains available at `/webhooks/resend` for fallback support.

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

## Member broadcast stream

Memba currently sends member broadcasts and inbound-rejection emails through the
Postmark server's default transactional stream:

```text
outbound
```

The delivery-status webhook for this stream must point at Memba's Postmark
delivery-status route:

```text
https://<memba-host>/webhooks/postmark
```

Member-message sends include correlation metadata (`memba_message_id`,
`memba_delivery_id`, and `memba_club_id`) so delivery-status webhooks can update
Memba records. The current member-message runtime configuration does not expose a
`MEMBA_*` variable for choosing a Postmark `MessageStream`; before cutover or
after provider maintenance, confirm a controlled member-message send appears in
`outbound` and that the delivery-status webhook is configured there. Do not reuse
the auth stream for member broadcasts.

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

## Inbound club-message email

Inbound club messages use a club subdomain and the `everyone` route:

```text
everyone@<club-slug>.clubs.memba.io
```

For example, members email:

```text
everyone@kmc.clubs.memba.io
```

Configure Postmark inbound domain forwarding for the wildcard
`*.clubs.memba.io` namespace:

```text
MX *.clubs.memba.io -> inbound.postmarkapp.com, priority 10
```

Use a dedicated Postmark Inbound Message Stream for this route and set its
inbound webhook URL to:

```text
https://<memba-host>/webhooks/postmark/inbound
```

Postmark inbound payloads are parsed from fields including `MessageID`, `From` /
`FromFull`, `OriginalRecipient`, `To` / `ToFull`, `Subject`, `TextBody`,
`HtmlBody`, `Attachments`, and `Headers`. Memba uses Postmark's top-level
`MessageID` as the stable provider retry/idempotency key; duplicate Postmark
retries for the same `MessageID` do not create duplicate club messages or
duplicate rejection emails.

Memba uses the provider-neutral inbound email handling shared with Resend:

- active members can post to their club address;
- alternate known member email addresses are accepted;
- only the `everyone` local part is accepted for now;
- unknown club subdomains and unsupported local parts are rejected without
  creating a club message;
- the old flat address shape, such as `kmc@clubs.memba.io`, is no longer
  accepted;
- unknown senders, inactive members, and non-members are rejected without
  creating a club message;
- inbound emails with attachments are rejected;
- inbound emails without usable plain text are rejected;
- rejection emails are delivered through the configured real provider, so they
  go through Postmark when `MEMBA_EMAIL_PROVIDER=postmark`.

Webhook authentication/signature verification for Postmark inbound webhooks is a
follow-up security concern. Do not put other applications behind this route, and
limit the Postmark inbound stream to the `*.clubs.memba.io` mail flow.

## Delivery-status webhook configuration

Configure the Postmark webhook URL for each deployed Memba environment:

```text
https://<memba-host>/webhooks/postmark
```

The route is `POST /webhooks/postmark` and accepts JSON webhook payloads. Enable
the Postmark events that Memba currently maps onto delivery state:

- `Delivery`
- `Bounce` for both transient/delayed and hard bounce outcomes
- `SpamComplaint`

Memba returns `202 Accepted` with `{"status":"accepted"}` when a webhook event is
processed. Unsupported or incomplete events return `422 Unprocessable Entity`.
Do not enable Postmark `Open`/`Opened` webhook events for Memba. Memba does not
track email opens; if a provider sends an open event anyway, Memba rejects it as
unsupported and does not change delivery status.

Webhook signature verification is not part of this slice, so production exposure
should account for that follow-up security work.

Do not configure Postmark inbound email to use this route. Inbound email must use
the separate inbound stream webhook URL:

```text
https://<memba-host>/webhooks/postmark/inbound
```

For Resend, configure this webhook URL:

```text
https://<memba-host>/webhooks/resend
```

Enable Resend events for delivered, bounced, complained/spam complaint, and
delivery-delayed events where available. Do not enable Resend opened/open events
for Memba. Memba correlates member-message Resend events using the
`memba_message_id` and `memba_delivery_id` tags/headers on outbound email.

The shared magic-link auth stream does not require a Memba webhook route. Keep
provider webhooks configured for member-message delivery and delivery-problem
events only. Do not point auth-stream delivery events at these routes unless the
webhook handler is later extended to handle auth-email events without
member-message metadata.

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
- does not request Postmark open tracking;
- sends through `Memba.Mailer` using Swoosh's Postmark adapter.

Postmark API, authentication, transport, configuration, or unexpected Swoosh
failures make the send command fail visibly. Recipient-specific outcomes after a
successful Postmark handoff remain webhook-driven and appear through Memba's
existing delivery status model.

Member-message email does not currently expose a runtime environment variable
for selecting a Postmark message stream. Confirm the Postmark server/stream setup
records member-message sends in the intended member broadcast stream. Magic-link
authentication email does expose a stream variable: use
`MEMBA_AUTH_EMAIL_MESSAGE_STREAM` as documented above.

## Local smoke-test guidance

Routine local development and automated tests should not set real provider
environment variables. By default, member-message delivery uses the fake provider
and the mailer uses local/test adapters, so local tests do not send real Postmark
or Resend email.

For a local Postmark member-message smoke test, opt in explicitly with the
member-message Postmark environment variables, start the app, send one message to
a controlled inbox, and confirm:

- Postmark accepts the email;
- the email arrives from `MEMBA_MESSAGING_FROM_ADDRESS`;
- replies go to the member sender/contact address expected for the message;
- Postmark shows the `memba_message_id`, `memba_delivery_id`, and
  `memba_club_id` metadata.

For a local auth smoke test, opt in explicitly with the auth Postmark environment
variables and confirm the magic-link email is accepted on
`MEMBA_AUTH_EMAIL_MESSAGE_STREAM`.

For a local inbound parser/controller smoke test, post a Postmark-shaped JSON
payload to:

```text
http://localhost:4000/webhooks/postmark/inbound
```

Use a payload with `MessageID`, `From`, `OriginalRecipient` such as
`everyone@kmc.clubs.memba.io`, `Subject`, and `TextBody`. This tests Memba's
inbound route without changing DNS.

For a real local inbound email smoke test, use the dedicated Postmark dev server
with the receiving-enabled `*.clubs-dev.memba.io` wildcard domain:

1. Add ngrok, Postmark, and inbound-domain secret/config values to `.local/secrets.envrc`:

   ```sh
   export NGROK_AUTHTOKEN="..."
   export MEMBA_POSTMARK_SERVER_TOKEN="postmark-dev-server-token"
   export MEMBA_MESSAGING_FROM_ADDRESS="messages@mail-dev.memba.io"
   export MEMBA_AUTH_EMAIL_FROM_ADDRESS="auth@mail-dev.memba.io"
   export MEMBA_AUTH_EMAIL_MESSAGE_STREAM="outbound-authentication"
   export MEMBA_CLUB_INBOUND_EMAIL_DOMAIN="clubs-dev.memba.io"
   ```

2. Run `bin/dev up`. The dev command starts the `ngrok` process through
   devenv/process-compose when an ngrok token is configured, reads the current
   ngrok HTTPS URL, and syncs the dedicated Postmark dev server webhooks to:

   ```text
   https://<ngrok-host>/webhooks/postmark
   https://<ngrok-host>/webhooks/postmark/inbound
   ```

3. Send real email to a local club address such as
   `everyone@test.clubs-dev.memba.io`. Memba dev resolves the club from the
   configured `MEMBA_CLUB_INBOUND_EMAIL_DOMAIN` value while Postmark reaches the
   local app through ngrok.

## Manual production smoke test

For a controlled environment only:

1. Verify the sending subdomain and sender address in Postmark.
2. Set the Postmark environment variables above.
3. Configure the environment-specific delivery-status webhook URL in Postmark.
4. Send one member message to a controlled inbox.
5. Confirm Postmark accepts the email and the inbox receives it from the
   configured sender with the expected Reply-To/contact behaviour.
6. Trigger or observe delivery/problem webhooks and confirm the message receipt
   and `/deliveries` overview update through Memba's delivery records.

For a controlled magic-link auth smoke test:

1. Verify the sending subdomain and auth sender address in Postmark.
2. Create or confirm the `outbound-authentication` Transactional Message Stream.
3. Set `MEMBA_EMAIL_PROVIDER=postmark`, `MEMBA_POSTMARK_SERVER_TOKEN`,
   `MEMBA_AUTH_EMAIL_FROM_ADDRESS`, and `MEMBA_AUTH_EMAIL_MESSAGE_STREAM`.
4. Create a club member with a controlled recipient email, or use a `memba.io`
   staff email.
5. Visit `/auth`, submit the email address, and confirm Postmark accepts the
   email on the auth stream.
6. Confirm the inbox receives a magic-link email from the configured auth sender.
7. Follow the link and confirm the browser signs in and redirects to `/`.

For a controlled inbound club-message smoke test:

1. Verify the `*.clubs.memba.io` MX record points to Postmark inbound.
2. Verify the Postmark inbound stream webhook URL is
   `https://<memba-host>/webhooks/postmark/inbound`.
3. Email `everyone@test.clubs.memba.io` or
   `everyone@<known-club-slug>.clubs.memba.io` from a controlled active member
   address.
4. Confirm Memba creates the club message and sends member deliveries.
5. Email the same address from an unsupported sender, or with an unsupported
   attachment, and confirm Memba creates no club message.
6. Confirm the rejection email is delivered through the selected Postmark
   member-message provider path.
