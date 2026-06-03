# Human todo

## Inbound club email smoke-test setup

Before running the production inbound email smoke tests in `./smoke-tests`, Matt needs to set up the following outside the codebase.

- [x] Automatically seed a controlled production club named `Smoke Test Club` with slug `test`.
- [x] Hard-code the `test` club slug so the smoke-test club does not appear as a public club page.
- [x] Automatically seed a controlled active member of the smoke-test club with primary email address `test@memba.io`.
- [x] Configure `clubs.memba.io` DNS MX to route inbound club email to Postmark: `10 inbound.postmarkapp.com`.
- [x] Configure the Postmark `memba.io` server inbound domain as `clubs.memba.io`.
- [x] Configure the Postmark inbound webhook URL as `https://memba.io/webhooks/postmark`.
- [x] Set up the `test@memba.io` Fastmail account so the smoke-test runner can send real emails and read resulting rejection/distribution emails.
- [x] Provide the smoke-test runner with the `test@memba.io` Fastmail app password through local environment variable `SMOKE_TEST_EMAIL_PASSWORD`; do not commit it.
- [x] Update the smoke-test runner to poll `test@memba.io` via IMAP using `SMOKE_TEST_EMAIL_PASSWORD`, while still supporting a Fastmail JMAP token when provided.
- [x] Confirm `test@memba.io` is usable for Memba member sign-in during smoke tests.
- [x] Confirm the production base URL the smoke tests should target: `https://memba.io`.

The routine inbound wiring smoke tests should cover real email from mailbox to Memba and back again:

- [ ] Unknown sender to `test@clubs.memba.io` is rejected and receives guidance.
- [ ] Known active member `test@memba.io` to `test@clubs.memba.io` creates and distributes a club message.
- [ ] Known active member `test@memba.io` with an attachment is rejected and receives attachment guidance.

HTML-only email is not required as a production smoke test because it mainly exercises the business rule for `plain_text_required`, which is covered by lower-level tests. The smoke tests should focus on production wiring and visible touch-points.

## Postmark setup for iteration 008

Before or during Postmark email integration, Matt needs to set up the following outside the codebase.
See [`postmark-email.md`](postmark-email.md) for the exact runtime configuration
and webhook details.

### Postmark account

- [x] Create or confirm access to a Postmark account for Memba.
- [x] Create a dedicated Message Stream for outbound member broadcasts: `outbound-member-broadcasts`.
- [x] Record the Postmark server token somewhere secure for deployment configuration; do not commit it to the repository. Local secret: `MEMBA_POSTMARK_SERVER_TOKEN`.

### Sending domain

- [x] Choose a dedicated Memba-controlled sending subdomain: `mail.memba.io`.
- [x] Add the domain in Postmark as a sender domain.
- [x] Add the DNS records Postmark gives us for SPF, DKIM, return-path/bounce handling, and DMARC.
- [x] Wait for Postmark to verify the domain. SPF, DKIM, and return-path are verified.
- [x] Avoid sending first-release member broadcasts from the root `memba.io` domain.

### Sender and reply addresses

- [x] Choose a configurable default From address: `messages@mail.memba.io`.
- [x] Choose a configurable Reply-To/contact address that is monitored by a human. Current default: Matt's Fastmail address, `matt@mattwynne.net`.
- [x] Make sure both addresses are acceptable under the verified Postmark sending domain/account settings.
- [x] Decide who monitors replies and support questions for the first invite-only clubs: Matt.

### Webhook configuration

- [x] In Postmark, configure the webhook URL for the deployed Memba environment: `https://memba.io/webhooks/postmark`.
- [x] Enable webhook events needed by Memba: delivered, bounced, and spam complaint. Postmark delivery-delay events arrive through the bounce/delayed shape handled by the app.
- [x] Disable/remove Postmark open webhook events if they were previously enabled. Memba rejects open events as unsupported and does not change delivery status from them.
- [x] Keep Postmark open tracking disabled for the outbound member broadcast stream/domain. Memba does not request or consume open-tracking signals.
- [x] Confirm Postmark webhook payloads include metadata/custom fields so Memba can receive `memba_message_id`, `memba_delivery_id`, and `memba_club_id`.

