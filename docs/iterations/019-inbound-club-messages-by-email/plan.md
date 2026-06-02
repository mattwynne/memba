# Inbound club messages by email

Date: 2026-06-02
Status: ready

## Goal

Let an active club member create a new club-wide message by sending an email to the club's inbound address.

After this iteration, Alice can email `kmc@clubs.memba.io` from any email address on her person record, and Memba creates a Kootenay Mountaineering Club message from that email and distributes it to the club's active members using the same delivery and visibility rules as a message composed in the web UI.

## Background / Context

Members can already compose club messages in the browser and receive club-message email. Clubs now have slugs and member-facing subdomains, so there is enough club identity to introduce a simple club-specific inbound email address.

The problem captured in `docs/problems/2026-06-02-send-club-message-by-email.md` is that members cannot create a club message by emailing Memba. The first useful slice should prove the core workflow without designing future replies, channels, rich HTML, attachments, or custom inbound domains.

Production currently uses Resend. Postmark is present in the codebase but still unproven for production use. This iteration should integrate with Resend inbound webhooks now, while keeping the app-side inbound email API provider-neutral enough that Postmark can replace or supplement Resend later.

## Scope

### In scope

- Add a club inbound address convention: `<club-slug>@clubs.memba.io`, for example `kmc@clubs.memba.io`.
- Treat that address as the club's implicit everyone address for now.
- Add a provider-neutral internal command/API for receiving an inbound club-message email.
- Add a Resend inbound webhook endpoint/parser that translates Resend inbound payloads into the provider-neutral internal command/API.
- Identify the sender from any email address on a person record, primary or alternate.
- Authorize inbound posting only when the identified person is an active member of the destination club.
- Create a new club message from an accepted inbound email.
- Address the created message to the same active club-member audience as a web-composed club message.
- Distribute accepted inbound messages through the existing outbound email delivery path.
- Preserve the same member-visible message detail, delivery status, and audit semantics as web-composed club messages.
- Use only the inbound email's non-blank `text/plain` body as the message body.
- Ignore inbound `text/html` for this slice and do not implement HTML-to-text conversion.
- Strip common quoted prior-message text and signatures from the plain-text body before validating and storing it.
- Reject inbound emails with no usable plain-text body after quote/signature stripping.
- Reject inbound emails that include attachments.
- Reject inbound emails from unknown senders, inactive members, and known people who are not active members of the destination club.
- Send a polite rejection email to the sender when the inbound email is not posted, including the reason and support/contact guidance.
- Do not send a separate confirmation email for accepted messages; the sender receives the normal club-message copy if included in the audience.
- Add or update tests and acceptance support for Resend inbound webhook handling and inbound club-message behaviour.
- Keep `dev check` green.

### Out of scope

- Replies to existing message emails.
- Threading or conversation grouping.
- Attachments support.
- Preserving, sanitising, rendering, or forwarding inbound HTML formatting.
- HTML-to-text conversion.
- Channels or sub-groups such as `everyone@kmc.clubs.memba.io`.
- Club custom inbound domains such as `all@members.kootenaymountaineeringclub.ca`.
- Moderation queues or hold-for-review workflows.
- Public contact messages from unknown senders.
- Final deliverability/reputation strategy for inbound or outbound domains.
- Switching production outbound delivery from Resend to Postmark.

## Iteration Type

Behaviour-facing.

The user-observable rule is that an active member can post a new club-wide message by emailing the club's inbound address, while unauthorised or unsupported inbound emails are rejected without creating a club message.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

This iteration changes who can create club messages, how club identity is resolved from email addresses, sender authorization, unsupported-content policy, and rejection behaviour. Stakeholder-readable examples are useful because small policy choices matter: alternate sender addresses are allowed, non-members are rejected, attachments are rejected, and HTML-only email is not converted.

Update this shared Cucumber feature file:

- `acceptance-tests/features/member_message_deliverability.feature`

Add `@wip` scenarios under new inbound-email rules until implementation catches up:

- Alice emails `kmc@clubs.memba.io` and the email becomes a KMC club message sent to KMC members only.
- Alice sends from an alternate email address on her person record and Memba still posts the message as Alice.
- An unknown sender emails `kmc@clubs.memba.io` and receives a rejection; no club message is created.
- Pat, a known member of another club but not KMC, emails `kmc@clubs.memba.io` and receives a rejection; no KMC message is created.
- Alice sends an email with an attachment and receives an attachment-not-supported rejection; no club message is created.
- Alice sends an email whose plain-text body contains a signature and quoted prior content; Memba posts only the new message text.
- Alice sends an HTML-only email and receives a plain-text-required rejection; no club message is created.

