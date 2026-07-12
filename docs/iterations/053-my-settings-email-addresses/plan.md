# My settings email-address management

Date: 2026-07-11
Status: ready

## Goal

Add global signed-in Person settings at `/my/settings`, reached from the club-site avatar menu as **Account settings**, so members can review their profile basics and manage their own email addresses safely.

After this iteration, a signed-in member can:

- open Account settings from the avatar menu;
- see their Person name and current club memberships;
- see which email address is primary and which addresses are verified or pending verification;
- add a new pending email address and receive a verification link;
- resend verification for a pending address;
- verify a pending address by opening the emailed link;
- make a verified non-primary address primary immediately;
- remove a non-primary address.

The session remains a signed-in Person session, not an email-address session. Verifying or removing the email address that originally started the session does not disturb the current session.

## Background / Context

Iteration 016 introduced multiple email addresses per Person with exactly one primary address for outbound club messages, but member-facing display and editing were deferred. The current projection records `email`, `normalized_email`, and `is_primary`; it does not yet model verified/pending state. Staff-facing edit flows can attach alternate addresses without proof that the person controls them.

This iteration adds the missing member-facing management surface and makes email-address verification explicit. Existing addresses are backfilled as verified so current members are not locked out. Newly added addresses start pending verification and cannot be used for primary delivery, sign-in identity, or inbound-message identity until verified.

User-facing copy may use the familiar phrase **Account settings**, but implementation and domain language should not introduce a new Account aggregate or bounded context. The domain model remains signed-in identity, Membership Person, Person email addresses, and Memberships.

## Related Problems

- [`docs/problems/2026-06-08-person-alternate-email-verification-missing.md`](../../problems/2026-06-08-person-alternate-email-verification-missing.md): **expected to resolve for the current Person email-address model.** New addresses become pending until the person proves mailbox control. Pending addresses cannot become primary or identify inbound mail.
- [`docs/problems/2026-07-11-unverified-email-inbound-rejection-confusion.md`](../../problems/2026-07-11-unverified-email-inbound-rejection-confusion.md): **partially addressed / deliberately left as follow-up UX.** This iteration enforces the safe rule that unverified known addresses are rejected for inbound identity. The richer confused-member recovery path and rejection-email UX remain follow-up work.

## Scope

### In scope

- Add a global member settings route at `/my/settings` for signed-in identities that resolve to a Membership Person.
- Add **Account settings** to the club-site avatar dropdown above a horizontal separator and the existing **Sign out** action.
- Render an Account settings page with:
  - page title `Account settings`;
  - read-only Person basics, including name;
  - current club memberships summary;
  - editable email-address section.
- Add verified/pending state for Person email addresses.
- Backfill all existing Person email-address rows as verified.
- Treat any newly added Person email address as pending/unverified, regardless of whether it is added by the member settings flow or an existing staff maintenance path.
- Send a general verification email with copy suitable for either member- or staff-added addresses, e.g. `Verify this email address for your Memba account`.
- Verification links verify the pending address only if it still belongs to the same Person and is still pending.
- Verification success page says: `Email verified, you can close this browser.`
- Expired/invalid verification links show a calm invalid/expired state and do not re-add or verify removed/replaced addresses.
- Publish a read-model/PubSub notification when an address is verified so an open `/my/settings` LiveView updates live.
- Allow resend verification for pending addresses.
- Allow verified non-primary addresses to become primary immediately.
- Changing primary affects future club-message delivery and current UI display immediately.
- Allow removing non-primary addresses, including the address that was used to start the current browser session.
- Prevent removing the current primary address so every Person keeps exactly one primary email address.
- Prevent making pending/unverified addresses primary.
- Prevent pending/unverified addresses from being used for sign-in identity and inbound email identity until verified, except that opening a sign-in link sent to a pending known address may itself verify that address.
- Reject duplicate normalized email addresses already attached to another Person with privacy-safe clear copy: `That email address is already in use by another Memba user.`
- Preserve the current one-normalized-email-address-per-Person assumption.

### Out of scope

- Club settings or any route that implies club-specific settings.
- Introducing an Account aggregate, Account bounded context, or account-specific persistence model separate from the current identity/Person model.
- Settings for signed-in get-started-only identities that do not resolve to a Membership Person; those users stay in the onboarding/request flow.
- Shared/household email addresses or one email address belonging to multiple people.
- Rate limiting, resend throttling, CAPTCHA, or other anti-abuse controls.
- Rich UX for members confused by inbound rejection from an unverified known address, beyond enforcing the safe rejection rule and leaving the follow-up problem note.
- Changing membership names, profile details beyond email addresses, or club membership state.
- Building a new design-system preview in Pi. Claude/DesignSync review may add or refine one before delivery.

## Iteration Type

Behaviour-facing.

The changed user-observable rules are:

- signed-in members have a global personal settings page at `/my/settings`;
- Person email addresses have verified and pending states;
- pending addresses are visible and removable but cannot be primary or identify the member until mailbox control is proven;
- verified non-primary addresses can become primary; and
- the avatar menu now exposes the personal settings route.

