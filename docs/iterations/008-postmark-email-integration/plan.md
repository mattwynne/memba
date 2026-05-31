# Postmark email integration for outbound member messages

Date: 2026-05-30
Status: implementing

## Goal

Memba sends real outbound member message emails through Postmark and can correlate Postmark webhook events back to the correct Memba message and recipient delivery records.

## Background / Context

Iterations 001–004 implemented the domain/application model for member message deliverability. Iteration 005 added the browser-facing app substrate and a Postmark-shaped webhook endpoint. Iteration 006 automates member-facing browser acceptance against the real Phoenix app and webhook endpoint. Iteration 007 plans an operator `/deliveries` overview for diagnosing delivery records across messages.

Those slices prove message state and webhook handling, but outbound delivery still uses `Memba.Messaging.DeliveryProviders.Fake`. The app has a `Memba.Mailer` using Swoosh, with local/test adapters configured, but no production Postmark provider that sends real email.

This iteration connects the existing delivery-provider port to Postmark for real outbound email while preserving deterministic local/test behaviour.

The first release is invite-only, with no self-serve club signup. Abuse controls and club-owned sending domains are deliberately deferred; real sending is enabled only when the deployment/environment is explicitly configured for Postmark.

## Scope

### In scope

- Add a real Postmark-backed delivery provider for email deliveries.
- Build outbound multipart emails from the existing `Memba.Messaging.DeliveryRequest` data: recipient address/name, subject, body, message ID, delivery ID, club ID, and channel.
- Include structured Postmark metadata/custom fields in each send for `memba_message_id`, `memba_delivery_id`, and `memba_club_id` so webhook events can be correlated without relying on brittle subject/body/recipient parsing.
- Send a plain-text part and a minimal safe HTML part for each member message so universal Postmark open tracking can work without adding a designed email template.
- Configure Swoosh/Postmark for any environment that explicitly opts into real sending using environment variables such as a Postmark server token, sender/from address, reply-to/contact address, and open-tracking setting if required by the adapter.
- Keep `Fake`/test delivery provider behaviour available for deterministic unit, domain, and acceptance tests.
- Add tests proving the provider constructs Postmark/Swoosh email payloads with the expected recipient, subject, body, sender, and correlation metadata.
- Add configuration checks or documentation so missing Postmark credentials fail clearly in environments where real sending is enabled.
- Update operational/developer documentation for configuring Postmark and webhook metadata expectations.

### Out of scope

- Changing member-facing message authoring or send flows beyond the provider integration.
- Changing the delivery state machine or status vocabulary.
- Webhook signature/security verification, unless it is trivial and does not expand the slice.
- Abuse controls, club trust workflows, club sending limits, self-serve signup controls, or approval UI; the first release remains invite-only.
- Club-owned sending domains; start with a configurable, monitored Memba-controlled sender on a dedicated sending subdomain, and defer per-club domain verification.
- Retries, background job scheduling, rate limiting, bulk batching, suppression-list handling, or bounce policy automation.
- Inbound email/reply handling, attachments, designed templates, rich HTML design, unsubscribe management, or preference centres; this slice is broadcast-only.
- Operator UI changes beyond whatever documentation is needed to explain Postmark correlation.
- Production authentication/authorization for webhook or operator pages.

## Acceptance Criteria

- When the real Postmark delivery provider is configured, sending a member message hands each email recipient to Postmark via Swoosh rather than only recording it in the fake provider.
- Each outbound Postmark email includes structured metadata/custom fields for Memba `message_id`, `delivery_id`, and `club_id` in subsequent webhook payloads.
- The existing `POST /webhooks/postmark` endpoint can process realistic Postmark delivered/opened/delayed/bounced/spam complaint payloads using that metadata and update the existing delivery records.
- Outbound emails are multipart, with the original body available as plain text and as minimal safe HTML, and Postmark open tracking is enabled universally for member-message emails.
- Local development and automated tests remain deterministic by default and do not send real email unless explicitly configured.
- Any environment can opt into real Postmark sending, including local development, but only through explicit configuration.
- Missing required Postmark configuration in a real-send environment produces a clear error before or during delivery, not a silent fake send.
- Postmark transport, auth, configuration, or API failures fail the send command hard and visibly.
- Recipient-specific delivery outcomes are handled through Postmark webhook events and shown via the existing delivery status model.
- Provider-level tests prove recipient, sender, reply-to, subject, text body, HTML body/open-tracking support, and correlation metadata are sent to Swoosh/Postmark.
- Existing member-facing and operator deliverability acceptance scenarios continue to pass.
- `dev check` passes.

