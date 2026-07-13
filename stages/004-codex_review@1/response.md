## Decision: READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/053-my-settings-email-addresses/plan.md` through line 251 and confirmed there was no additional content after that.

## Blocking gaps

1. None.

## Non-blocking improvements

1. The plan still has `Status: needs-revision`; if this workflow records validation in the file later, that status should be updated by the appropriate synthesis/validation step.
2. The acceptance criterion “Signing in with a pending known address may verify that address” would be slightly clearer as “does verify” or with exact conditions, since the validation plan already expects that behaviour.
3. The direct-navigation behaviour for signed-in identities that do not resolve to a Membership Person could be made more explicit, e.g. redirect, 404, or existing onboarding flow.
4. The duplicate-address rule is clear for addresses owned by another Person, but the plan could clarify the UX for attempting to add an address already attached to the same Person.
5. The “Open Technical Decisions” are bounded enough for implementation, but the implementer should resolve them early before broad UI work, especially token storage and aggregate/projection enforcement.

## Smallest viable iteration

The smallest useful slice is the current coherent member-facing email-management capability: a signed-in Person can reach global Account settings, see profile/club/email state, add a pending email, verify it, make a verified address primary, and remove non-primary addresses while pending addresses remain unusable for primary delivery or inbound identity.

If forced smaller, the minimum valuable slice would be:

1. `/my/settings` with avatar-menu entry.
2. Email-address listing with primary/verified/pending state.
3. Add pending email + verification email/callback.
4. Make verified non-primary primary.
5. Remove non-primary address.
6. Enforce pending-address restrictions for primary delivery, sign-in verification, and inbound identity.

Resend verification and live PubSub refresh could be deferred, but they are well-scoped and fit the current iteration.

## Required plan edits

None required for readiness.

## Validation plan

Success should be proven by:

1. Migration/domain tests showing existing addresses are backfilled as verified and new addresses start pending.
2. Domain tests for duplicate rejection, pending-not-primary, verified-make-primary, primary-not-removable, non-primary-removable, removed-token-invalid, sign-in-as-verification, and inbound pending rejection.
3. LiveView/controller tests for avatar-menu navigation, `/my/settings` rendering, URL-addressable tabs, add/resend/remove/make-primary flows, verification success, invalid/expired links, and live refresh.
4. Acceptance scenarios in `acceptance-tests/features/person_email_addresses.feature` for the stakeholder-facing behaviour.
5. Manual demo covering the end-to-end member flow from avatar menu through add, verify, promote to primary, remove old address, and confirm future club-message delivery uses the new verified primary.
6. Final `dev check` passing after implementation.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}