## Decision: READY

## Confidence: High

## Blocking gaps

1. None.

## Non-blocking improvements

1. The plan could make recipient normalization a first-class acceptance criterion, not only an implementation constraint, by explicitly saying mixed-case recipients, display-name-wrapped addresses, and angle-bracket addresses still resolve safely.
2. If iteration 041 is already complete when implementation starts, update wording that says “041 is in progress” to avoid stale context.
3. The implementation plan could name likely concrete modules/files for the address helper and resolver, but it is already specific enough to implement.

## Smallest viable iteration

The smallest useful slice is the planned hard cutover:

- Generate and display `everyone@<club-slug>.clubs.memba.io`.
- Accept inbound club-wide messages only at `everyone@<known-club>.clubs.memba.io`.
- Reject unsupported local parts, unknown club subdomains, unsupported domains, and the old flat `kmc@clubs.memba.io` address without creating messages.
- Preserve existing authorization, sender matching, body handling, idempotency, delivery, rejection, and reply-by-email header routing semantics.
- Update acceptance coverage, docs, smoke-test configuration, and run the smoke test after Matt completes Postmark/DNS setup.

Splitting out docs/smoke updates would reduce proof of the production cutover, so keeping them in this iteration is appropriate.

## Required plan edits

None required for readiness.

## Validation plan

Success should be proven by:

1. Unit/domain tests showing `kmc` renders as `everyone@kmc.clubs.memba.io`.
2. Resolver tests accepting `everyone@kmc.clubs.memba.io` and rejecting unsupported local parts, unknown club subdomains, unsupported domains, and the old flat address.
3. Acceptance scenarios passing for primary sender, alternate sender, unknown sender, inactive/non-member rejection, attachment rejection, missing plain text/HTML-only rejection, and body stripping under the new address shape.
4. Reply-by-email tests confirming the visible reply destination is `everyone@<club-slug>.clubs.memba.io` while `In-Reply-To` / `References` continue to determine replies.
5. UI tests confirming member dashboard and compose surfaces display the new address and mailto link.
6. Documentation and smoke-test config review confirming wildcard Postmark/DNS setup and `everyone@test.clubs.memba.io`.
7. Production inbound smoke test passing after Matt completes Postmark/DNS setup.
8. Full `dev check` passing.

{"context_updates":{"gemini_review_decision":"READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":0,"gemini_review_blocking_gaps":"None","gemini_review_required_edits":"None"}}