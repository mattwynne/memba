## Decision: READY

## Confidence: High

## Blocking gaps

0. None.

## Non-blocking improvements

1. Optionally add the exact command for running only the two relevant `homepage.feature` staff scenarios, if the project has a preferred targeted Cucumber invocation.
2. Optionally state explicitly that there are no data model, migration, API, workflow, integration, or background-job changes. This is already implied by the plan, but making it explicit would reduce reviewer ambiguity.

## Smallest viable iteration

The plan is already the smallest useful slice: replace the signed-in homepage’s existing staff nav affordance with the design-system staff bar, limited to the homepage, preserving the existing staff-access rule and feature scenarios.

## Required plan edits

None.

## Validation plan

Success can be proven by:

1. Updating `acceptance-tests/features/support/homepage.js` so the existing staff-access assertion targets the new staff bar.
2. Verifying the existing `acceptance-tests/features/homepage.feature` staff scenarios pass:
   - “Pat is Memba staff”
   - “Pat is staff and a club member”
3. Confirming staff users with and without clubs see the new bar and link.
4. Confirming signed-in non-staff users and signed-out visitors do not see the bar.
5. Confirming the old `#admin-home-link` button is gone from the signed-in nav.
6. Performing a narrow-screen visual check for no horizontal overflow.
7. Running `dev check` successfully.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}