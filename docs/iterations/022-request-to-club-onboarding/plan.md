# Staff-approved request-to-club onboarding

Date: 2026-06-05
Status: implementing

## Goal

Let interested club organisers request access through Memba, then let Memba staff convert a genuine request into a real club with an active first member and a direct welcome/sign-in link. Public visitors still cannot self-serve into email-sending capability.

## Background / Context

`docs/problems/2026-06-05-spammers-abusing-open-signups.md` captures the risk that open public signup could let bad actors send unwanted email through Memba, harming sender reputation and legitimate deliverability.

The current roadmap already points toward a safer near-term onboarding model: replace public “get started” links with request-an-account lead capture, create no club/account automatically, and let Memba staff review requests.

During planning Matt decided this iteration should cover the full staff-mediated onboarding lifecycle:

- public/signed-in people can request access;
- Memba staff can reject unsuitable requests with internal notes;
- Memba staff can convert genuine requests into clubs and first active members;
- converted requesters receive a direct welcome magic link to the new club.

Matt also noted that existing staff UI already creates clubs with generated/editable slugs. The implementation must reuse or extract that existing club creation/slug behaviour rather than duplicating a divergent conversion form.

## Scope

### In scope

- Replace the current `/get-started` mailto-only page with a request form.
- Signed-out requesters provide:
  - name;
  - email address;
  - club name;
  - short note.
- Signed-in requesters are known people with names:
  - pre-populate their known name and email;
  - show name/email as read-only request details rather than editable fields;
  - ask only for club name and short note.
- Validate required request details and email shape where the requester supplies an email.
- Store each request durably with enough data for staff triage and audit.
- Send a notification email about new requests to `hello@memba.io`.
- Show the requester a clear acknowledgement that Memba will review the request.
- Add staff Requests navigation and a basic `/admin/requests` active requests inbox.
- Staff can reject an active request:
  - capture internal reason/notes;
  - remove it from the active requests inbox;
  - do not notify the requester;
  - create no club, person, membership, sign-in link, or access.
- Staff can convert an active request:
  - reuse or extract the existing staff club creation UI/rules for generated/editable slugs;
  - suggest a slug from the requested club name;
  - let staff edit the slug before confirming;
  - apply the existing slug validation and availability rules;
  - create the club;
  - reuse an existing person when the request email already belongs to a person;
  - otherwise create a new person from the request name/email;
  - create an active membership for the requester in the new club;
  - mark the request converted and remove it from the active requests inbox;
  - send a welcome email with a magic sign-in link whose destination is the new club’s member home.
- The welcome link should work for the requester whether or not they are already signed in when they click it. Re-authenticating the same person through the magic-link flow is acceptable.
- Add tests for public request submission, signed-in prepopulation/read-only identity details, staff request triage, rejection, conversion, existing-person reuse, slug validation/reuse, welcome email delivery, and authorization.
- Keep `dev check` green.

### Out of scope

- Public self-serve account, club, membership, or sending capability creation.
- Applicant confirmation email before staff review.
- Notifying requesters about rejected requests.
- Converted/rejected request history UI beyond removing those requests from the active inbox.
- Approval/rejection state filters, search, pagination, bulk actions, or dashboards.
- CAPTCHA, spam scoring, rate limiting, or automated abuse detection.
- Multi-person onboarding.
- Club branding setup during conversion.
- Billing, trials, plans, subscriptions, or payment collection.
- Club admin roles or permissions beyond creating the requester as an active first member.
- Building a duplicate club creation/slug form that can drift from the existing staff club creation behaviour.

## Iteration Type

Behaviour-facing.

The user-observable rule is that trying Memba becomes staff-approved onboarding: requesters may ask for access, but only Memba staff can reject a request or convert it into a club with an active first member and a sign-in link.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

This iteration changes public onboarding, staff triage, access creation, rejection policy, identity reuse, and email invitation behaviour. Stakeholder-readable examples are useful to keep the anti-abuse boundary explicit: a public request must not itself create email-sending access.

Create this shared Cucumber feature file:

- `acceptance-tests/features/request_account.feature`

The feature is tagged `@wip` during planning because all scenarios are future-facing and the request model, routes, UI, emails, and step support do not exist yet.