### Deployment configuration

- [x] Provide deployment secrets/config for local configuration:
  - `MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark`
  - `MEMBA_POSTMARK_SERVER_TOKEN`
  - `MEMBA_POSTMARK_FROM_ADDRESS`
  - `MEMBA_POSTMARK_REPLY_TO_ADDRESS`
- [x] Select Postmark provider config in the production deployment environment after iteration 020 deployment:
  - `MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark`
  - `MEMBA_AUTH_EMAIL_PROVIDER=postmark`
  - `MEMBA_AUTH_EMAIL_FROM_ADDRESS=auth@mail.memba.io`
  - `MEMBA_AUTH_EMAIL_MESSAGE_STREAM=outbound-authentication`
- [x] Keep local/test environments on fake delivery unless explicitly opting into real Postmark sending.

### Manual smoke test

- [ ] Pick a controlled recipient inbox for the first real send. Suggested: Matt's Fastmail inbox.
- [ ] Send one member broadcast from an explicitly configured environment.
- [ ] Confirm Postmark accepts the email.
- [ ] Confirm the email arrives from the configured From address and has the configured Reply-To address.
- [ ] Trigger or observe delivered/problem webhook events and confirm Memba updates delivery status.

Notes:

- A local send smoke test can exercise the Postmark provider by opting into `MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark` and using `MEMBA_POSTMARK_SERVER_TOKEN`, `MEMBA_POSTMARK_FROM_ADDRESS`, and `MEMBA_POSTMARK_REPLY_TO_ADDRESS`.
- Real Postmark webhooks cannot reach a purely local Phoenix server unless we expose it with a public HTTPS tunnel such as ngrok or Cloudflare Tunnel and temporarily point the Postmark webhook at that URL. Otherwise, webhook smoke testing should happen against the deployed `https://memba.io/webhooks/postmark` endpoint.

## Postmark setup for iteration 010 auth magic links

Before enabling real shared magic-link sign-in email, Matt needs to set up the
following outside the codebase. See [`postmark-email.md`](postmark-email.md) for
the exact runtime configuration and smoke-test steps.

### Auth message stream

- [x] Create a dedicated Postmark Transactional Message Stream for authentication email: `outbound-authentication`.
- [x] Keep auth email separate from the member broadcast stream `outbound-member-broadcasts`.
- [x] Do not point auth-stream delivery or delivery-problem events at `POST /webhooks/postmark` unless the app is later extended to process auth-email webhook events.

### Auth sender address

- [x] Choose a verified Memba-controlled From address for auth email: `auth@mail.memba.io`.
- [x] Make sure the address is allowed by the verified `mail.memba.io` sender domain/account settings.

### Deployment configuration

- [x] Provide production deployment secrets/config for real auth email:
  - `MEMBA_AUTH_EMAIL_PROVIDER=postmark`
  - `MEMBA_POSTMARK_SERVER_TOKEN`
  - `MEMBA_AUTH_EMAIL_FROM_ADDRESS=auth@mail.memba.io`
  - `MEMBA_AUTH_EMAIL_MESSAGE_STREAM=outbound-authentication`
- [ ] Keep local/test environments from sending real auth email unless explicitly opting into a controlled smoke test.

### Manual smoke test

- [ ] Pick a controlled recipient inbox for the first real auth send.
- [ ] Submit the recipient email at `/auth` from an explicitly configured environment.
- [ ] Confirm Postmark accepts the email on the `outbound-authentication` stream.
- [ ] Confirm the magic-link email arrives from the configured auth From address.
- [ ] Follow the magic link and confirm the browser signs in and redirects to `/`.
