## Decision: READY

## Confidence: High

I read the complete plan directly from `docs/iterations/022-request-to-club-onboarding/plan.md` lines 1–238.

## Blocking gaps

1. None.

## Non-blocking improvements

1. The plan lists several “Open Technical Decisions.” They are implementation-level choices rather than plan-blocking gaps, but the author could reduce delivery ambiguity by adding preferred defaults, especially for:
   - request context/module location;
   - magic-link post-auth return URL handling;
   - email side-effect handling around the conversion transaction.
2. The acceptance criteria are strong, but the plan could explicitly state whether rejection notes are required at the acceptance-criteria level, since the implementation plan says “required internal notes.”
3. The feature-file plan says Matt should review the feature language before removing `@wip`; if this review is mandatory for delivery, it could be listed as a stop-condition dependency.

## Smallest viable iteration

The smallest useful slice is the full staff-approved onboarding loop already described: public/signed-in request capture, staff active inbox, reject, convert to club/member, and welcome magic link. A smaller request-only slice would not deliver the key business outcome of safely onboarding real clubs without public self-serve access.

## Required plan edits

None required.

## Validation plan

Success should be proven by:

1. Creating `acceptance-tests/features/request_account.feature` with the planned stakeholder-readable scenarios.
2. Verifying `/get-started` accepts valid requests, rejects invalid/missing fields, sends staff notification, and creates no club/member/access.
3. Verifying signed-in requesters use read-only known identity details.
4. Verifying `/admin/requests` is staff-only and lists active requests with required fields.
5. Verifying rejection records internal notes, removes the request from active inbox, sends no requester email, and creates no access.
6. Verifying conversion reuses existing slug behavior, blocks invalid/taken slugs, creates the club, reuses or creates the person, creates active membership, marks the request converted, removes it from the active inbox, and sends the welcome magic link.
7. Verifying the welcome magic link lands the requester on the new club member home.
8. Verifying existing staff club creation/slug behavior and existing authentication behavior still pass.
9. Removing `@wip` from the acceptance feature only once scenarios pass.
10. Running `dev check` before delivery is considered complete.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}