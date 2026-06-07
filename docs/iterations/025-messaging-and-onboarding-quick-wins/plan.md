# Messaging and onboarding quick wins

Date: 2026-06-06
Status: merged

## Goal

Clear three small, high-friction product problems without opening larger product areas:

1. Outgoing club-message emails identify the club in the subject with the mandatory club slug.
2. Member compose validates blank message bodies clearly before send.
3. Staff notification emails for onboarding requests link directly to the relevant request conversion view.

## Background / Context

The problems index shows a few small unresolved or partially addressed items that can be cleared as a focused quick-wins iteration. This iteration deliberately avoids larger product slices such as email replies/threading, custom domains, email verification, club-owner permissions, and rejected inbound email inboxes.

Iteration 024 is currently implementing transactional email template redesign and touches member-message email generation. This quick-wins iteration should start after iteration 024 is merged so the implementation can build on the new email rendering shape rather than racing it.

Club slugs are mandatory. A club-message email subject should therefore always include the slug prefix, for example `[kmc] Trip planning night`. This is not configurable in this slice.

The existing staff request inbox at `/admin/requests` already has the conversion form/panel. This iteration should make that conversion state addressable by URL, not duplicate it in a separate implementation. LiveView patch navigation can change the URL and open the conversion panel without a full page refresh.

## Related Problems

- [`docs/problems/2026-06-01-club-email-lacks-context-links.md`](../../problems/2026-06-01-club-email-lacks-context-links.md): partially addressed. This iteration adds the important mandatory slugged subject prefix. Full context links back to the club site/message page remain separate unless iteration 024 or later covers them.
- [`docs/problems/2026-06-01-member-compose-blank-body-generic-failure.md`](../../problems/2026-06-01-member-compose-blank-body-generic-failure.md): expected to resolve. Blank or whitespace-only message bodies should produce a specific form validation message and no send attempt.
- [`docs/problems/2026-06-05-onboarding-request-email-lacks-action-link.md`](../../problems/2026-06-05-onboarding-request-email-lacks-action-link.md): expected to resolve. Staff notification emails should link directly to the relevant request conversion URL.
- [`docs/problems/2026-06-05-club-email-announcement-behaviour-unclear.md`](../../problems/2026-06-05-club-email-announcement-behaviour-unclear.md): not targeted here. Iteration 024 is expected to address reply-to-sender guidance and announcement-style email copy.

## Scope

### In scope

- Always prefix outgoing club-message email subjects with the club slug, using the format `[slug] Subject`.
- Preserve the in-app message subject exactly as entered; only the outbound email envelope subject is prefixed.
- Apply slugged subjects consistently to member-message email delivery paths, including Postmark, Resend, Local/Swoosh, and local delivery facts where they record the delivered email subject.
- Validate blank or whitespace-only member compose bodies in the LiveView before calling `Messaging.send_club_message/2`.
- Show a clear, specific, recoverable member-facing validation message for blank body, such as “Message body can’t be blank.”
- Ensure invalid member compose input does not create a club message and does not call the configured email delivery provider.
- Add an addressable staff request conversion URL under the existing staff requests LiveView, for example `/admin/requests/:request_id`.
- Refactor the existing requests inbox Convert action to patch/navigate to the request-specific conversion URL instead of using a list-only `phx-click` state.
- Reuse the existing conversion panel/form logic for the request-specific URL; do not duplicate conversion behaviour in a second LiveView.
- Let the email link open the requests page with the relevant request conversion panel visible. The panel may remain in the existing page layout rather than becoming a standalone detail page.
- Add a direct browser link to the staff onboarding-request notification email pointing to the request-specific conversion URL.
- Keep the request-specific conversion URL under the existing staff-only request access controls.
- Show a clear no-longer-active/not-found state when staff opens a request-specific conversion URL for a converted, rejected, missing, or invalid request, with a link back to `/admin/requests`.
- Add or update tests for the above behaviours.

### Out of scope