Scenario summaries:

- Robin requests access without gaining immediate club access.
- Alice requests a new club while signed in and does not re-enter known identity details.
- Pat converts a request into a club and first active member, using a suggested/editable slug.
- Pat converts a request from an existing person and Memba reuses that person.
- Pat rejects a request with an internal note and does not notify the requester.
- Robin receives a welcome sign-in link for the new club after conversion.

Matt should review the feature language before implementation removes the `@wip` tag.

## Allowed acceptance feature changes

- `acceptance-tests/features/request_account.feature`: create a new feature-level `@wip` feature documenting staff-approved request-to-club onboarding. The `@wip` tag keeps planning-time checks green until delivery implements the routes, UI, emails, request model, and step support.
- `acceptance-tests/test/cucumber_config.test.js`: update the planning-time browser Cucumber configuration test so it recognises `request_account.feature` as an explicitly deferred `@wip` planning feature.
- During implementation, acceptance support and step definitions may be added for public request submission, signed-in request submission, staff request triage, conversion/rejection, mailbox inspection, and welcome-link sign-in. Remove the `@wip` tag only when the scenarios pass.

## Acceptance Criteria

- `/get-started` presents a Memba-hosted request form instead of relying on a mailto-only contact link.
- Signed-out visitors can submit name, email, club name, and short note.
- Required fields are validated before a request is accepted.
- Invalid requester email addresses are not accepted.
- Successful submission stores a durable request.
- Successful submission sends a notification email to `hello@memba.io`.
- Successful submission shows an acknowledgement explaining that Memba will review the request.
- Submitting a request does not create a club.
- Submitting a request does not create active membership or sign-in access.
- A signed-in requester is treated as an existing person with a known name and email.
- Signed-in requesters see name/email pre-populated as read-only request details.
- Signed-in requesters submit club name and short note without editing identity details.
- `/admin/requests` exists for signed-in Memba staff and is protected by existing staff authorization.
- Staff navigation includes Requests.
- Non-staff users cannot access `/admin/requests` or request conversion/rejection actions.
- The active requests inbox lists unconverted/unrejected requests with requester name, email, club name, note, and submitted time.
- Staff can reject an active request with internal notes/reason.
- Rejected requests leave the active requests inbox.
- Rejection does not send an email to the requester.
- Rejection does not create a club, person, membership, sign-in link, or access.
- Staff can open/prepare conversion for an active request.
- Conversion suggests a default club slug from the requested club name.
- Conversion lets staff edit the suggested slug before confirming.
- Conversion reuses or extracts the existing staff club creation slug-generation, validation, and availability behaviour; it must not implement a separate divergent slug policy.
- Conversion cannot proceed with an invalid or already-taken slug.
- Conversion creates the requested club with the confirmed slug.
- If the request email belongs to an existing person, conversion reuses that person.
- If the request email does not belong to an existing person, conversion creates a person using the request name/email.
- Conversion creates an active membership for the requester in the new club.
- Conversion marks the request converted and removes it from the active requests inbox.
- Conversion sends the requester a welcome email for the new club.
- The welcome email includes a magic sign-in link that takes the requester to the new club’s member home after sign-in.
- The welcome link works whether the requester is already signed in or not; re-authenticating the same person via the link is acceptable.
- Existing staff club creation and slug editing behaviour keeps working.
- Existing member sign-in/authentication behaviour keeps working.
- `dev check` passes.

## Open Business Decisions

None known for this slice.

Decisions made during planning:

- Use `hello@memba.io` for new-request notifications.
- Staff need both conversion and rejection actions.
- Rejection captures internal notes/reason and does not notify the requester.
- Converted and rejected requests leave the active requests inbox; history UI is out of scope.
- Staff approval is sufficient to create the requester as an active first member.
- If a request email already belongs to a person, reuse that person rather than creating a duplicate.
- Signed-in users are people with names and should not re-enter editable name/email details on the request form.
- Conversion should send a direct magic-link welcome email to the new club.

## Implementation Plan