Matt should review the added scenario language as domain language before treating this plan as final.

## Allowed acceptance feature changes

- `acceptance-tests/features/member_message_deliverability.feature`: add `@wip` inbound-email scenarios documenting accepted inbound posting, alternate sender addresses, rejection for unknown/non-member senders, unsupported attachments, quote/signature stripping, and HTML-only rejection. The `@wip` tags keep planning-time checks green until delivery implements the supporting steps and application behaviour.
- Acceptance support and step definitions may be updated during implementation to simulate Resend inbound webhook payloads, inspect rejection emails in the test mailbox, and assert that no club message was created for rejected inbound email.

## Acceptance Criteria

- `kmc@clubs.memba.io` resolves to Kootenay Mountaineering Club by the existing `kmc` club slug.
- Unknown club slugs in inbound recipient addresses are rejected without creating a message.
- An inbound email to `kmc@clubs.memba.io` from Alice's primary email address creates a KMC club message from Alice.
- An inbound email to `kmc@clubs.memba.io` from one of Alice's alternate email addresses also creates a KMC club message from Alice.
- Accepted inbound messages are visible anywhere web-composed club messages are visible to active KMC members.
- Accepted inbound messages address the same active club-member audience as web-composed club messages.
- Accepted inbound messages are delivered through the existing outbound delivery provider path.
- Accepted inbound messages create the same kind of delivery records/statuses as web-composed club messages.
- Accepted inbound messages do not address members of other clubs.
- Memba does not send a separate acceptance confirmation email.
- The inbound email subject becomes the club message subject.
- The inbound email `text/plain` body, after quote/signature stripping, becomes the club message body.
- Inbound `text/html` is ignored in this slice.
- Memba does not implement HTML-to-text conversion in this slice.
- If there is no non-blank plain-text body after quote/signature stripping, no club message is created and the sender receives a clear rejection email.
- If the inbound email has attachments, no club message is created and the sender receives a clear rejection email explaining attachments are not supported yet.
- If the sender email address is unknown to Memba, no club message is created and the sender receives a polite rejection email with support/contact guidance.
- If the sender email address belongs to a person who is not an active member of the destination club, no club message is created and the sender receives a polite rejection email with support/contact guidance.
- If the sender email address belongs to an inactive member of the destination club, no club message is created and the sender receives a polite rejection email with support/contact guidance.
- Rejection emails include enough reason for the sender to know why their message was not posted, without exposing private club data unnecessarily.
- Resend inbound webhook payloads are accepted by a dedicated endpoint and translated into the provider-neutral inbound email command/API.
- The provider-neutral inbound email command/API is covered by tests independently from the Resend payload shape.
- Resend-specific parsing/routing is covered by controller/parser tests.
- `dev check` passes.

## Open Business Decisions

None for this slice.

Deferred decisions:

- Exact future address shape for channels/sub-groups, such as `everyone@kmc.clubs.memba.io`.
- Whether the long-term default address should remain `<club-slug>@clubs.memba.io` or become a channel local-part on the club subdomain.
- How custom club-owned inbound domains will be verified, routed, and presented to members.
- Whether custom domains should be preferred to protect Memba-owned domain reputation.
- Whether replies to message emails should create threaded replies, new club messages, or both depending on context.
- How rich inbound HTML should be sanitised, stored, rendered, and forwarded.
- Whether attachments should be stored and shown, stripped with a warning, or handled by a separate file workflow.
- Whether unknown senders should eventually become public contact messages or access requests instead of rejections.

## Implementation Plan

1. Inspect the existing messaging command flow, membership/person email-address lookup, club slug lookup, outbound email provider flow, Resend webhook controller, router webhook scope, and current acceptance support.
2. Introduce an internal inbound email data structure and command/API in the messaging context that is independent of Resend. Include sender address, recipient addresses, subject, text body, HTML body if present, attachment metadata, provider message id, and provider name.
3. Add destination resolution for `<club-slug>@clubs.memba.io` that finds the club by slug and rejects unsupported recipient addresses or unknown slugs.
4. Add sender resolution that finds a person by any primary or alternate email address.
5. Add active-membership authorization for the resolved sender and destination club.
6. Reuse or wrap the existing web-composed club-message command so accepted inbound email creates the same message, recipients, delivery records, and outbound deliveries as a member-composed message.
7. Add plain-text body normalization:
   - require a non-blank `text/plain` part;
   - ignore `text/html`;
   - do not implement HTML-to-text conversion;
   - strip common signatures and quoted prior-message text;
   - reject if the resulting body is blank.