- Moderator, staff, or club-owner settings for slugged subjects. Slug prefixes are always on.
- Full club/message context links in member-message emails, except where iteration 024 has already made a safe helper available and implementation can include them without broadening the slice.
- Changing in-app message subjects or message projections to include the slug.
- Email replies, threading, or reply-to-Memba behaviour.
- Request rejection deep links unless they naturally fall out of the route refactor without extra product decisions.
- A full standalone request detail page beyond the conversion URL/panel.
- Club-owner/admin roles, permissions, or member invitation capability.
- Email verification, custom domains, rejected inbound email inboxes, or public signup changes.

## Iteration Type

Behaviour-facing quick-wins iteration.

The user-observable rules changed are:

- Club-message email recipients can identify the club from the email subject.
- Members get a specific validation error for a blank compose body instead of a generic send failure.
- Memba staff can move from a request notification email directly to the relevant request conversion workflow.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

These are small but user-visible rules involving messaging, validation, and staff workflow. The existing feature files are the right place to express them:

- `acceptance-tests/features/member_message_deliverability.feature`
  - Add a scenario for slugged club-message email subjects.
  - Add a scenario for blank-body compose validation.
- `acceptance-tests/features/request_account.feature`
  - Add a scenario for staff opening the request conversion workflow from the notification email link.

The new scenarios should be marked `@todo-domain`/`@todo-ui` while this plan is ahead of implementation.

## Allowed acceptance feature changes

- `acceptance-tests/features/member_message_deliverability.feature`: remove `@todo-domain`/`@todo-ui` from the slugged club-message email subject scenario once it is implemented; remove `@todo-domain`/`@todo-ui` from the blank-body compose validation scenario once it is implemented.
- `acceptance-tests/features/request_account.feature`: remove `@todo-domain`/`@todo-ui` from the staff notification request-conversion link scenario once it is implemented.

## Acceptance Criteria

- When Alice sends a Kootenay Mountaineering Club message with subject `Trip planning night`, every outgoing member-message email subject is `[kmc] Trip planning night`.
- The stored/projected/in-app message subject remains `Trip planning night`.
- Subject prefixing handles already-trimmed user subjects without introducing doubled spaces.
- Provider tests cover Postmark, Resend, Local/Swoosh, and local delivery facts or equivalent local mailbox evidence.
- When a member submits compose with a blank or whitespace-only body, the form stays in compose mode and shows a body-specific validation message.
- Blank-body compose validation preserves the entered subject so the member can recover.
- Blank-body compose validation does not dispatch `Messaging.send_club_message/2`, create a message, or call the delivery provider.
- Existing generic send failure remains for real delivery/provider failures.
- `/admin/requests` still lists active onboarding requests.
- Clicking Convert in the requests list changes the URL to the request-specific route using LiveView patch navigation and opens the existing conversion panel for that request without duplicating conversion code.
- Opening the request-specific route directly as staff shows the conversion panel for that active request.
- The request-specific route remains protected by the same staff authorization as `/admin/requests`.
- Cancelling conversion patches/navigates back to `/admin/requests`.
- Successfully converting the request still creates the club, first active member, converted request record, and welcome email as before, then returns staff to the active requests inbox.
- Opening a request-specific route for a converted, rejected, missing, or invalid request shows a clear no-longer-active/not-found message and a link back to `/admin/requests`.
- The new-request staff notification email includes the request ID/details and a direct browser link to the request-specific conversion URL.
- Existing request-account acceptance scenarios continue to pass, aside from the newly planned `@todo-domain`/`@todo-ui` scenario while this plan is ahead of implementation.
- The iteration is complete when the three new acceptance scenarios pass without `@todo-domain`/`@todo-ui` tags and `dev check` passes.

## Open Business Decisions

None known.

Confirmed decisions:

- Slug prefixes are always on because club slugs are mandatory.
- The request notification link may open the existing requests page with the conversion panel visible; it does not need a bespoke standalone detail layout.

## Implementation Plan

