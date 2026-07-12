## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. Replace the acceptance criterion wording “Signing in with a pending known address **may** verify that address” with deterministic wording such as “**does** verify that address,” matching the implementation plan and scenario summary.
2. Consider clarifying the unauthorized `/my/settings` behavior for signed-in identities that do not resolve to a Membership Person, e.g. no menu link plus redirect/404/flash behavior if visited directly.
3. The “Open Technical Decisions” section is acceptable for implementation readiness, but the implementer should resolve and document the chosen token storage, command/event shape, verification-state ownership, and PubSub topic/message shape during implementation.
4. The scope is coherent but large. If implementation risk grows, defer live PubSub refresh or staff-edit compatibility polish only if doing so does not weaken the core safety rules.

## Smallest viable iteration

The smallest useful slice is: a signed-in Membership Person can access `/my/settings`, view their email addresses with verified/pending/primary state, add a pending address, receive and open a verification link, and then make the verified address primary while pending addresses remain blocked from primary delivery, sign-in identity, and inbound identity.

Removal, resend, avatar-menu polish, and live-update behavior are important for the full planned experience, but the core useful outcome is safe self-service addition and verification of alternate email addresses.

## Required plan edits

None required before implementation.

## Validation plan

Success should be proven by:

1. Migration/backfill tests confirming existing email-address rows become verified.
2. Domain tests for adding pending addresses, duplicate rejection, verification, removed-token invalidation, primary restrictions, removal restrictions, sign-in-as-verification, inbound rejection, and club-message delivery to verified primary only.
3. LiveView/controller tests for avatar-menu navigation, `/my/settings` rendering, add/resend/remove/make-primary flows, verification success, invalid/expired verification links, and live refresh.
4. Updated Cucumber feature coverage in `acceptance-tests/features/person_email_addresses.feature` for the named `@iteration-053` scenarios, with temporary todo tags removed or narrowed as behavior becomes executable.
5. Manual demo covering account settings access, add pending address, verify via emailed link, live UI update, make primary, remove non-primary, and confirm future club-message delivery uses the new primary address.
6. Final `dev check` passing after implementation.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}