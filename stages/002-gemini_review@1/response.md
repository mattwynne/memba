## Decision: READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/053-my-settings-email-addresses/plan.md` lines 1–252. No files were edited.

## Blocking gaps

None.

## Non-blocking improvements

1. Clarify same-Person duplicate handling when a member tries to add an email address already attached to their own Person record, especially if it is already pending or verified.
2. Optionally state the exact UX for direct access to `/my/settings` by a signed-in identity that does not resolve to a Membership Person, e.g. redirect, 404, or existing onboarding flow.
3. Optionally name the intended verification-token TTL or explicitly reference the existing sign-in-link TTL constant if one exists.
4. Optionally define the exact invalid/expired verification-link copy if product wants consistency beyond “calm invalid/expired state.”

## Smallest viable iteration

The smallest useful slice is essentially the current coherent slice: a signed-in member can reach global Account settings, view Person basics and memberships, manage email addresses, verify newly added addresses, make verified addresses primary, remove non-primary addresses, and have pending addresses excluded from primary delivery/sign-in/inbound identity until verified.

A smaller read-only settings page or email-management UI without verification enforcement would not deliver the stated safety/business outcome.

## Required plan edits

None required before implementation.

## Validation plan

Success can be proven by:

1. Running `dev check`.
2. Passing domain/context tests for:
   - existing email addresses backfilled as verified;
   - newly added addresses created pending;
   - pending addresses blocked from primary status;
   - verified alternates allowed to become primary;
   - primary address removal blocked;
   - non-primary removal allowed, including the session-starting address;
   - duplicate address handling;
   - removed pending address not verified by old token;
   - sign-in link for pending known address verifies without changing primary/session semantics;
   - inbound identity rejection for pending addresses.
3. Passing LiveView/controller tests for:
   - avatar menu Account settings link, divider, and Sign out;
   - `/my/settings` rendering Person basics, memberships, and email rows;
   - URL-addressable Profile/Clubs/Emails tabs;
   - add/resend/remove/make-primary flows;
   - verification success and invalid/expired pages;
   - live refresh after verification PubSub notification.
4. Updating/executing the planned `acceptance-tests/features/person_email_addresses.feature` scenarios and removing/narrowing temporary `@todo-domain @todo-ui` tags as implementation support lands.
5. Manual demo of the end-to-end member flow from avatar menu through adding, verifying, making primary, removing old alternate, and confirming delivery uses the new verified primary.

{"context_updates":{"gemini_review_decision":"READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":0,"gemini_review_blocking_gaps":"None","gemini_review_required_edits":"None"}}