## Open Business Decisions

None known.

Decisions made during planning:

- The sender/from address is configurable. For first production use, prefer a monitored Memba-controlled address on a dedicated sending subdomain, such as `messages@mail.memba.io`, rather than the root `memba.io` domain.
- The reply-to/contact address is configurable and should be monitored.
- Club-owned sender domains are deferred until after the first real-send slice.
- First-release club onboarding is invite-only; self-serve signup and abuse-control workflows are out of scope for this iteration.
- Real sending is allowed in any environment, including local development, but only when explicitly configured.
- Member-message emails are multipart text plus minimal HTML, with universal open tracking.

## Implementation Plan

1. Inspect the current delivery-provider port, message send flow, Swoosh configuration, and Postmark webhook correlation code.
2. Decide the smallest provider shape: likely `Memba.Messaging.DeliveryProviders.Postmark` implementing `Memba.Messaging.DeliveryProvider` and using `Memba.Mailer`/Swoosh.
3. Add configuration for selecting the Postmark provider only when explicitly configured, preserving the fake provider for tests and local defaults.
4. Add required configuration for Postmark server token and sender/from address, with clear error reporting when real sending is enabled but configuration is incomplete.
5. Build the outbound email from `DeliveryRequest`, including recipient, configured sender/from, configured reply-to, subject, text body, minimal safe HTML body, and Postmark metadata/custom fields for `memba_message_id`, `memba_delivery_id`, and `memba_club_id`.
6. Enable universal Postmark open tracking for member-message emails through the supported Swoosh/Postmark mechanism.
7. Ensure transport/auth/configuration/API failures from Postmark fail the send command hard and visibly, while preserving webhook-driven delivery outcomes for recipient-specific status changes.
8. Add focused tests for the Postmark provider using Swoosh test facilities or a test adapter so no real email is sent.
9. Exercise realistic Postmark webhook payloads that contain the outbound metadata and confirm they update the existing delivery records.
10. Update documentation for enabling Postmark, configuring environment variables, configuring the Postmark webhook URL, and choosing a monitored Memba-controlled sending subdomain.
11. Run the existing browser/domain acceptance suites and `dev check`, fixing regressions without weakening fake-provider determinism.

## Open Technical Decisions

- Confirm the exact Swoosh Postmark adapter API and the supported way to pass Postmark metadata/custom fields and open-tracking options.
- Confirm whether the current `DeliveryRequest` already carries `club_id`; if not, thread it through without expanding the domain beyond what is needed for Postmark metadata.
- Do not require persisting Postmark provider message IDs in this slice; implementation may log or retain them only if the existing model makes it trivial.
- Confirm the clearest error shape for hard Postmark transport/auth/configuration/API failures.

## New Capability

A configured Memba deployment can send real multipart member-message emails through Postmark with open tracking, and Postmark delivery/open/bounce/spam events can be correlated back to Memba delivery records using Memba's own message, delivery, and club identifiers.

## Validation Plan

- Run provider tests proving Swoosh/Postmark payload construction, sender/reply-to configuration, multipart text/HTML bodies, open-tracking support, hard failure behaviour, and metadata/custom fields.
- Run webhook tests using realistic Postmark payloads containing the metadata generated by the provider.
- Run the Elixir/domain acceptance path used by `dev check`.
- Run the browser acceptance suite after iterations 006 and 007 are complete.
- Run `dev check`.
- Manual demo in an explicitly configured environment: send a message to a controlled address, confirm Postmark accepts the email from the configured sender with the configured reply-to, open the HTML email, trigger/receive delivered/opened/problem webhooks, and confirm Memba updates the message receipt and `/deliveries` overview.

## Risks / Follow-ups

- Real provider behaviour introduces network failures, provider limits, credential problems, and abuse risk; retry/background delivery and abuse controls should likely be later iterations.
- Webhook signature verification is important before exposing a production endpoint, but may deserve its own security-focused slice.
- Club-owned sending domains may be needed to protect sender reputation or meet club branding requirements, but DNS verification and operational support are deferred.
- Provider message IDs may be useful for diagnostics and support; storing them can be added if needed after the first real-send slice.
- Designed email templates, richer HTML rendering, reply handling, unsubscribe links, and preference management are intentionally deferred.
