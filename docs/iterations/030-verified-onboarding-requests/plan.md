# Verified public onboarding requests

Date: 2026-06-08
Status: ready

## Goal

Require a signed-out public requester to verify control of their email address with Memba's existing magic-link auth before they can submit a club onboarding request that Memba Staff can see or act on.

Verification creates a signed-in identity/account session for the email address, but does not create a Membership Person. Staff conversion remains the point where Memba creates or reuses the Person, creates the club, and makes the requester the first active member.

## Background / Context

Iteration 022 replaced open self-serve signup with Staff-approved request-to-club onboarding. That protected Memba's sender reputation by ensuring a public request does not immediately create a club, membership, or email-sending capability. However, a signed-out visitor can still submit a request with an email address they have not proved they control. Staff may be asked to triage or convert a request whose requester email is spoofed or mistyped.

Iterations 028 and 029 use invitation/magic-link patterns for member invitations. This iteration applies the same identity-control principle to the public Get Started request flow, while keeping the Staff-approved onboarding model intact.

## Related Problems

- [`docs/problems/2026-06-08-onboarding-request-unvalidated-email.md`](../../problems/2026-06-08-onboarding-request-unvalidated-email.md): expected to resolve. Signed-out requesters must verify their email through a magic-link sign-in before Staff see or act on the onboarding request.
- [`docs/problems/2026-06-05-spammers-abusing-open-signups.md`](../../problems/2026-06-05-spammers-abusing-open-signups.md): remains resolved for the current product shape. This iteration keeps Staff approval as the gate before any club, membership, or email-sending capability is created.
- [`docs/problems/2026-06-05-onboarding-request-email-lacks-action-link.md`](../../problems/2026-06-05-onboarding-request-email-lacks-action-link.md): related but intentionally left unresolved unless already delivered elsewhere. This slice changes when Staff notifications are sent, not the notification's action-link content.
- [`docs/problems/2026-06-08-person-alternate-email-verification-missing.md`](../../problems/2026-06-08-person-alternate-email-verification-missing.md): related but intentionally left unresolved. This slice verifies the public requester identity email; it does not change alternate email-address management for existing people.

## Scope

### In scope

- Change the signed-out `/get-started` flow so the first step asks for email address only.
- Reuse the existing magic-link sign-in email/token flow, with `return_to` back to the Get Started request form.
- After the requester follows the magic link, sign them in as a verified identity for that email address.
- Treat the signed-in identity as an account/verified email session, not as a Membership Person.
- For a signed-in identity whose email does not belong to an existing Person, show a verified request form asking for name, club name, and short note.
- Submitting the verified request stores the request with the verified identity email and supplied name/club/note.
- Do not create a Person, club, membership, or sign-in access when the verified request is submitted.
- Send the Staff new-request notification only after a verified request is submitted.
- Show Staff only verified submitted requests in the active requests inbox.
- For a signed-in identity whose email belongs to an existing Person, preserve the current behaviour: show known name/email as read-only request details and ask only for club name and short note.
- Preserve Staff rejection/conversion behaviour from iteration 022 for verified requests.
- Preserve conversion semantics: reuse an existing Person when the verified email belongs to one; otherwise create the Person from the verified request name/email during Staff conversion.
- Preserve existing general magic-link sign-in behaviour.

### Out of scope

- Creating a Membership Person during email verification or request submission.
- Self-serve club creation, membership creation, or email-sending capability.
- CAPTCHA, spam scoring, rate limiting, or automated abuse detection.
- Requester rejection emails.
- Converted/rejected request history UI beyond existing behaviour.
- Changing the Staff request notification email content beyond ensuring it is sent only for verified requests.
- Changing invitation flows.
- Verifying alternate email addresses for existing people.

## Iteration Type

Behaviour-facing.

The user-observable rule changed is that signed-out public requesters verify their email before completing a Staff-reviewable request. The Staff-observable rule changed is that active onboarding requests and new-request notifications represent verified requester email control.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

This iteration changes public onboarding, identity verification, Staff triage trust, and the boundary between an auth identity/account and a Membership Person. Stakeholder-readable examples are needed to make clear that verification signs a requester in but does not create membership-domain records until Staff conversion.

Update existing feature file:

- `acceptance-tests/features/request_account.feature`
  - Add scenarios tagged `@iteration-030 @todo-domain @todo-ui` during planning.
  - `@todo-domain @todo-ui` keeps planning-time checks green because the verified Get Started flow and step support are future-facing.
  - Commented rule heading: `# Rule: Signed-out requesters verify their email before Staff review`
    - Scenario: Robin verifies their email before submitting a request
    - Scenario: Staff do not see an email-only verification that Robin abandons
  - Commented rule heading: `# Rule: Verified request submission does not create membership-domain records`
    - Scenario: Robin submits a verified request before becoming a Person
    - Scenario: Pat converts Robin's verified request into a club and first member

Existing request-account scenarios may be updated during delivery to align with the new verified flow. In particular, the existing public request scenario should no longer imply that a signed-out person can submit a Staff-visible request without following a magic link first.

## Allowed acceptance feature changes

- `acceptance-tests/features/request_account.feature`: add the planned `@iteration-030` scenarios under scenario-level `@todo-domain @todo-ui`; during delivery, implement the verified public request flow, update existing public request scenarios to the new language, and remove or narrow `@todo-domain`/`@todo-ui` when the scenarios pass in the relevant runner.
- Existing authentication feature files may be updated only where necessary to describe the reused magic-link return-to behaviour for Get Started. Preserve existing sign-in behaviour unless this plan explicitly changes it.

