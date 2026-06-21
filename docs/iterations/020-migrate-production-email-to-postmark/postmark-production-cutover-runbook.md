# Postmark production cutover runbook

This is Matt's manual runbook for moving production email to Postmark after the
iteration 020 code has been deployed and validated. It complements
[`docs/postmark-email.md`](../../postmark-email.md), which is the reference for
provider setup details and environment variables.

Do not commit provider tokens or copied secret values. Capture command output and
screenshots in the private operations log for the cutover.

## Scope

This cutover moves all production email paths together:

- member-message outbound delivery and rejection emails;
- magic-link authentication email;
- inbound club-message email for `everyone@<club-slug>.clubs.memba.io`.

Keep the providers aligned. Memba's member-message and auth paths share
`Memba.Mailer` runtime configuration, so do not intentionally run a mixed
Postmark/Resend production configuration unless a later iteration changes that
constraint and provides a dedicated runbook.

## Pre-cutover checklist

### Release and environment readiness

- [ ] Confirm the iteration 020 code is deployed to the production Fly app
      (`memba`) and the release command/migrations completed successfully.
- [ ] Confirm the production app boots and stays healthy after deploy:
      `fly status --app memba` and `fly logs --app memba`.
- [ ] Confirm release-state checks required by ADR 0017 passed; do not treat a
      green local test run as proof that production schema/release state is
      correct.
- [ ] Record the current production email settings and the intended rollback
      values in the private operations log before changing secrets.
- [ ] Confirm a controlled recipient inbox is available for auth, outbound
      member-message, and rejection-email smoke tests.
- [ ] Confirm a controlled active member can send from a known address to
      `everyone@test.clubs.memba.io` or another known club subdomain in
      production.

### Postmark dashboard and DNS readiness

- [ ] Postmark account/server is approved for production sending.
- [ ] Sending domain `mail.memba.io` is verified in Postmark for SPF, DKIM,
      return-path/bounce handling, and DMARC alignment.
- [ ] Member broadcast stream exists: `outbound-member-broadcasts`.
- [ ] Member broadcast delivery-status webhook points to:

  ```text
  https://memba.io/webhooks/postmark
  ```

- [ ] Member broadcast webhook events are limited to delivery/problem events that
      Memba handles: delivery, bounce/delayed, and spam complaint. Open/opened
      webhook events and open tracking remain disabled.
- [ ] Auth stream exists as a dedicated Transactional Message Stream:
      `outbound-authentication`.
- [ ] Auth stream is not reusing the member broadcast stream and does not point
      auth-only delivery events at Memba's member-message webhook route.
- [ ] Inbound stream exists for `*.clubs.memba.io`.
- [ ] Inbound stream webhook points to:

  ```text
  https://memba.io/webhooks/postmark/inbound
  ```

- [ ] DNS for inbound club messages is ready to route to Postmark:

  ```text
  MX *.clubs.memba.io 10 inbound.postmarkapp.com
  ```

- [ ] DNS has no higher-priority conflicting MX record for club subdomains such
      as `test.clubs.memba.io` or `kmc.clubs.memba.io` that would steal inbound
      club-message mail.

### Rollback readiness

- [ ] Keep the Resend API key available in the private secret store:
      `MEMBA_RESEND_API_KEY`.
- [ ] Keep the Resend member-message sender values available:
      `MEMBA_MESSAGING_FROM_ADDRESS` and `MEMBA_MESSAGING_REPLY_TO_ADDRESS`.
- [ ] Keep the Resend auth values available:
      `MEMBA_AUTH_EMAIL_PROVIDER=resend`, `MEMBA_AUTH_EMAIL_FROM_ADDRESS`, and a
      Resend-compatible `MEMBA_AUTH_EMAIL_MESSAGE_STREAM` category/stream value.
- [ ] Keep the Resend delivery-status webhook URL configured or ready to restore:

  ```text
  https://memba.io/webhooks/resend
  ```

- [ ] Keep the Resend webhook signing secret available in Fly if Resend webhooks
      may be used: `MEMBA_RESEND_WEBHOOK_SIGNING_SECRET`.
