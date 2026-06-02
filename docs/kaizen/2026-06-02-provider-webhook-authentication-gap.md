# Problem: Provider webhooks lacked authentication guardrails

Date: 2026-06-02

## Context

While debugging a production member message whose Resend deliveries remained shown as `sent`, we found that the Resend webhook endpoint existed in Memba but no webhook was configured in Resend. After creating the Resend webhook, Resend returned a signing secret.

## Expected standard

When an email provider webhook is added to production, the setup should make both parts obvious and hard to forget:

- the provider dashboard/API webhook exists and sends the required event types;
- the application verifies that incoming webhook requests are genuinely from the provider.

## What happened

- `GET /webhooks` in Resend initially returned no configured webhooks.
- The app had `POST /webhooks/resend`, but production had no Resend webhook configured to call it.
- After creating the Resend webhook, Resend returned a `whsec_...` signing secret.
- Memba's Resend webhook controller did not yet verify signatures.
- The Postmark webhook controller follows the same application pattern: it accepts delivery status payloads but has no obvious authentication/signature/basic-auth check in `web/lib/memba_web/controllers/postmark_webhook_controller.ex`.
- A Postmark API check showed a production webhook configured at `https://memba.io/webhooks/postmark` for delivery, open, bounce, and spam complaint triggers, with no credential embedded in the URL returned by the API.

## Impact

Customer-facing delivery state could remain stale if provider webhooks are not configured. Webhook endpoints without provider authentication can also accept spoofed delivery status updates if an attacker finds the endpoint and constructs plausible payloads.

## What allowed it to happen

The provider integration workflow lacked a production readiness guardrail for webhook configuration and webhook authentication. Tests proved payload mapping but did not assert production webhook registration, secret storage, or request verification.

## Observations

- Resend showed the four affected emails as delivered, while Memba had only `MessageSent` and `EmailDeliveryCreated` events for the message.
- Fly logs around the message send showed no `POST /webhooks/resend` requests.
- `GET /webhooks` with the Resend admin API key returned an empty list before manual setup.
- Resend webhook creation returned a signing secret, making verification support explicit.
- Postmark has a production webhook configured for the expected message stream and triggers, so the gap is not missing registration; it is the lack of an obvious request-authentication mechanism in the app/configuration.

## Why this matters

Provider integrations are easy to half-install: sending can work while delivery feedback silently fails or remains unauthenticated. Without a checklist or automated verification, the problem appears only later as stale user-facing delivery status or as a security gap.

## Open questions

- What authentication mechanisms does Postmark support for webhooks in our current plan/configuration?
- Should deployment or smoke checks verify configured provider webhooks and expected event subscriptions?
- Should provider webhook endpoints fail closed when their signing/authentication secret is missing in production?

## Possible prevention ideas

- Add a provider integration checklist covering webhook URL, event subscriptions, signing/authentication secret, and production smoke test.
- Add tests for authenticated webhook rejection/acceptance for each provider.
- Add production startup warnings or health checks when a selected provider lacks webhook authentication configuration.