## Acceptance Scenarios / Feature Files

BDD decision: **Required.**

The iteration changes member-visible identity and email-address policy: who can add addresses, when an address is trusted, when primary delivery can change, and what happens to pending addresses. These are business rules that benefit from stakeholder-readable examples.

Update [`acceptance-tests/features/person_email_addresses.feature`](../../../acceptance-tests/features/person_email_addresses.feature) with `@iteration-053 @todo-domain @todo-ui` scenarios for this future-facing slice. The project Cucumber profile excludes `@todo-ui`, so the planning scenarios do not make the current build red before implementation.

New/changed scenario summaries:

- Alice opens Account settings from the avatar menu.
- Alice adds and verifies a new email address.
- Alice cannot make a pending email address primary.
- Alice makes a verified alternate email address primary.
- Alice removes a non-primary email address but cannot remove the primary address.
- Alice resends verification for a pending address.
- A removed pending address cannot be verified by an old link.
- Signing in with a pending known address verifies it.
- Inbound email from a pending known address is rejected.

## Allowed acceptance feature changes

- `acceptance-tests/features/person_email_addresses.feature`: add member-facing settings and verification rules/scenarios tagged `@iteration-053 @todo-domain @todo-ui`. Reason: document the new Person email-address verification and self-service management behaviour before implementation. Coverage is intentionally future-facing and excluded from default Cucumber while tagged `@todo-ui`; implementation should remove or narrow the temporary tags when domain/browser support is delivered.

## Designs

This iteration changes visible member surfaces and needs design coverage.

Existing checked-in design sources are sufficient for a first implementation plan, because the page can reuse established member app shell, card, form, badge, avatar-menu, and simple confirmation patterns:

- Club-site app shell and avatar dropdown: `web/lib/memba_web/components/layouts.ex` (`Layouts.club_site/1`, `club-site-identity-menu`).
- Member app chrome and compact personal/avatar treatment: `design-system/wireframes/mobile-club-home.html`.
- Member-management form/card treatment: `design-system/wireframes/invite-a-member.html`.
- Profile/verification completion and calm confirmation page language: `design-system/wireframes/profile-completion.html` plus current auth check-email page styling.
- Existing staff email-address form behaviour for rows, primary selection, add/remove patterns: `web/lib/memba_web/live/admin/people_live/edit.ex`.

No dedicated `/my/settings` design-system card exists yet. Because this plan is authored in Pi, DesignSync is unavailable. Claude Code should review the plan/design decision before delivery and may create a fast-follow design-system preview for `/my/settings` and the verification confirmation page if the checked-in sources above are not enough.

Implementation should keep the UI simple and app-like:

- Avatar menu order: `Account settings`, separator, `Sign out`.
- `/my/settings` title: `Account settings`.
- Email address rows clearly show `Primary`, `Verified`, and `Pending verification` states.
- Pending rows expose `Resend verification` and `Remove` actions.
- Verified non-primary rows expose `Make primary` and `Remove` actions.
- Primary row explains that primary is used for club-message delivery and cannot be removed.
- Verification success page copy: `Email verified, you can close this browser.`

## Acceptance Criteria

- A signed-in club member can open the avatar dropdown and follow **Account settings** to `/my/settings`.
- The avatar dropdown keeps **Sign out** and visually separates it from **Account settings** with a horizontal separator.
- `/my/settings` is global/personal and not a club-specific settings route.
- `/my/settings` is available only when the signed-in identity resolves to a Membership Person.
- A signed-in get-started-only identity that does not resolve to a Person is not given a new settings workflow in this iteration.
- The settings page shows the Person name and current club memberships.
- The settings page lists all Person email addresses with primary and verification state.
- Existing email-address rows are migrated/backfilled as verified.
- Adding a new email address creates a pending/unverified row immediately.
- Adding a duplicate address owned by another Person fails with `That email address is already in use by another Memba user.`
- A verification email is sent for a newly added pending address.
- A pending address can resend its verification email.
- A pending address can be removed.
- A pending address cannot be made primary.
- A verified non-primary address can be made primary.
- Changing primary immediately updates future club-message delivery and current UI display.
- A non-primary address can be removed even if it was the address used to start the current browser session.
- The primary address cannot be removed.
- Opening a valid verification link for a still-pending address marks that address verified and shows `Email verified, you can close this browser.`
- Opening an old verification link for a removed/replaced address does not verify or recreate that address and shows an invalid/expired state.
- An open settings LiveView updates when an address is verified elsewhere.
- Signing in with a pending known address may verify that address as part of proving mailbox control.
- Pending/unverified addresses are not accepted for inbound email identity.
- Club-message recipient resolution continues to send only to the current verified primary email address.
- Existing person email-address and member-message behaviours continue to pass.

## Open Business Decisions

None known.

## Implementation Plan

