# Migrate production email to Postmark

Date: 2026-06-02
Status: merged

## Goal

Make Memba ready to switch all production email from Resend to Postmark, including inbound club messages that could not be proven with the current Resend domain/account setup.

After this iteration, Matt can manually cut production over to Postmark for member-message outbound delivery, inbound club-message email, rejection emails, and magic-link authentication using a documented runbook, while keeping Resend available as a rollback/fallback provider.

## Background / Context

Iteration 008 added Postmark-backed outbound member-message delivery and Postmark delivery-status webhook handling. Postmark approval was still pending at the time, so ADR 0016 introduced Resend as a first-class switchable provider for production-like testing.

Iteration 019 is the current delivery slice for inbound club messages by email. It deliberately proves inbound email with Resend first while keeping the application-side inbound email API provider-neutral enough for Postmark to replace or supplement Resend later.

Postmark has now been approved. The original product plan was to finish iteration 019 with Resend, observe that incoming messages work, then migrate production email to Postmark. During production smoke-test preparation we found the current Resend setup cannot receive `clubs.memba.io` without changing or upgrading the Resend domain configuration. Matt approved proceeding directly to Postmark inbound setup while preserving Resend as a fallback for the code paths that already work.

## Scope

### In scope

- Add or complete Postmark inbound email support for club-message emails sent to `<club-slug>@clubs.memba.io`, for example `kmc@clubs.memba.io`.
- Keep the member-facing inbound club-message address unchanged during the provider migration.
- Translate Postmark inbound email payloads into the same provider-neutral inbound email command/API introduced for Resend in iteration 019.
- Preserve iteration 019's accepted and rejected inbound-message behaviours for Postmark payloads: sender lookup, active-membership authorization, attachment rejection, plain-text requirement, quote/signature stripping, and rejection email delivery.
- Ensure provider retry/idempotency handling works for Postmark inbound payloads using the provider message id or equivalent stable identifier.
- Confirm outbound member-message delivery can be selected with `MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark` and still sends the required Postmark metadata for delivery-status correlation.
- Confirm magic-link authentication email can be selected with `MEMBA_AUTH_EMAIL_PROVIDER=postmark` and uses the dedicated Postmark authentication message stream.
- Confirm rejection emails sent by inbound club-message handling use the configured real email provider and work when Postmark is selected.
- Update operational documentation and human todo/runbook material for Matt's manual production cutover: Postmark message streams, inbound domain/MX setup, webhook setup, Fly secrets, smoke tests, monitoring checks, and rollback to Resend.
- Update ADR/documentation as needed to record Postmark as the intended primary provider while keeping Resend as a supported fallback.
- Add automated tests for Postmark inbound parsing/translation and provider-selection/configuration behaviour.
- Keep local development and automated tests deterministic by default; no real provider sends unless explicitly configured.
- Keep `dev check` green.

### Out of scope

- Actually changing production Fly secrets, DNS/MX records, or provider dashboard settings during delivery. Matt will perform the production cutover manually using the runbook.
- Changing the member-facing inbound address away from `<club-slug>@clubs.memba.io`.
- Changing the business rules for who may post by email or how unsupported inbound emails are rejected.
- Adding new inbound email features: replies, threading, attachments, HTML preservation/conversion, channels/sub-groups, moderation, or custom club-owned inbound domains.
- Removing Resend support from the codebase.
- Switching automated acceptance tests to call real Postmark APIs.
- Webhook authentication/signature verification unless it is already part of the existing provider-specific implementation and can be preserved without expanding the slice.
- Designing new email templates or changing member-facing email copy except where provider-specific configuration requires it.

## Iteration Type

Technical/engineering.

The intended user-observable behaviour does not change. Members keep using the same club inbound address, message delivery behaviour, rejection rules, and magic-link sign-in flow. The slice changes provider plumbing, configuration, tests, and operational documentation so production can move from Resend to Postmark safely.

## Acceptance Scenarios / Feature Files

BDD decision: Not useful for this slice.

The stakeholder-visible behaviours are already or will be expressed by existing acceptance scenarios, especially the iteration 019 inbound club-message scenarios in `acceptance-tests/features/member_message_deliverability.feature` and existing member-message delivery/auth behaviours. This iteration should prove that the same behaviours work when the configured provider is Postmark rather than Resend. Provider payload parsing, configuration, and cutover runbooks are better covered by focused integration/unit tests and a manual smoke-test checklist than by adding new stakeholder-readable Gherkin.

