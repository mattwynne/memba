# Auth email delivery progress

Date: 2026-06-13
Status: ready

## Goal

Make the sign-in-link waiting experience less frustrating by showing neutral, live delivery progress for authentication emails, including when the recipient mailbox provider has accepted the email, without revealing whether an email address is known to Memba.

## Background / Context

Sign-in links need to feel instant. Recent production investigation found that Memba can create the token and hand the email to Postmark quickly, while Postmark-to-Fastmail/MessagingEngine delivery can sometimes take tens of seconds or several minutes. The current `/auth/check-email` page immediately tells people to check their inbox, even when Postmark has not yet delivered the message to the recipient's mailbox provider.

Memba already has architectural precedent for live UI updates from committed read-model state:

- ADR 0021 publishes committed read-model changes through Phoenix PubSub.
- ADR 0022 distinguishes read-model change notifications from projection barriers.
- Existing delivery-status LiveViews subscribe to read-model changes and refresh from persistence.

This iteration applies the same pattern to auth-email delivery progress.

## Related Problems

- [Check email page should update after sign-in in another browser](../../problems/2026-06-06-auth-check-email-auto-update-after-sign-in.md) — Partially addressed / depends on the same LiveView/PubSub surface. This iteration updates the check-email page for email-delivery progress, but does not require detecting that the user completed sign-in in another browser.
- No existing problem note specifically captures slow sign-in-link email delivery. The plan is based on production evidence from prior session `pi:019e95e5` and current Postmark/Fastmail inspection showing accepted-to-delivered delays on the auth stream.

## Scope

### In scope

- Persist a short-lived auth-email request/progress record for every submitted email address, including unknown addresses, so the browser always receives an opaque request ID and the UI shape does not reveal account existence.
- For recognized sign-in recipients, correlate the auth email sent through Postmark with the auth-email request by provider metadata.
- Extend Postmark webhook handling for auth-stream delivery events so Memba records when the recipient mailbox provider accepts the auth email.
- Publish committed auth-email progress changes through the existing Phoenix PubSub/read-model-change pattern.
- Change the check-email route to include an opaque request ID and render a LiveView that refreshes progress without page reload.
- Keep user-facing copy honest: Memba may say the mailbox provider accepted the email; it must not claim the email is visible in the inbox.
- Preserve anti-enumeration behaviour: known and unknown email submissions must have the same route shape and neutral wording.
- Add tests for recognized, unknown, delayed, failed, and no-webhook fallback behaviour.

### Out of scope

- Guaranteeing inbox placement or detecting spam/junk placement.
- Surfacing Postmark internal queue/retry details that Postmark does not expose through its API/webhooks.
- Changing the Postmark provider, sender domain, DNS, or Fly machine sleep settings.
- Solving the separate cross-browser/session problem where the check-email page updates after the user signs in elsewhere.
- Showing recipient email addresses or account-existence-specific messages on the progress page.
- Building a staff/operator dashboard for auth email delivery history.

## Iteration Type

Behaviour-facing.

The user-observable rule changes from “after submitting an email, immediately tell the person to check their inbox” to “after submitting an email, show neutral progress while Memba sends the sign-in email and, when available, show that the recipient mailbox provider accepted it.”

The privacy rule remains unchanged: the sign-in flow must not reveal whether Memba recognizes the submitted email address.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

The slice changes user-visible authentication behaviour and includes a security/privacy rule. The relevant shared feature file is:

- `acceptance-tests/features/authentication.feature`

New scenarios are planned under `@iteration-032 @todo-domain @todo-ui` while the implementation and step support are future-facing:

- `Alice sees when her mailbox provider accepts the sign-in email`
- `Robin sees the same neutral waiting experience for an unknown email address`

These scenarios describe the business rules without naming LiveView, PubSub, Postmark, routes, CSS selectors, or database details.

## Allowed acceptance feature changes

- `acceptance-tests/features/authentication.feature`: add the planned `@iteration-032 @todo-domain @todo-ui` scenarios for auth email delivery progress and privacy-preserving unknown-email behaviour. The tags keep planning-time checks green until implementation adds matching behaviour and step support.
- During implementation, remove or narrow `@todo-domain` and `@todo-ui` only when the scenarios pass in the relevant runner. Preserve the `@iteration-032` tag.

## Acceptance Criteria

- Submitting a known sign-in email creates a short-lived auth-email request/progress record and redirects or patches to a check-email page identified by an opaque request ID.
- Submitting an unknown email creates an indistinguishable opaque request/progress experience from the user's point of view, without sending an email.
- Known and unknown submissions use the same route shape and neutral copy so a user cannot infer account existence from the URL, initial page, or timing-sensitive first response.
- The sign-in email sent through Postmark includes metadata that can correlate delivery webhooks to the auth-email request without exposing sensitive data in the UI.
- When Postmark reports that the recipient mailbox provider accepted the auth email, Memba records that state and the check-email page updates live.
- The page uses careful wording such as “Your mailbox provider has accepted the email. It should appear shortly.” It must not say “the email is in your inbox.”
- If no provider-accepted event arrives within a short period, the page falls back to neutral guidance to check inbox/junk and ask for another link later.
- Postmark delayed, bounced, spam complaint, malformed, duplicate, and missing-correlation webhook events are handled safely without crashing and without revealing account existence to the requester.
- Existing sign-in-link behaviour still works: known members and staff can sign in; unknown people cannot; links remain one-use and expiring.

