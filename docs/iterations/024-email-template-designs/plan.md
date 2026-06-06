# Transactional email template redesign

Date: 2026-06-06
Status: ready

## Goal

Incorporate the new email design packet from `~/Downloads/Memba.zip` into Memba's transactional emails, so sign-in links, member messages, and inbound-message rejection notices use the v2 branded, mobile-friendly templates.

The implementation should preserve deliverability and plain-text readability while making emails feel trustworthy to older members using iPads and other common mail clients.

## Background / Context

Matt provided a zip packet in Downloads containing new Memba email designs. The relevant v2 design artifacts have been copied into this iteration folder so Fabro's clone-based delivery sandbox can access them:

- `source/email-system-spec-v2.html`
- `source/sign-in-link-v2.html`
- `source/member-message-v2.html`
- `source/inbound-rejection-v2.html`

The design spec's central rule is:

> Memba is ambient inside a club, and steps forward only between clubs.

Applied to this iteration:

- Member messages are club-led: the sender/club leads; Memba is the carrier.
- Sign-in links are club-led where possible, with a clear Memba trust mark because phishing reassurance matters.
- Inbound rejection notices are Memba-led delivery notices, but name the club up front.
- Plain-text twins remain required.
- Email HTML should be compatible and simple: single-column, table-oriented, inline styles, real text, bulletproof buttons, printed fallback links for sign-in.

Current email code uses very plain generated HTML:

- `Memba.Accounts.AuthEmail` builds shared sign-in-link emails.
- `Memba.Messaging.EmailDeliveryProviders.Postmark` and `Memba.Messaging.EmailDeliveryProviders.Local` build member-message emails.
- `Memba.Messaging.InboundClubRejectionEmail` builds inbound rejection notices.
- `Memba.Onboarding.WelcomeEmail` builds welcome/sign-in emails for converted onboarding requests.

## Scope

### In scope

- Add a reusable transactional email rendering structure or helpers that keep HTML templates maintainable and safe.
- Implement the v2 visual/content system for sign-in-link emails.
- Preserve sign-in-link plain-text email bodies with the raw URL printed clearly.
- Where a sign-in link is for a known club/member context, use the club-led variant from the design direction.
- Where a sign-in link is cross-club or staff/global context, keep Memba-led or Memba-trust-forward copy that fits the same design system.
- Implement the v2 member-message email template for both Postmark and local/Swoosh delivery paths.
- Keep member-message From/Reply-To semantics intact:
  - From display name continues to make the sender and Memba carrier clear.
  - Reply-To goes to the real sender, not the whole group.
- Implement the v2 inbound rejection email template.
- Update rejection reason copy to match the spec's plain-language reason strings where this does not change policy.
- Preserve inbound rejection threading headers and provider metadata/tags.
- Apply a compatible template direction to onboarding welcome emails, likely as a sign-in/welcome variant, so the newly-created group welcome email does not remain visually inconsistent.
- Add or update unit tests for generated email subjects, From/Reply-To, provider metadata/tags, plain text bodies, HTML bodies, fallback URLs, and key trust/support copy.
- Use Canadian English and broader small-community-group language established in iteration 023 where copy is not dictated by the design packet.
- Keep `dev check` green.

### Out of scope

- Changing email provider selection, DNS, DKIM, DMARC, Postmark/Resend configuration, or production sending domains.
- Implementing per-group custom sender domains; the spec explicitly treats that as a premium upgrade, not default behaviour.
- Adding unsubscribe preferences or subscription management beyond any existing headers/policy.
- Changing who can send messages, who receives messages, inbound authorization policy, sign-in-token lifetime, or rejection policy.
- Adding new email types beyond the existing auth, member-message, inbound-rejection, and onboarding-welcome emails.
- Full i18n/localization plumbing.
- Pixel-perfect rendering guarantees in every email client.
- Public website copy changes from iteration 023.

## Iteration Type

Behaviour-facing copy/design iteration.

The domain rules do not change, but users observe changed email content and email HTML. The important behaviour invariants are that sign-in links still authenticate securely, member-message replies still go to the sender rather than the whole group, and inbound rejection notices still clearly explain that nothing was posted.

## Acceptance Scenarios / Feature Files

BDD decision: Useful but not required.

Existing acceptance scenarios already exercise sign-in links, member-message delivery, inbound-message handling, and onboarding welcome links. New Gherkin would mostly assert email presentation details and would be brittle.

