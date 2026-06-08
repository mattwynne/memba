## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. Clarify the apparent tension between “consume the invitation token” and “reopening an accepted invitation link signs/keeps the person in and lands them in the club.” The intended rule appears to be: the link is one-use for membership creation, but may still resolve an already-accepted invitation safely.
2. Add an explicit acceptance criterion for authorization, e.g. non-Staff users cannot access or submit the Staff invitation route.
3. Name likely implementation modules/files where useful, especially for Membership invitation storage, mail delivery, auth callback/profile completion, and Staff club routes.
4. Consider specifying what “clear Staff-facing message” means for duplicate active-member invitations, at least at the semantic level.
5. Consider tightening the open technical decisions so they are clearly implementation choices rather than unresolved readiness issues.

## Smallest viable iteration

The smallest useful slice is the one already described: Staff invite one email to one club; unknown invitees prove email control through the invitation link, enter a name, and become ordinary active members only after profile completion. Duplicate active-member blocking and duplicate pending-invitation resend should stay in the slice because they are necessary safety rules for a usable invitation flow.

## Required plan edits

None required before implementation.

## Validation plan

Success can be proven by:

1. Adding the planned `acceptance-tests/features/club_member_invitations.feature` scenarios.
2. Verifying Staff can invite by email without providing a name.
3. Verifying unknown invitees are not people or active members until they submit a non-blank name.
4. Verifying profile completion creates the person, creates ordinary active membership, accepts the invitation, consumes it for membership creation, signs the person in, and lands them in the club.
5. Verifying existing complete people can accept and join without repeating profile completion.
6. Verifying duplicate active-member invitations are blocked.
7. Verifying duplicate pending invitations resend and preserve one pending record.
8. Verifying abandoned profile completion leaves the invitation pending and reusable.
9. Verifying accepted-link reuse does not create duplicate memberships.
10. Verifying existing staff onboarding, member sign-in, and club navigation still work.
11. Running targeted domain/web/Cucumber tests and then `dev check`.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}