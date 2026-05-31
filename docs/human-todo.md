# Human todo

## Postmark setup for iteration 008

Before or during Postmark email integration, Matt needs to set up the following outside the codebase.

### Postmark account

- [x] Create or confirm access to a Postmark account for Memba.
- [x] Create a dedicated Message Stream for outbound member broadcasts: `outbound-member-broadcasts`.
- [x] Record the Postmark server token somewhere secure for deployment configuration; do not commit it to the repository. Local secret: `POSTMARK_SERVER_TOKEN`.

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
- [x] Enable webhook events needed by Memba: delivered, opened, bounced, and spam complaint. Postmark delivery-delay events arrive through the bounce/delayed shape handled by the app.
- [x] Enable open tracking for the outbound member broadcast stream/domain.
- [x] Confirm Postmark webhook payloads include metadata/custom fields so Memba can receive `memba_message_id`, `memba_delivery_id`, and `memba_club_id`.

### Deployment configuration

- [x] Provide deployment secrets/config for local configuration:
  - `POSTMARK_SERVER_TOKEN`
  - configured From address
  - configured Reply-To address
  - delivery provider selection for real Postmark sending
  - Postmark message stream and open-tracking option
- [ ] Add the same secrets/config to the production deployment environment once Fly.io deploys are set up.
- [x] Keep local/test environments on fake delivery unless explicitly opting into real Postmark sending.

### Manual smoke test

- [ ] Pick a controlled recipient inbox for the first real send. Suggested: Matt's Fastmail inbox.
- [ ] Send one member broadcast from an explicitly configured environment.
- [ ] Confirm Postmark accepts the email.
- [ ] Confirm the email arrives from the configured From address and has the configured Reply-To address.
- [ ] Open the HTML email and confirm an opened event reaches Memba.
- [ ] Trigger or observe delivered/problem webhook events and confirm Memba updates delivery status.

Notes:

- A local send smoke test can exercise the Postmark provider by opting into `MEMBA_DELIVERY_PROVIDER=postmark` and using `POSTMARK_SERVER_TOKEN`.
- Real Postmark webhooks cannot reach a purely local Phoenix server unless we expose it with a public HTTPS tunnel such as ngrok or Cloudflare Tunnel and temporarily point the Postmark webhook at that URL. Otherwise, webhook smoke testing should happen against the deployed `https://memba.io/webhooks/postmark` endpoint.