1. Inspect current public `/get-started`, homepage links, layouts, auth/current identity assigns, staff navigation, staff club creation LiveView, slug helper modules, membership/person creation APIs, and auth email/token APIs.
2. Extract reusable club creation/slug form logic if needed so request conversion and `/admin/clubs` share the same slug generation, validation, and availability behaviour. Prefer reuse over duplication.
3. Design the request persistence model:
   - requester name;
   - requester email;
   - requested club name;
   - note;
   - status such as active/converted/rejected;
   - internal rejection notes;
   - converted club/person identifiers where useful for audit;
   - submitted/triaged timestamps.
4. Add migration/schema/context functions for creating, listing active, rejecting, and converting requests.
5. Implement signed-out `/get-started` form with required-field and email validation.
6. Implement signed-in `/get-started` behaviour using the current person’s known name/email as read-only request details.
7. Send a new-request notification email to `hello@memba.io` after successful request creation.
8. Add staff `/admin/requests` route and LiveView under existing staff authentication.
9. Add Requests to the staff navigation without regressing existing Clubs, People, Messages, and Deliveries navigation.
10. Build the active requests inbox with clear request details and actions for reject/convert.
11. Implement rejection with required internal notes and no requester email.
12. Implement conversion preparation with generated/editable slug using the same rules as staff club creation.
13. Implement conversion transactionally where practical: create club, create/reuse person, create active membership, mark request converted, and send/wrap welcome email behaviour consistently.
14. Implement welcome email generation with a magic sign-in token and post-auth destination for the new club member home.
15. Add or update tests for public form validation/submission, signed-in prepopulation, notification email, staff authorization, active inbox, rejection, conversion, existing-person reuse, slug validation, welcome email, and preservation of existing club creation/slug behaviour.
16. Add acceptance step support for `request_account.feature` and remove `@wip` once the scenarios pass.
17. Run targeted tests while developing, then run `dev check`.

## Open Technical Decisions

Implementation should investigate and decide:

- Whether request persistence belongs in an existing context or a new onboarding/requests context.
- The cleanest way to reuse staff club creation slug behaviour: extracted helper functions, shared form component, or routing conversion through an existing create-club flow with request context.
- The exact post-auth return URL mechanism for welcome magic links to land on the club member home, especially for club subdomains.
- Whether new-request notification and welcome emails should reuse existing auth email configuration or introduce a small onboarding email module/config.
- How to keep conversion transactional around database changes while email delivery remains an external side effect.
- How to derive the signed-in person’s display name efficiently and reliably from the current identity email.

## New Capability

Memba has a staff-approved onboarding path: people can ask to try Memba, staff can reject unsuitable requests, and staff can convert genuine requests into clubs with active first members and direct sign-in links, without exposing public self-serve email-sending access.

## Validation Plan

- Review `acceptance-tests/features/request_account.feature` with Matt for domain language and examples before removing `@wip`.
- Run browser Cucumber configuration checks to ensure the new feature is excluded while `@wip`.
- During implementation, add LiveView/controller/context tests for request creation, validation, staff inbox, rejection, conversion, slug reuse, welcome email, and authorization.
- Run existing staff club slug tests to prove the shared slug behaviour still works.
- Run existing authentication tests to prove magic-link sign-in behaviour still works.
- Run the new acceptance scenarios after removing `@wip`.
- Run `dev check` before delivery is complete.

Manual demo after implementation:

1. Visit `/get-started` signed out.
2. Submit a request for West Coast Paddlers and see the acknowledgement.
3. Confirm no club/member access exists yet.
4. Sign in as Memba staff.
5. Open `/admin/requests` and see the active request.
6. Reject a second request with an internal note and confirm no requester email is sent.
7. Convert the West Coast Paddlers request, edit the generated slug, and confirm.
8. Confirm the club exists, the requester is an active member, and the request leaves the active inbox.
9. Open the welcome email and follow the magic link to the new club member home.

## Risks / Follow-ups

- This iteration reduces abuse from public self-serve signup but does not add automated spam controls; CAPTCHA/rate limits/spam scoring may still be useful later.
- Converted/rejected request history will probably become useful once there is real traffic.
- Staff may later need request search, filters, duplicate detection, and richer qualification fields.
- Staff may later need to invite additional club organisers during conversion.
- Club branding, billing/trials, and plan setup remain separate onboarding follow-ups.