No shared Cucumber feature files are expected to change. Existing coverage that may observe email content includes `acceptance-tests/features/authentication.feature`, `acceptance-tests/features/member_message_deliverability.feature`, `acceptance-tests/features/request_account.feature`, and `acceptance-tests/features/member_club_subdomains.feature`. If those scenarios or step support assert old email text, update only the assertions/step support needed to preserve the same behaviour coverage while reflecting the new user-visible copy.

## Acceptance Criteria

- The v2 design artifacts from the Downloads zip are available in the repository under this iteration folder for implementation reference.
- Sign-in-link HTML email uses the v2 design system: single-column card, clear primary button, printed fallback URL, expiry/one-use reassurance, and Memba trust mark.
- Sign-in-link text email remains readable and includes the sign-in URL, expiry, one-use reassurance, and ignore-if-unrequested guidance.
- Sign-in-link subjects and headings are appropriate for context:
  - club/member context leads with the group name where available;
  - global/staff/cross-club context remains clearly Memba-led.
- Member-message HTML email uses the v2 member-message pattern: group-led header, sender-to-members line, readable message body, reply guidance, and Memba-as-carrier footer.
- Member-message text body remains exactly the sender's original message body. Reply guidance and Memba footer are added only to the HTML part in this iteration.
- Member-message From, Reply-To, subject, provider metadata, and local-delivery fact recording continue to work.
- Inbound rejection HTML email uses the v2 delivery-notice pattern: Memba-led, names the group when known, gives one plain reason, gives next steps, and says nothing was sent to the group.
- Inbound rejection text email remains readable and includes the same reason and next-step information.
- Inbound rejection subjects lead with the group when known, e.g. "Your email to {group} wasn't posted", and fall back to a Memba-led subject such as "Your email wasn't posted" when group context is unavailable, while preserving reply threading where needed.
- Existing rejection reasons map to plain-language copy from the design spec or a close equivalent:
  - attachments unsupported;
  - plain text required;
  - unknown sender;
  - sender not active member;
  - unknown group/address;
  - unsupported recipient;
  - fallback unknown failure.
- Onboarding welcome email uses a compatible v2 sign-in/welcome pattern and no longer has bare HTML.
- HTML escapes all user-, sender-, message-, and group-provided content safely, including message bodies containing HTML or script-like text.
- Email header values built from user-, sender-, or group-provided content are sanitized so newlines/control characters cannot break headers.
- Sign-in links without group context use a Memba-led subject and heading such as "Sign in to Memba"; sign-in links with group context use a group-led subject/heading.
- Tests cover generated HTML enough to catch regressions in the key structural/copy promises without snapshotting the entire template.
- `dev check` passes.

## Open Business Decisions

None known.

Design and implementation decisions already captured by the packet and this plan:

- Default email sending remains from the currently configured Memba-controlled sender addresses/domains. This iteration may change display names and email body copy, but must not change provider configuration, DNS, or configured `from` address values.
- Per-group custom domains are not part of this iteration.
- Memba is the carrier inside a group and leads only where it is the cross-group account or delivery-notice actor.
- Implement shared rendering helpers in a new module under `web/lib/memba/email_templates.ex` (module name `Memba.EmailTemplates`) unless implementation discovers a Phoenix naming constraint; keep the public email-delivery APIs in the existing modules.
- Member-message plain-text bodies remain exactly the sender's original body. HTML may add reply guidance and the Memba footer.
- `Memba.Accounts.AuthEmail.deliver_sign_in_link/2` keeps working. Add an optional context/options variant such as `deliver_sign_in_link/3` for group-led sign-in emails where the caller can supply group name/context. Existing callers with no context remain Memba-led.
- `Memba.Onboarding.WelcomeEmail` uses the group-led sign-in/welcome variant because it already has club context.
- Do not hard-code `help@memba.io`. Support/next-step copy should say "reply to this email" when a reply-to address is configured, or use generic support wording that does not publish an unconfirmed mailbox.
- The implementation should use group/community language where possible, while preserving existing domain/module names such as `club` in code unless a later product-domain iteration changes them.

## Implementation Plan