## Acceptance Criteria

- Postmark inbound email payloads addressed to `<club-slug>@clubs.memba.io` are parsed and translated into the same provider-neutral inbound email data structure/command used by Resend.
- A Postmark inbound email from an active member to `kmc@clubs.memba.io` creates the same KMC club message, audience, delivery records, and outbound sends as the equivalent Resend inbound email.
- Postmark inbound emails from unknown senders, inactive members, and known people who are not active members of the destination club are rejected without creating a club message and trigger the same polite rejection email behaviour as Resend.
- Postmark inbound emails with attachments are rejected consistently with iteration 019's unsupported-attachment rule.
- Postmark inbound emails with no usable plain-text body after quote/signature stripping are rejected consistently with iteration 019's plain-text-required rule.
- Postmark inbound retry/idempotency behaviour prevents duplicate club messages when the same provider message is delivered more than once.
- Outbound member-message Postmark configuration still sends metadata/custom fields for `memba_message_id`, `memba_delivery_id`, and `memba_club_id` so Postmark delivery-status webhooks correlate to existing delivery records.
- Postmark delivery-status webhooks remain distinct from Postmark inbound-email webhooks in routing, documentation, and tests.
- Auth magic-link Postmark configuration requires the server token, auth from address, and dedicated auth message stream, and fails clearly when selected but incomplete.
- Rejection emails sent by inbound club-message handling work when the selected real provider is Postmark.
- Resend remains selectable for member-message delivery, auth email, and inbound handling so Matt can roll production back if the Postmark cutover fails.
- Documentation names the exact environment variables/secrets Matt must set or change for the Postmark cutover and the exact Resend variables/secrets to restore for rollback.
- Documentation names the required Postmark dashboard/DNS setup for outbound member broadcasts, auth magic links, inbound email routing for `clubs.memba.io`, and delivery-status webhooks.
- Documentation includes a manual smoke-test script that proves auth email, outbound member-message email, inbound club-message email, rejection email, delivery-status webhook processing, and rollback readiness.
- Routine local development and automated tests do not send real Postmark or Resend email by default.
- `dev check` passes.

## Open Business Decisions

None known.

Decisions made during planning:

- Switch all production email paths to Postmark, not only club-message email.
- Keep `<club-slug>@clubs.memba.io` unchanged as the member-facing inbound address.
- Delivery should prepare code and documentation only; Matt will perform production provider/DNS/secrets changes manually.
- Keep Resend support as a tested fallback rather than removing it.

## Implementation Plan

1. Start after iteration 019 is delivered. Do not require manual Resend inbound observation before proceeding; Matt approved moving directly to Postmark after production setup showed the current Resend domain/account cannot receive `clubs.memba.io` without further provider changes.
2. Inspect iteration 019's provider-neutral inbound email API, idempotency model, rejection-email path, Resend inbound parser/controller, provider selection, and tests.
3. Inspect existing Postmark outbound member-message provider, Postmark delivery-status webhook controller, auth email Postmark configuration, and `docs/postmark-email.md`.
4. Determine the cleanest Postmark inbound routing shape. Prefer keeping inbound-email handling separate from outbound delivery-status webhooks if Postmark's dashboard supports separate inbound and delivery-status webhook URLs; otherwise make the shared Postmark route dispatch safely by payload shape.
5. Add a Postmark inbound parser/controller/dispatcher that maps realistic Postmark inbound payload fields to the provider-neutral inbound email structure: provider name, provider message id, sender, recipients, subject, plain text, HTML body if present, attachment metadata, and useful headers.
6. Reuse iteration 019's provider-neutral command/API for all accepted/rejected behaviour rather than duplicating business rules in Postmark-specific code.
7. Add Postmark inbound idempotency support using the stable provider message id or equivalent payload field.
8. Add tests for Postmark inbound payload parsing and controller/dispatcher behaviour, including accepted primary-address sender, alternate-address sender where practical, rejection cases, attachments, HTML-only/missing plain text, and duplicate retry handling.
9. Verify or add tests proving Postmark outbound member-message payloads still include sender/reply-to, text/HTML bodies, and correlation metadata expected by the Postmark delivery-status webhook handler.
10. Verify or add tests proving Postmark auth email configuration uses `MEMBA_AUTH_EMAIL_PROVIDER=postmark`, `MEMBA_POSTMARK_SERVER_TOKEN`, `MEMBA_AUTH_EMAIL_FROM_ADDRESS`, and `MEMBA_AUTH_EMAIL_MESSAGE_STREAM`, and fails clearly when incomplete.
11. Verify rejection-email delivery follows the configured mailer/provider path and works when Postmark is selected.
12. Update `docs/postmark-email.md` to describe the full Postmark production setup: outbound member-message stream, auth stream, inbound club-message routing for `clubs.memba.io`, delivery-status webhook URL, inbound webhook URL, environment variables, and local smoke-test guidance.
13. Update `docs/human-todo.md` or add a runbook under this iteration folder with Matt's manual cutover steps, smoke tests, monitoring checks, and rollback steps to Resend.
14. Update ADR/documentation as needed to reflect that Postmark is the intended primary production provider after approval, while Resend remains a first-class fallback.
15. Run targeted tests for Postmark inbound, Resend inbound regression, Postmark outbound delivery, auth email configuration, and provider selection.
16. Run `dev check`.