1. Inspect current identity, auth-token, Person email-address, and staff edit flows before changing the model.
2. Add verification state to the Person email-address read model/projection and database schema, with all existing rows backfilled as verified.
3. Model the write-side behaviour with explicit business commands/events rather than a generic replace-only edit where practical. Candidate behaviour names: add pending email address, verify email address, make primary email address, remove email address, resend verification request. Keep exact command/event names aligned with existing Membership aggregate style.
4. Preserve or adapt `replace_person_email_addresses/2` for staff edit compatibility while enforcing the new rule that newly introduced addresses become pending/unverified unless they already exist as verified addresses for that Person.
5. Add token generation/storage for email-address verification. Tokens must be one-use/expiring if existing auth token infrastructure supports it; otherwise keep validity safely scoped to the pending Person/address pair and do not verify removed/replaced addresses.
6. Add a general verification email template using existing transactional email delivery conventions.
7. Add the verification callback route/page. A valid callback verifies the address, publishes a settings/read-model change notification, and renders `Email verified, you can close this browser.` Invalid/expired callbacks render a calm invalid/expired message.
8. Update sign-in callback handling so a successful sign-in link for a pending known Person email address marks that address verified without making it primary or changing the Person session semantics.
9. Update inbound email sender resolution so pending/unverified known addresses are rejected rather than accepted as member identity.
10. Add `/my/settings` LiveView under the club-member/authenticated browser surface as a global personal settings page.
11. Add the **Account settings** avatar-menu link and separator in `Layouts.club_site/1`.
12. Build the settings UI using existing app shell/card/form/badge patterns, with stable IDs for LiveView tests.
13. Subscribe the settings LiveView to Person email-address changes and refresh rows live after verification.
14. Add/update domain tests for verification state, primary restrictions, duplicate handling, removal restrictions, sign-in-as-verification, and inbound rejection.
15. Add/update LiveView/controller tests for avatar menu navigation, settings page rendering, add/resend/remove/make-primary flows, verification confirmation, invalid verification link, and live refresh.
16. Implement or update the `@iteration-053` acceptance scenarios, removing or narrowing `@todo-domain @todo-ui` as behaviour becomes executable.
17. Run `dev check` and fix all issues.

## Open Technical Decisions

- Exact token storage mechanism: reuse existing auth token infrastructure if it cleanly supports email-address verification tokens without disturbing sessions; otherwise add a narrowly scoped verification-token store.
- Exact command/event shape for evolving from full address-set replacement to individual self-service actions while keeping historic event replay and staff edit compatibility safe.
- Whether verification state belongs only in the projection event payloads, or also in an aggregate-held email-address value object for invariant enforcement. Prefer aggregate enforcement for primary/removal rules.
- Exact PubSub topic/message shape for settings refresh. It should identify the Person or opaque changed resource and avoid exposing sensitive email details unnecessarily.

## New Capability

Members can manage their own verified email addresses from a global personal settings page. Memba can distinguish verified and pending Person email addresses and prevent pending addresses from being used for primary delivery or inbound identity until mailbox control is proven.

## Validation Plan

- Run `dev check` after implementation.
- Domain/context tests:
  - existing rows are treated as verified after migration/backfill;
  - adding an address creates pending state;
  - pending addresses cannot become primary;
  - verified non-primary addresses can become primary;
  - primary cannot be removed;
  - non-primary can be removed;
  - removed pending address cannot be verified by an old token;
  - duplicate normalized address attached to another Person is rejected;
  - sign-in with pending known address verifies it;
  - inbound from pending known address is rejected.
- LiveView/controller tests:
  - avatar menu contains Account settings, separator, and Sign out;
  - `/my/settings` renders Person basics, club memberships, and email rows;
  - add/resend/remove/make-primary flows update UI and domain state;
  - verification callback shows success copy;
  - invalid/expired callback shows invalid/expired copy;
  - open settings LiveView updates after verification PubSub notification.
- Acceptance tests:
  - implement/update `acceptance-tests/features/person_email_addresses.feature` scenarios tagged `@iteration-053` and remove/narrow temporary `@todo-domain @todo-ui` tags when executable.
- Manual demo:
  1. Sign in as an existing club member.
  2. Open avatar menu and choose Account settings.
  3. Add a new email address and observe pending state.
  4. Confirm pending address cannot be made primary.
  5. Use the verification link in a separate browser/tab.
  6. Confirm the verification page says `Email verified, you can close this browser.`
  7. Confirm the original settings page updates to verified.
  8. Make the verified address primary.
  9. Remove the old non-primary address.
  10. Confirm club-message delivery uses the new primary address.

## Risks / Follow-ups

- Staff edit currently replaces full email-address sets; adapting it to preserve verification state without surprising Staff may require careful command/event design.
- Reusing sign-in links as verification must not leak account existence or accidentally change session semantics.
- The invalid/expired verification page should be calm, but a fuller recovery path may be needed later.
- Inbound rejection from an unverified known address is safe but may confuse members; follow-up captured in `docs/problems/2026-07-11-unverified-email-inbound-rejection-confusion.md`.
- Shared household email addresses remain out of scope and may require revisiting the global uniqueness invariant.
- Claude/DesignSync should review whether the existing design references are enough or whether a dedicated `/my/settings` preview should be added before delivery.
