# Human todo

## Local dev real inbound email setup

Before testing real inbound email against `bin/dev up`, Matt needs to connect the existing Resend inbound domain to the temporary ngrok URL for the running local app.

Use Resend for local dev inbound email for now. Postmark can receive production `clubs.memba.io`, but the current Postmark account would not enable inbound processing on a second dev server/domain.

- [x] Confirm Resend has receiving enabled on `clubs-dev.memba.io`.
- [x] Set local dev inbound/API config in `.local/secrets.envrc`:
  - `MEMBA_CLUB_INBOUND_EMAIL_DOMAIN=clubs-dev.memba.io`
  - `MEMBA_RESEND_API_KEY=$RESEND_ADMIN_API_KEY` so Memba can fetch full received-email content from Resend's Receiving API.
- [x] Create or choose an ngrok account/authtoken for local dev tunnelling.
- [x] Add the ngrok token to `.local/secrets.envrc`; do not commit it:
  - `NGROK_AUTHTOKEN=...`
- [x] Run `bin/dev up` and copy the ngrok public HTTPS host from the ngrok process logs.
  - Current ngrok URL: `https://monetary-ungodly-atop.ngrok-free.dev`
- [x] In Resend, temporarily configure the webhook URL as `https://<ngrok-host>/webhooks/resend`.
  - Current Resend webhook URL: `https://monetary-ungodly-atop.ngrok-free.dev/webhooks/resend`
- [x] Send a real email to a local dev club address such as `test@clubs-dev.memba.io` or `<local-club-slug>@clubs-dev.memba.io`.
  - Sent from `test@memba.io` to `test@resend.memba.io` with subject `Local dev inbound smoke 1780596387` before the dev domain was renamed to `clubs-dev.memba.io`.
- [x] Confirm the local dev app receives the webhook and creates/rejects the inbound club message according to the local dev seed data.
  - Confirmed on 2026-06-04: Resend sent `POST /webhooks/resend`; Memba fetched the missing text body from Resend's Receiving API; local dev created a Smoke Test Club message with subject `Local dev inbound smoke 1780596387` and body `Hello from a real email into local dev via Resend and ngrok.`
- [ ] After local testing, restore the Resend webhook URL to `https://memba.io/webhooks/resend` if production/fallback Resend webhooks still need to point at production.

Notes:

- `MEMBA_DEV_NGROK=0` disables the ngrok process for normal local dev.
- The Resend webhook URL must be updated whenever ngrok gives a new host.
- A DNSimple MX record for `dev-clubs.memba.io -> inbound.postmarkapp.com` was created while exploring Postmark dev inbound. It is not used by the current Resend dev setup.
- A Postmark server named `memba local dev` was created while testing whether a separate dev inbound server could be enabled. The API token cannot delete servers, so delete or repurpose it in the Postmark UI if it is annoying.

## Postmark member-message manual smoke test

See [`postmark-email.md`](postmark-email.md) for runtime configuration and webhook details.

- [ ] Pick a controlled recipient inbox for the first real send. Suggested: Matt's Fastmail inbox.
- [ ] Send one member broadcast from an explicitly configured environment.
- [ ] Confirm Postmark accepts the email.
- [ ] Confirm the email arrives from the configured From address and has the configured Reply-To address.
- [ ] Trigger or observe delivered/problem webhook events and confirm Memba updates delivery status.

## Postmark auth magic-link manual smoke test

See [`postmark-email.md`](postmark-email.md) for runtime configuration and smoke-test steps.

- [ ] Keep local/test environments from sending real auth email unless explicitly opting into a controlled smoke test.
- [ ] Pick a controlled recipient inbox for the first real auth send.
- [ ] Submit the recipient email at `/auth` from an explicitly configured environment.
- [ ] Confirm Postmark accepts the email on the `outbound-authentication` stream.
- [ ] Confirm the magic-link email arrives from the configured auth From address.
- [ ] Follow the magic link and confirm the browser signs in and redirects to `/`.