- [ ] Decide before cutover whether inbound rollback to Resend is operationally
      available. The current Resend domain/account previously could not receive
      the `*.clubs.memba.io` namespace without provider changes; if that is
      still true, rollback can restore outbound/auth email to Resend but cannot
      fully restore inbound club-message receiving until Resend inbound domain
      routing is fixed.

## Cutover steps

1. Freeze unrelated production changes while the cutover and smoke tests run.
2. Confirm Postmark dashboard and DNS readiness from the checklist above.
3. Set the Postmark production secrets on Fly:

   ```sh
   fly secrets set --app memba \
     MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark \
     MEMBA_POSTMARK_SERVER_TOKEN=<postmark-server-token> \
     MEMBA_MESSAGING_FROM_ADDRESS=messages@mail.memba.io \
     MEMBA_MESSAGING_REPLY_TO_ADDRESS=<monitored-reply-address> \
     MEMBA_AUTH_EMAIL_PROVIDER=postmark \
     MEMBA_AUTH_EMAIL_FROM_ADDRESS=auth@mail.memba.io \
     MEMBA_AUTH_EMAIL_MESSAGE_STREAM=outbound-authentication
   ```

   Fly will roll the app after secret changes. Keep existing Resend secrets in
   the private secret store; leaving unused Resend secrets in Fly is acceptable
   while rollback readiness is being preserved.

4. Watch the rollout:

   ```sh
   fly status --app memba
   fly logs --app memba
   ```

5. If the app fails to boot because required Postmark config is missing, fix the
   secret values or immediately run the rollback steps below.

## Manual smoke tests

Run these in order and record the exact time, recipient, provider activity link
or screenshot, and Memba observation for each step.

### 1. Auth magic link

- [ ] Visit `https://memba.io/auth`.
- [ ] Submit a controlled member or staff email address.
- [ ] Confirm Postmark accepts the email on `outbound-authentication`.
- [ ] Confirm the inbox receives the magic link from
      `MEMBA_AUTH_EMAIL_FROM_ADDRESS`.
- [ ] Follow the link and confirm the browser signs in and redirects to `/`.
- [ ] Check `fly logs --app memba` for auth email errors or 500s.

### 2. Outbound member message and delivery-status webhook

- [ ] From the production UI, send one member message to a controlled club/member
      audience.
- [ ] Confirm Postmark accepts the email on the member broadcast stream.
- [ ] Confirm the Postmark message includes metadata/custom fields for
      `memba_message_id`, `memba_delivery_id`, and `memba_club_id`.
- [ ] Confirm the controlled inbox receives the email from
      `MEMBA_MESSAGING_FROM_ADDRESS` with the expected reply/contact behaviour.
- [ ] Observe or trigger a delivery/problem event in Postmark.
- [ ] Confirm `POST /webhooks/postmark` returns accepted responses and Memba's
      delivery records or `/deliveries` view update as expected.

### 3. Inbound club message accepted path

- [ ] Email `everyone@test.clubs.memba.io` or another known club subdomain from
      a controlled active member address. Use a unique subject/body for this
      smoke test.
- [ ] Confirm Postmark receives the inbound message and calls
      `https://memba.io/webhooks/postmark/inbound`.
- [ ] Confirm Memba creates one club message for the email.
- [ ] Confirm Memba distributes that message to the expected member audience.
- [ ] Confirm no duplicate club message appears if Postmark retries the same
      inbound message.

### 4. Inbound rejection and rejection-email delivery

- [ ] Email the same club address from an unsupported sender, or send a controlled
      email with an unsupported attachment.
- [ ] Confirm Memba creates no club message for the rejected inbound email.
- [ ] Confirm the rejection email is delivered through the configured Postmark
      member-message provider path.
- [ ] Confirm Fly logs show no unexpected exceptions around the rejection path.

### 5. Rollback readiness check

- [ ] Confirm the Resend API key, sender values, auth settings, webhook signing
      secret, and `https://memba.io/webhooks/resend` setup are still available.