## Open Technical Decisions

Implementation should investigate and decide:

- The exact Postmark inbound webhook payload shape and which field is the best stable provider message id for idempotency.
- Whether Postmark inbound email and delivery-status events should use two separate routes or one dispatching route, based on Postmark configuration capabilities and the existing `/webhooks/postmark` controller.
- The exact Postmark inbound domain/MX setup needed to preserve `<club-slug>@clubs.memba.io`.
- Whether Postmark inbound webhooks provide attachment metadata without downloading attachments, and how to detect attachments early enough to preserve the iteration 019 rejection rule.
- Whether any provider-specific inbound authentication is available and already configured; do not expand into a security iteration unless small and non-disruptive.

## New Capability

Memba can receive, send, and operationally validate all production email paths through Postmark while preserving Resend as a fallback. Matt has a concrete runbook for a manual production cutover and rollback.

## Validation Plan

- Run focused tests for Postmark inbound payload parsing/translation.
- Run focused tests for provider-neutral inbound command/API regressions from iteration 019.
- Run focused tests for Resend inbound parsing to confirm fallback support still works.
- Run focused tests for Postmark outbound member-message payload metadata and delivery-status webhook correlation.
- Run focused tests for Postmark auth email configuration and missing-config errors.
- Run `dev check`.
- Manual cutover smoke test from the runbook after Matt changes production configuration:
  1. Confirm Postmark outbound member-message stream, auth stream, inbound routing for `clubs.memba.io`, and webhooks are configured.
  2. Set production secrets to select Postmark for member-message delivery and auth email.
  3. Send a magic link to a controlled inbox, confirm receipt from the Postmark auth sender, and sign in successfully.
  4. Send a member message from the web UI, confirm Postmark accepts and delivers it, and confirm delivery-status webhook updates Memba.
  5. Email `kmc@clubs.memba.io` from an active member address, confirm Memba creates and distributes the club message.
  6. Email `kmc@clubs.memba.io` from an unsupported sender or with an unsupported attachment, confirm no club message is created and the rejection email is delivered through Postmark.
  7. Confirm Resend rollback instructions are complete and the required Resend secrets/webhooks are still available.

## Risks / Follow-ups

- Postmark inbound payloads may differ enough from Resend that the provider-neutral API needs small adjustments. Keep changes provider-neutral and preserve Resend tests.
- Inbound domain/MX setup for `clubs.memba.io` may require DNS/provider dashboard work that cannot be completed by code delivery alone; document it clearly for Matt's manual cutover.
- Production cutover risk includes missed MX propagation, webhook misconfiguration, missing secrets, or sender-domain reputation issues. The runbook and rollback path mitigate this.
- Webhook authentication remains a known follow-up security concern from ADR 0016 and the provider webhook authentication kaizen note.
- Keeping both providers increases maintenance cost, but it is valuable while Memba is still proving deliverability and provider fit.