8. Add attachment rejection before message creation when inbound payload includes any attachments.
9. Add rejection-email delivery for unsupported inbound emails. Use the configured application mailer/provider path where practical, and keep rejection copy concise: reason plus support/contact guidance.
10. Add a Resend inbound webhook route/controller/parser that validates and accepts Resend inbound payloads according to the available Resend payload/signature conventions already used in production configuration.
11. Translate the Resend payload into the provider-neutral inbound email command/API and return provider-appropriate HTTP statuses for accepted webhook receipt versus malformed/unprocessable payloads.
12. Add tests for provider-neutral inbound behaviour:
    - accepted primary address;
    - accepted alternate address;
    - unknown sender rejection;
    - non-member rejection;
    - inactive-member rejection;
    - attachments rejection;
    - missing/blank plain text rejection;
    - HTML-only rejection without conversion;
    - quote/signature stripping;
    - unknown club slug rejection.
13. Add Resend webhook parser/controller tests for realistic inbound payloads, malformed payloads, and rejection paths.
14. Update browser acceptance step support only as needed to express the new `@wip` scenarios after implementation begins.
15. Keep all new acceptance scenarios tagged `@wip` until delivery implements the required step support and application behaviour.
16. Run `dev check`.

## Open Technical Decisions

None expected to block implementation.

Implementation should investigate and decide details for:

- The exact Resend inbound webhook payload fields available for text body, HTML body, attachments, headers, message id, and envelope recipients.
- Whether Resend inbound webhooks require signature verification or share existing webhook verification mechanisms.
- The minimal safe quote/signature stripping approach for plain text. Prefer conservative stripping over complex parsing.
- Whether rejection emails should be sent synchronously during webhook handling or via existing asynchronous delivery paths.
- How to avoid provider retries creating duplicate messages if Resend retries the same inbound webhook. Prefer idempotency based on provider message id where available.

## New Capability

A member can post to the whole club by email, using the club's simple slug-based inbound address. Memba can receive provider inbound email payloads, route them to clubs, authorize senders, create normal club messages, and reject unsupported inbound emails politely.

## Validation Plan

- Run `dev check`.
- Run targeted messaging context tests for the provider-neutral inbound email command/API.
- Run targeted Resend inbound webhook controller/parser tests.
- Run targeted mailer tests for rejection emails.
- Run Cucumber configuration tests to confirm `@wip` scenarios are excluded from the default acceptance run until implemented.
- After implementation removes or narrows `@wip` tags, run the affected Cucumber feature file.
- Manual demo:
  1. Start the app locally with the local/test mailer.
  2. Ensure Kootenay Mountaineering Club has slug `kmc` and Alice is an active member with primary and alternate email addresses.
  3. Submit a realistic Resend inbound webhook payload representing Alice emailing `kmc@clubs.memba.io` with subject `Trip planning night` and a plain-text body.
  4. Confirm the message appears in KMC member views as a normal club message from Alice.
  5. Confirm KMC active members receive outbound club-message email and Nelson Paddling Club members do not.
  6. Submit the same example from Alice's alternate email address and confirm it is posted as Alice.
  7. Submit examples from an unknown sender and from Pat, who is not a KMC member, and confirm no message appears and each sender receives a rejection email.
  8. Submit an example with an attachment and confirm it is rejected with an attachment-not-supported email.
  9. Submit an HTML-only example and confirm it is rejected with a plain-text-required email.
  10. Submit an example with quoted content/signature and confirm only the new message text appears in the posted club message.

## Risks / Follow-ups

- Resend inbound webhook support may have payload or verification details that differ from the current outbound/delivery-status assumptions. Keep the Resend-specific parser isolated.
- Inbound webhooks may be retried. Without idempotency, duplicate emails could create duplicate club messages.
- Quote/signature stripping can easily become too aggressive or too weak. Keep this conservative and covered by examples.
- Rejection emails can create backscatter if sent to spoofed senders. This is acceptable for the first slice only if the implementation uses provider guidance and avoids replying to obviously invalid automated senders where practical.
- Ignoring HTML is a deliberate short-term simplification. A later rich-content iteration should preserve, sanitise, render, and forward safe HTML rather than adding throwaway HTML-to-text conversion now.
- Attachments are rejected for now. A later iteration should decide storage, scanning, visibility, and delivery semantics.
- Future channel/sub-group addressing and custom club-owned inbound domains may change address generation and routing.