1. Inspect the v2 source artifacts in `docs/iterations/024-email-template-designs/source/` and current email-building modules/tests.
2. Add shared helper module `web/lib/memba/email_templates.ex` (`Memba.EmailTemplates`) for the email HTML shell/components and text-safe helpers. Keep inline styles and avoid external CSS dependencies.
3. Implement safe helpers in `Memba.EmailTemplates` for:
   - escaping user/group/sender/message content;
   - sanitizing header text derived from user/group/sender content;
   - converting plaintext message bodies to email-safe HTML;
   - rendering a primary button plus fallback URL;
   - rendering group-led and Memba-led headers;
   - rendering the Memba footer/trust footer without hard-coded unconfirmed support addresses.
4. Update `web/lib/memba/accounts/auth_email.ex` to render the new sign-in template while preserving provider options and error handling. Keep `deliver_sign_in_link/2`; add an optional context/options variant for group-led sign-in where callers can provide group name/context.
5. Update sign-in call sites only where group context is already available or cheaply derivable, such as club-subdomain sign-in. When no group context is available, keep the Memba-led sign-in subject/heading.
6. Update `web/lib/memba/onboarding/welcome_email.ex` to use the compatible group-led welcome/sign-in variant and pass the converted club as context.
7. Update member-message delivery HTML in `web/lib/memba/messaging/email_delivery_providers/postmark.ex` and `web/lib/memba/messaging/email_delivery_providers/local.ex`, extracting shared rendering so both paths stay aligned. Keep plain-text member-message bodies exactly as the sender wrote them.
8. Update `web/lib/memba/messaging/inbound_club_rejection_email.ex` to use the new delivery-notice template, subject rules, reason copy, next-step copy, threading headers, and metadata.
9. Update tests, especially:
   - `web/test/memba/accounts/auth_email_test.exs` for auth email Postmark/Resend/local provider options, HTML/text content, fallback URL, escaping, and context/no-context variants;
   - `web/test/memba/onboarding_conversion_test.exs` or a focused onboarding email test for welcome email link and group-led content;
   - existing member-message provider tests, or add focused tests near `web/test/memba/messaging/email_delivery_providers/`, for member-message HTML, unchanged text body, From/Reply-To, subject, metadata, and local delivery facts;
   - existing inbound email/rejection tests, or add `web/test/memba/messaging/inbound_club_rejection_email_test.exs`, for reason text, HTML, subject fallback, threading, and metadata/tags;
   - escaping/header-safety tests for group names, sender names, subjects, and message bodies with HTML/script-like text or newlines.
10. Run targeted email-related tests while developing.
11. Run any affected acceptance tests if mailbox text parsing changes.
12. Run `dev check`.
13. Record implementation notes and any deliberate deviations from the supplied designs in this iteration folder.

## Open Technical Decisions

None known.

## New Capability

Memba transactional emails will look and read like a coherent product system: group-led where members are interacting with their group, Memba-led where Memba is the carrier or account/trust actor, and consistently readable on iPads and common email clients.

## Validation Plan

- Compare generated emails against the v2 source artifacts for semantic structure and copy hierarchy, not pixel-perfect browser-prototype fidelity.
- Confirm sign-in email HTML includes a primary button with `href`, a printed fallback URL, expiry/one-use reassurance, and the Memba trust mark.
- Confirm member-message HTML includes group-led header, sender-to-members line, escaped message body, reply guidance, and Memba carrier footer, while the text body remains exactly the sender's body.
- Confirm inbound rejection HTML includes Memba-led header, group name if known, one reason line, next steps, and reassurance that nothing was posted.
- Unit-test email fields, provider options, text bodies, key HTML content, escaping, header sanitization, fallback links, and reason mappings.
- Use local Swoosh mailbox previews during implementation to manually inspect:
  - sign-in link;
  - onboarding welcome link;
  - member message;
  - inbound rejection notice.
- If practical, inspect at desktop and mobile/iPad-like widths in the browser mailbox.
- Run `dev check` before completion.

## Risks / Follow-ups

- Email-client compatibility is easy to regress if templates use modern web CSS too literally. Implementation should translate the design into conservative email HTML rather than copy every browser-only style from the prototypes.
- Exact design fidelity may need a follow-up after real mailbox screenshots from Gmail, Apple Mail, Outlook, and Fastmail.
- Some ordinary sign-in requests may remain Memba-led when the current flow has no reliable group context; this is acceptable for this iteration and is covered by the no-context fallback acceptance criteria.
- If Matt later wants to publish a support mailbox in email templates, confirm the mailbox/support process first and add it in a small follow-up.
- A later i18n iteration can move copy strings behind locale-aware rendering.
