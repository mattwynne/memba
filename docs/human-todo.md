# Human todo

## Postmark setup for iteration 008

Before or during Postmark email integration, Matt needs to set up the following outside the codebase.

### Postmark account

- Create or confirm access to a Postmark account for Memba.
- Create a dedicated Message Stream for outbound member broadcasts, if Postmark account setup allows it.
- Record the Postmark server token somewhere secure for deployment configuration; do not commit it to the repository.

### Sending domain

- Choose a dedicated Memba-controlled sending subdomain, for example `mail.memba.io`.
- Add the domain in Postmark as a sender domain.
- Add the DNS records Postmark gives us for SPF, DKIM, return-path/bounce handling, and any recommended DMARC alignment.
- Wait for Postmark to verify the domain.
- Avoid sending first-release member broadcasts from the root `memba.io` domain if a sending subdomain can be used instead.

### Sender and reply addresses

- Choose a configurable default From address, for example `messages@mail.memba.io`.
- Choose a configurable Reply-To/contact address that is monitored by a human, for example `support@memba.io` or another shared inbox.
- Make sure both addresses are acceptable under the verified Postmark sending domain/account settings.
- Decide who monitors replies and support questions for the first invite-only clubs.

### Webhook configuration

- In Postmark, configure the webhook URL for the deployed Memba environment: `/webhooks/postmark`.
- Enable webhook events needed by Memba: delivered, opened, delayed, bounced, and spam complaint.
- Enable open tracking for the outbound member broadcast stream/domain.
- Confirm Postmark webhook payloads include metadata/custom fields so Memba can receive `memba_message_id`, `memba_delivery_id`, and `memba_club_id`.

### Deployment configuration

- Provide deployment secrets/config for:
  - Postmark server token
  - configured From address
  - configured Reply-To address
  - delivery provider selection for real Postmark sending
  - any Postmark message stream or open-tracking option required by the implementation
- Keep local/test environments on fake delivery unless explicitly opting into real Postmark sending.

### Manual smoke test

- Pick a controlled recipient inbox for the first real send.
- Send one member broadcast from an explicitly configured environment.
- Confirm Postmark accepts the email.
- Confirm the email arrives from the configured From address and has the configured Reply-To address.
- Open the HTML email and confirm an opened event reaches Memba.
- Trigger or observe delivered/problem webhook events and confirm Memba updates delivery status.