1. Start after iteration 024 is merged to avoid conflicts in member-message email template/provider code.
2. Inspect current member-message email request shape after iteration 024, especially where club name/slug is available to Postmark, Resend, Local/Swoosh, and local delivery facts.
3. Add or reuse a small helper for member-message outbound email subject rendering, for example `"[#{club_slug}] #{subject}"`, with header-safe sanitization consistent with iteration 024's email helper approach.
4. Ensure `EmailDeliveryRequest` or equivalent delivery request data carries the club slug if it does not already. Prefer deriving it at request creation time from the membership context rather than coupling provider modules to membership projections.
5. Update Postmark, Resend, and Local/Swoosh member-message delivery code to use the prefixed email subject while keeping text body and in-app message subject unchanged.
6. Update local delivery facts to record the actual outbound email subject if local facts are used as mailbox evidence.
7. Add tests proving stored message subject remains unprefixed while outbound emails are prefixed.
8. Update `MembaWeb.MemberMessageLive.New` to validate blank/whitespace-only body before `send_current_member_message/2` dispatches.
9. Add body-specific form error rendering while preserving the existing generic send-failure state for provider/infrastructure failures.
10. Add LiveView tests for blank body and whitespace-only body, including no provider delivery requests and preserved subject.
11. Add a request-specific route in the existing staff live session, likely mapping both routes to the same LiveView module:
    - `live "/requests", RequestsLive.Index, :index`
    - `live "/requests/:request_id", RequestsLive.Index, :convert`
12. Refactor `RequestsLive.Index` to use `handle_params/3` for conversion route state:
    - `:index` clears conversion state;
    - `:convert` loads the active request and assigns the existing conversion panel/form;
    - invalid or inactive request assigns a no-longer-active state.
13. Replace the list Convert button with a patch link to the request-specific route, using `<.link patch={...}>` or the current Phoenix 1.8 equivalent. Do not use deprecated `live_patch`.
14. Make conversion cancel patch back to `/admin/requests`.
15. After successful conversion, return staff to `/admin/requests` with the existing success flash and refreshed stream.
16. Update `Memba.Onboarding.NewRequestEmail` to include an absolute request-specific staff URL. Reuse the app's existing URL generation/configuration approach for absolute links.
17. Add tests for direct request URL, list Convert patch behaviour, inactive/missing request state, notification email link, and unchanged conversion outcomes.
18. Update acceptance feature files with the planned `@todo-domain`/`@todo-ui` scenarios.
19. Run targeted tests for messaging email providers, member compose LiveView, onboarding request LiveView, onboarding email, and acceptance feature parsing.
20. Run `dev check`.

## Implementation Details to Confirm

These are low-level implementation details, not blocking product or architecture decisions:

- Exact helper/module name for prefixed member-message email subjects after iteration 024's email helper structure is known.
- Whether the request route uses `RequestsLive.Index` with live action `:convert` or a similarly named module. Prefer the same LiveView and shared render path to avoid duplication.
- Exact absolute URL source for staff notification email links in test/dev/prod configuration.

## New Capability

Memba clears three small workflow and trust gaps: club-message emails are easier to recognize in inboxes, blank compose input is handled as a normal form validation problem, and staff can act on onboarding request notifications without manually finding the request.

## Validation Plan

- Review the updated Gherkin scenarios with Matt as domain language before implementation if there are wording concerns.
- Run focused tests for member-message email providers and local delivery facts proving prefixed outbound subjects.
- Run member compose LiveView tests proving blank-body validation and no send side effect.
- Run onboarding request LiveView tests proving patch navigation, direct route mounting, inactive/missing state, and unchanged conversion behaviour.
- Run onboarding notification email tests proving the request-specific action link is present.
- Run affected acceptance tests or at least feature parsing/tag checks while scenarios remain `@todo-domain`/`@todo-ui`.
- Remove the `@todo-domain`/`@todo-ui` tags from the three new acceptance scenarios once implemented and run them green.
- Run full `dev check` before delivery is considered complete.

## Risks / Follow-ups

- Iteration 024 may change email rendering and tests; starting this iteration after 024 reduces merge conflicts.
- Slugged subjects solve only one part of the broader email-context problem. Club/message links should remain a follow-up if not already handled by iteration 024.
- Request-specific conversion state should not become a hidden second implementation of request conversion. Keep one conversion path and one set of tests for the business outcome.
- Direct request links in email require correct external URL configuration in production; tests should make the expected base URL explicit.