- [ ] Confirm the team understands whether inbound rollback to Resend is fully
      available or blocked by the `clubs.memba.io` Resend account/domain setup.

## Monitoring checks after cutover

For the first hour, and again later the same day:

- [ ] Watch `fly logs --app memba` for runtime config failures, Swoosh/provider
      errors, auth 500s, and webhook errors on `/webhooks/postmark` or
      `/webhooks/postmark/inbound`.
- [ ] Watch Postmark activity for the member broadcast stream, auth stream, and
      inbound stream.
- [ ] Watch Postmark bounces, spam complaints, and delivery delays.
- [ ] Confirm no unexpected Postmark open/opened webhook traffic is hitting
      Memba. If open events appear, disable them in Postmark.
- [ ] Confirm member-message delivery records in Memba continue to move from
      pending/accepted to delivered/problem states when provider events arrive.
- [ ] Confirm inbound club-message emails arrive promptly after DNS/MX
      propagation and that rejected emails do not create club messages.
- [ ] Keep the controlled inbox available for follow-up tests until monitoring is
      quiet.

## Rollback to Resend

Rollback if Postmark production sending, auth, inbound routing, or webhooks fail
in a way that affects users and cannot be corrected quickly.

### Resend rollback secrets

Restore these Fly secrets for Resend-backed member-message delivery and auth:

```sh
fly secrets set --app memba \
  MEMBA_MESSAGING_DELIVERY_PROVIDER=resend \
  MEMBA_RESEND_API_KEY=<resend-api-key> \
  MEMBA_MESSAGING_FROM_ADDRESS=<resend-member-from-address> \
  MEMBA_MESSAGING_REPLY_TO_ADDRESS=<monitored-reply-address> \
  MEMBA_AUTH_EMAIL_PROVIDER=resend \
  MEMBA_AUTH_EMAIL_FROM_ADDRESS=<resend-auth-from-address> \
  MEMBA_AUTH_EMAIL_MESSAGE_STREAM=<resend-auth-category-or-stream> \
  MEMBA_RESEND_WEBHOOK_SIGNING_SECRET=<resend-webhook-signing-secret>
```

Do not unset the Postmark secrets until Resend rollback smoke tests pass; provider
selection variables determine which adapter Memba uses. After rollback is proven,
unused Postmark secrets may be removed from Fly if desired.

### Resend dashboard/DNS rollback

- [ ] Confirm Resend delivery-status webhook is configured for production:

  ```text
  https://memba.io/webhooks/resend
  ```

- [ ] Enable the Resend delivered, bounced, complained/spam-complaint, and
      delayed/problem events that Memba handles. Keep open/opened events disabled
      for Memba.
- [ ] Confirm the Resend webhook signing secret in Fly matches the Resend
      dashboard secret.
- [ ] If inbound rollback to Resend is available, move `*.clubs.memba.io`
      inbound DNS/provider routing back to Resend and point inbound webhooks at
      `https://memba.io/webhooks/resend`.
- [ ] If Resend still cannot receive the `*.clubs.memba.io` namespace, keep or
      disable Postmark inbound routing deliberately and communicate that inbound
      club-message email is degraded until Resend inbound setup is fixed. Do not
      claim rollback is complete for inbound email in that state.

### Rollback smoke tests

- [ ] Watch Fly restart after the Resend secret update:

  ```sh
  fly status --app memba
  fly logs --app memba
  ```

- [ ] Submit `/auth` with a controlled address and confirm the magic link is sent
      through Resend and signs in successfully.
- [ ] Send a controlled member message and confirm Resend accepts it, the inbox
      receives it, and `POST /webhooks/resend` updates Memba delivery records.
- [ ] If Resend inbound rollback is available, email
      `everyone@test.clubs.memba.io` or another known club subdomain from a
      controlled active member address and confirm Memba creates exactly one club
      message through the Resend inbound path.
- [ ] If Resend inbound rollback is not available, document the inbound outage or
      temporary Postmark-inbound exception in the operations log.
- [ ] Continue monitoring Fly logs, Resend activity, and Memba delivery records
      until they are quiet.