## Acceptance Criteria

- A signed-out visitor opening Get Started can enter only an email address as the first step.
- Submitting the email sends the existing magic-link sign-in email/token to that address with a return destination back to Get Started.
- Entering only an email does not create an onboarding request visible to Staff.
- Entering only an email does not send the Staff new-request notification.
- Following the magic link signs the requester in as the verified email identity.
- Following the magic link returns the requester to the Get Started request form.
- If the verified email does not belong to a Person, the request form asks for name, club name, and short note.
- Submitting that verified request stores an active onboarding request using the verified identity email and supplied name/club/note.
- Submitting that verified request sends the Staff new-request notification.
- Submitting that verified request shows the requester the existing review acknowledgement.
- Submitting that verified request does not create a Person.
- Submitting that verified request does not create a club.
- Submitting that verified request does not create an active membership or sign-in access to a club.
- Staff active requests inbox lists the verified request.
- Staff can reject the verified request with the existing rejection behaviour.
- Staff can convert the verified request with the existing conversion behaviour.
- Converting a verified request for an email with no existing Person creates the Person from the verified request name/email, creates the club, creates the first active membership, removes the request from the active inbox, and sends the welcome email.
- Converting a verified request for an email belonging to an existing Person reuses that Person.
- A signed-in requester whose email already belongs to a Person keeps the current read-only known name/email request form and submits only club name and note.
- Existing general magic-link sign-in keeps working.
- Existing Staff request inbox, rejection, conversion, slug validation, and welcome email behaviours keep working for verified requests.
- The new Cucumber scenarios pass after implementation with `@todo-domain`/`@todo-ui` removed or narrowed as appropriate.
- `dev check` passes.

## Open Business Decisions

None known.

Confirmed decisions:

- Use email-first verification for signed-out requesters.
- Reuse the existing magic-link sign-in email/token flow.
- Verification creates a signed-in identity/account session but not a Membership Person.
- Name, club name, and note are collected after email verification for identities without a Person.
- Staff only see and receive notifications for verified submitted requests.

## Implementation Plan

1. Inspect the current `/get-started` controller/templates or LiveView, auth sign-in token creation, return-to handling, Staff request inbox, and onboarding request creation/notification code.
2. Split the public Get Started experience into two states:
   - signed-out: email-only verification request;
   - signed-in: verified request form.
3. Reuse the existing magic-link sign-in flow for the signed-out email-only step, setting return-to back to the Get Started request form.
4. Ensure following the magic link returns the requester to Get Started and assigns `current_identity` for the verified email.
5. Update request form rendering:
   - if signed in and the email belongs to an existing Person, show known name/email read-only and collect club name/note;
   - if signed in and no Person exists, collect name, club name, and note while using the signed-in email as read-only verified identity.
6. Update request submission so it requires a signed-in identity email and never trusts a typed requester email for Staff-visible requests.
7. Ensure email-only verification requests do not create onboarding request records or Staff notifications.
8. Ensure verified request submission does not create Person, club, membership, or club access.
9. Preserve Staff request inbox and notification behaviour for verified submitted requests.
10. Preserve Staff conversion/rejection semantics for verified submitted requests, including creating/reusing the Person during conversion.
11. Add or update controller/LiveView tests for signed-out email-only step, magic-link return-to, verified identity with no Person, verified identity with existing Person, and no Staff visibility before verification.
12. Add or update domain/context tests proving request creation requires a verified identity email and does not create membership-domain records.
13. Update Cucumber step definitions only as needed during delivery to exercise the `@iteration-030` scenarios.
14. Remove or narrow `@todo-domain`/`@todo-ui` from the new/updated scenarios only when they pass in the relevant runner.
15. Run `dev check`.

## Open Technical Decisions

- Exact function/module names for the email-only Get Started verification step.
- Whether the existing auth sign-in UI/service can be reused directly with a `return_to`, or whether Get Started needs a thin wrapper around the token/email creation call.
- Whether to persist any short-lived pre-verification UI state. The preferred slice avoids this by collecting name/club/note only after magic-link verification.

## New Capability

Memba Staff only triage onboarding requests from people who have proved control of the requester email address. Public visitors can create a verified identity/account session before requesting a club, without creating a Membership Person or gaining club access until Staff approve the request.

## Validation Plan

- Review `acceptance-tests/features/request_account.feature` language for the new verified-request examples before delivery.
- During implementation, add web tests for the signed-out email-only Get Started step, magic-link return-to, verified request form, and signed-in existing-person form.
- Add tests proving Staff do not see or receive notification for an abandoned email-only verification.
- Add tests proving verified request submission creates no Person, club, membership, or club access.
- Run the updated Cucumber scenarios after implementation with appropriate todo tags removed or narrowed.
- Run `dev check`.

## Risks / Follow-ups

- This iteration changes a currently working public request flow; preserve the low-friction feel by making the email-first step clear and the post-link form obvious.
- Staff notifications will move later in the flow, so abandoned email-only attempts become invisible by design. If Matt later wants visibility into abandoned attempts, capture that as a separate operational analytics problem rather than making them Staff-actionable requests.
- This does not add CAPTCHA/rate limiting. If abuse continues through verified emails, a future anti-abuse iteration may be needed.
