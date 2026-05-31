# Postmark email integration for outbound member messages

Date: 2026-05-30
Status: draft

## Goal

Memba sends real outbound member message emails through Postmark and can correlate Postmark webhook events back to the correct Memba message and recipient delivery records.

## Background / Context

Iterations 001–004 implemented the domain/application model for member message deliverability. Iteration 005 added the browser-facing app substrate and a Postmark-shaped webhook endpoint. Iteration 006 automates member-facing browser acceptance against the real Phoenix app and webhook endpoint. Iteration 007 plans an operator `/deliveries` overview for diagnosing delivery records across messages.

Those slices prove message state and webhook handling, but outbound delivery still uses `Memba.Messaging.DeliveryProviders.Fake`. The app has a `Memba.Mailer` using Swoosh, with local/test adapters configured, but no production Postmark provider that sends real email.

This iteration connects the existing delivery-provider port to Postmark for real outbound email while preserving deterministic local/test behaviour.

## Scope

### In scope

- Add a real Postmark-backed delivery provider for email deliveries.
- Build outbound emails from the existing `Memba.Messaging.DeliveryRequest` data: recipient address/name, subject, body, message ID, delivery ID, and channel.
- Include metadata or tags in each Postmark send so webhook events can be correlated to `message_id` and `delivery_id` without relying on brittle subject/body parsing.
- Configure Swoosh/Postmark for production-style environments using environment variables such as a Postmark server token and sender/from address.
- Keep `Fake`/test delivery provider behaviour available for deterministic unit, domain, and acceptance tests.
- Add tests proving the provider constructs Postmark/Swoosh email payloads with the expected recipient, subject, body, sender, and correlation metadata.
- Add configuration checks or documentation so missing Postmark credentials fail clearly in environments where real sending is enabled.
- Update operational/developer documentation for configuring Postmark and webhook metadata expectations.

### Out of scope

- Changing member-facing message authoring or send flows beyond the provider integration.
- Changing the delivery state machine or status vocabulary.
- Webhook signature/security verification, unless it is trivial and does not expand the slice.
- Retries, background job scheduling, rate limiting, bulk batching, suppression-list handling, or bounce policy automation.
- Inbound email, attachments, templates, rich HTML design, unsubscribe management, or preference centres.
- Operator UI changes beyond whatever documentation is needed to explain Postmark correlation.
- Production authentication/authorization for webhook or operator pages.

## Acceptance Criteria

- When the real Postmark delivery provider is configured, sending a member message hands each email recipient to Postmark via Swoosh rather than only recording it in the fake provider.
- Each outbound Postmark email includes enough structured metadata to identify the Memba `message_id` and `delivery_id` in subsequent webhook payloads.
- The existing `POST /webhooks/postmark` endpoint can process realistic Postmark delivered/opened/delayed/bounced/spam complaint payloads using that metadata and update the existing delivery records.
- Local development and automated tests remain deterministic by default and do not send real email unless explicitly configured.
- Missing required Postmark configuration in a real-send environment produces a clear error before or during delivery, not a silent fake send.
- Provider-level tests prove recipient, sender, subject, body, and correlation metadata are sent to Swoosh/Postmark.
- Existing member-facing and operator deliverability acceptance scenarios continue to pass.
- `dev check` passes.

## Open Business Decisions

- What sender/from address should production member-message emails use?
- Should the first real emails be plain text only, or should this slice include a minimal HTML body as well?
- Which environments are allowed to send real emails initially: production only, staging/demo, or local opt-in too?

## Implementation Plan

1. Inspect the current delivery-provider port, message send flow, Swoosh configuration, and Postmark webhook correlation code.
2. Decide the smallest provider shape: likely `Memba.Messaging.DeliveryProviders.Postmark` implementing `Memba.Messaging.DeliveryProvider` and using `Memba.Mailer`/Swoosh.
3. Add configuration for selecting the Postmark provider only when explicitly configured, preserving the fake provider for tests and local defaults.
4. Add required configuration for Postmark server token and sender/from address, with clear error reporting when real sending is enabled but configuration is incomplete.
5. Build the outbound email from `DeliveryRequest`, including recipient, sender, subject, text body, and Postmark metadata for `memba_message_id` and `memba_delivery_id`.
6. Add focused tests for the Postmark provider using Swoosh test facilities or a test adapter so no real email is sent.
7. Exercise realistic Postmark webhook payloads that contain the outbound metadata and confirm they update the existing delivery records.
8. Update documentation for enabling Postmark, configuring environment variables, and configuring the Postmark webhook URL.
9. Run the existing browser/domain acceptance suites and `dev check`, fixing regressions without weakening fake-provider determinism.

## Open Technical Decisions

- Confirm the exact Swoosh Postmark adapter API and the supported way to pass Postmark metadata/custom fields.
- Decide whether the provider should return `:ok` immediately after a successful Postmark API response or persist provider message IDs for later diagnostics.
- Decide whether provider failures should fail the whole message send command in this slice or be captured as delivery failures for later retry work.

## New Capability

A configured Memba deployment can send real member-message emails through Postmark, and Postmark delivery/open/bounce/spam events can be correlated back to Memba delivery records.

## Validation Plan

- Run provider tests proving Swoosh/Postmark payload construction and metadata.
- Run webhook tests using realistic Postmark payloads containing the metadata generated by the provider.
- Run the Elixir/domain acceptance path used by `dev check`.
- Run the browser acceptance suite after iterations 006 and 007 are complete.
- Run `dev check`.
- Manual demo in an explicitly configured environment: send a message to a controlled address, confirm Postmark accepts the email, trigger/receive delivered/opened/problem webhooks, and confirm Memba updates the message receipt and `/deliveries` overview.

## Risks / Follow-ups

- Real provider behaviour introduces network failures, provider limits, and credential problems; retry/background delivery should likely be a later iteration.
- Webhook signature verification is important before exposing a production endpoint, but may deserve its own security-focused slice.
- Provider message IDs may be useful for diagnostics and support; storing them can be added if needed after the first real-send slice.
- Email templates, HTML rendering, unsubscribe links, and preference management are intentionally deferred.
