## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. The plan lists several open technical decisions. They appear implementation-level rather than readiness-blocking, but the author could reduce ambiguity by turning them into “implementation discretion” notes or preferred defaults.
2. Clarify whether existing persisted non-test clubs need a production backfill, or whether this iteration only guarantees the default role for newly converted clubs plus test/dev fixtures.
3. Name likely modules, projections, or migration files if the project conventions are already known. The current implementation plan is clear enough, but more file-level pointers would speed delivery.
4. Clarify whether the planned Cucumber feature will be domain-only at first despite the `@todo-ui` tag, since the member-facing admin UI is explicitly out of scope.

## Smallest viable iteration

The smallest useful slice is essentially the current one: introduce one app-defined permission, `club.manage_members`; create one default club role, Membership Administrator; assign it to the approved requester/first member during onboarding conversion; project permission checks by club/person; support domain/application-level grant/revoke of that role for active members; and enforce that a club is not left with zero Membership Administrators. Defer invite-by-email, custom role editing, fine-grained permissions, and member-facing admin UI.

## Required plan edits

None required before implementation.

## Validation plan

Success should be proven by:

1. New stakeholder-readable Cucumber scenarios in `acceptance-tests/features/club_membership_administration.feature`, with planning tags removed once implemented.
2. Domain/application tests proving:
   - default Membership Administrator role creation;
   - `club.manage_members` is granted to that role;
   - approved requester/first member receives the role during conversion;
   - permission projection answers whether a person can manage members in a club;
   - a member with `club.manage_members` can grant Membership Administrator to another active member;
   - an ordinary member cannot grant it;
   - the last Membership Administrator cannot be revoked or removed.
3. Regression coverage for existing onboarding conversion behaviour: club creation, requester/member creation or reuse, membership creation, request conversion state, and welcome email.
4. Existing member sign-in and membership behaviours continue to pass.
5. `dev check` passes.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}