## Open Business Decisions

- Exact progress copy and timing thresholds need final wording during implementation. Suggested states:
  - “Preparing your sign-in link…”
  - “If this email can sign in, the link is on its way.”
  - “Your mailbox provider has accepted the email. It should appear shortly.”
  - “If it does not arrive, check junk mail or ask for another link.”
- Whether unknown-email requests should display simulated progress for a fixed minimum duration or immediately show the same neutral “on its way” copy. Default recommendation: keep the first response and page shape identical, and avoid long artificial waits.

## Implementation Plan

1. Inspect the existing auth LiveView, auth email module, Postmark webhook controller, read-model change publisher, and current delivery-status LiveViews that subscribe to read-model changes.
2. Add a small persistence model for auth-email requests/progress, with an opaque public request ID, normalized internal email only where needed, status, provider message/correlation data, timestamps, and expiry/cleanup considerations.
3. Update the sign-in request flow so every submitted address creates an opaque request/progress record before navigation.
4. For recognized recipients, send the auth email with Postmark metadata linking it to the auth request. For unknown recipients, do not send email but keep the request's public status neutral.
5. Change `/auth/check-email` to use an opaque request ID, with backward-compatible handling for any old route if needed.
6. Add LiveView progress rendering and subscription. Refresh from persistence after receiving committed-change notifications.
7. Extend Postmark webhook handling to route auth-stream delivery/problem events to auth-email progress updates without weakening member-message delivery-status handling.
8. Publish auth-email progress changes after the relevant DB update commits, using the ADR 0021 pattern. If the auth progress record is not a Commanded projection, use a small committed-update publisher with the same PubSub discipline and document why it is not a projector.
9. Add tests for known/unknown submissions, metadata, webhook correlation, duplicate webhook idempotency, live update behaviour, and privacy-preserving copy.
10. Implement or update acceptance step support for the `@iteration-032` scenarios, then remove/narrow `@todo-domain`/`@todo-ui` when they pass.

## Open Technical Decisions

- Whether auth-email progress should be modelled as a simple Ecto source-of-truth table or as a small event-sourced/projection flow. Default recommendation: simple Ecto table, because auth-email request progress is operational/session state rather than core domain history.
- Whether to publish through `Memba.ReadModelChanges` directly or add `Memba.AuthEmailProgressChanges` with a narrower topic. Default recommendation: reuse the committed-change pattern and topic discipline, but keep payloads narrow enough for the auth LiveView to filter by request ID.
- How long to retain auth-email request records. Default recommendation: short retention aligned with sign-in token expiry plus enough time for webhook retries and diagnostics.
- How to handle old `/auth/check-email` without a request ID. Default recommendation: render the existing neutral static guidance or redirect to `/auth` rather than inventing progress.

## New Capability

A person waiting for a sign-in link can see neutral live progress and, when Postmark reports success, know that their mailbox provider accepted the email. Memba gains an auditable correlation point for auth-email delivery latency without compromising account-enumeration protection.

## Validation Plan

- Run targeted unit/context tests for auth-email request persistence and status transitions.
- Run Postmark auth-email construction tests to prove metadata includes the opaque request correlation and uses the `outbound-authentication` stream.
- Run Postmark webhook controller tests for auth-stream delivered, delayed, bounced, spam complaint, duplicate, malformed, and missing-correlation events.
- Run LiveView tests proving the check-email page renders neutral initial state, updates after a committed provider-accepted status, and does not disclose account existence for unknown requests.
- Run the updated authentication Cucumber scenarios after removing/narrowing `@todo-domain`/`@todo-ui` during implementation.
- Run `dev check` before completion.
- Manual smoke test in production or a staging-like environment:
  1. Request a sign-in link for a known controlled address.
  2. Watch the check-email page progress.
  3. Confirm Postmark records the auth message and delivery event.
  4. Confirm the page shows mailbox-provider acceptance, not inbox-placement certainty.
  5. Request a link for an unknown controlled address and confirm the UI remains neutral.

## Risks / Follow-ups

- Provider webhooks may arrive after the user has left the page; persistence and idempotency matter more than transient PubSub delivery.
- Mailbox-provider acceptance still does not guarantee inbox placement, so copy must avoid overclaiming.
- Artificially simulating unknown-email progress could create confusing waits; keep the anti-enumeration goal balanced against usability.
- This iteration may make it easier to later resolve the cross-browser signed-in update problem, but that should remain a separate slice unless implementation discovers a very small shared hook.
- If Postmark auth delivery latency remains high, a later operational iteration should compare provider behaviour, sender reputation, DMARC policy, and dedicated IP/stream options.
