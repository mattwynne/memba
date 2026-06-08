## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. Specify the malformed/invalid email-address behaviour if it is not already fully inherited from the iteration 028 Staff invitation flow.
2. If the delivery team wants tighter UI predictability, choose the preferred direct-access rejection style up front: forbidden page, redirect with flash, or not-found-style concealment.
3. Consider naming likely implementation modules/routes after iteration 028 lands, but the current plan is still specific enough to implement.

## Smallest viable iteration

The smallest useful slice is exactly the core Membership Admin invitation path:

- A signed-in active club member with `club.manage_members` can invite one ordinary member by email for their own club.
- The invitee receives a one-use invitation link.
- Unknown invitees provide a name before activation.
- Existing complete people can accept without re-entering a name.
- Ordinary members cannot see or use the invitation flow.
- Duplicate active membership is rejected.
- Duplicate pending invitation resends and preserves one pending invitation.

The plan appropriately leaves pending invitation management, expiry, bulk invitations, role choice, richer onboarding, and alternate-email verification out of scope.

## Required plan edits

None required.

## Validation plan

Success can be proven by:

1. Adding or updating the planned `acceptance-tests/features/club_member_invitations.feature` scenarios tagged `@iteration-029`.
2. Verifying Membership Admin happy path invitation and invitee activation.
3. Verifying ordinary members cannot see or directly use the invitation action.
4. Verifying duplicate active-member rejection.
5. Verifying duplicate pending invitation resend without creating another pending record.
6. Verifying accepted invitations create ordinary active memberships only.
7. Verifying the Staff invitation flow from iteration 028 still works.
8. Running the relevant Cucumber scenarios with todo tags removed or narrowed once passing.
9. Running `dev check`.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}