## Decision: READY

## Confidence: High

I read `docs/iterations/053-my-settings-email-addresses/plan.md` completely with file-reading tools. I did not edit files.

## Blocking gaps

1. None.

## Non-blocking improvements

1. Consider naming the exact verification-token TTL or the existing constant that should be reused. The current “short TTL aligned with sign-in links unless implementation finds an existing project constant” is probably implementable, but an exact value would reduce implementation ambiguity.
2. Consider clarifying the UX for adding an email address that is already attached to the same Person, especially if it is already verified or already pending. The plan clearly covers duplicates owned by another Person, but same-Person duplicate handling could be made explicit.
3. Consider stating the expected response for `/my/settings` when a signed-in identity does not resolve to a Membership Person, such as redirecting to onboarding/request flow or returning not found. The boundary is clear, but the concrete route behavior is not specified.
4. Consider naming likely module/test files during implementation, though the current implementation plan is already specific enough to proceed.

## Smallest viable iteration

The smallest useful slice is essentially the current coherent slice: a signed-in member can reach global Account settings, view profile/club/email state, add a pending email, verify it, make a verified alternate primary, remove non-primary addresses, and have pending addresses excluded from primary delivery/inbound identity until verified.

I would not split out verification from email management, because safely adding addresses depends on pending/verified state and mailbox-control proof. If scope pressure appears during implementation, the most plausible defer candidates are polish/follow-up items such as richer invalid-link recovery UX or resend throttling, both already out of scope.

## Required plan edits

None.

## Validation plan

Success should be proven by:

1. Domain/context tests for:
   - existing email rows backfilled as verified;
   - newly added addresses starting pending;
   - pending addresses blocked from becoming primary;
   - verified non-primary addresses becoming primary;
   - primary removal being rejected;
   - non-primary removal succeeding;
   - old links for removed/replaced pending addresses not verifying anything;
   - duplicate normalized addresses owned by another Person being rejected;
   - pending known-address sign-in verifying the address without changing primary/session semantics;
   - inbound email from pending known addresses being rejected.

2. LiveView/controller tests for:
   - avatar menu showing Account settings, separator, and Sign out;
   - `/my/settings` rendering Person basics, club memberships, and email rows;
   - Profile/Clubs/Emails tab state being URL-addressable and restorable;
   - add, resend, remove, and make-primary flows;
   - verification success and invalid/expired pages;
   - open settings LiveView refreshing after verification PubSub notification.

3. Acceptance scenarios in `acceptance-tests/features/person_email_addresses.feature` for the named `@iteration-053` scenarios, with temporary `@todo-domain @todo-ui` tags removed or narrowed as implementation lands.

4. Manual demo of the full member workflow:
   - sign in;
   - open Account settings from avatar menu;
   - add a pending email;
   - confirm it cannot be primary;
   - verify via emailed link;
   - observe live settings update;
   - make the verified address primary;
   - remove the old non-primary;
   - confirm future club-message delivery uses the new verified primary address.

5. Final stop condition: `dev check` passes after implementation with the intended tests and acceptance coverage updated.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}