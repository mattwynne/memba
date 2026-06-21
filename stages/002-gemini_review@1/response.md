## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. Clarify the implementation stop condition if Matt’s Postmark/DNS prerequisite is delayed or unavailable during the implementation window, since the production smoke test depends on external setup.
2. Consider naming the most likely code modules/files for inbound address generation and destination resolution if the author wants to reduce implementation discovery time further.
3. Consider explicitly stating whether old flat-address rejection should produce a distinct rejection reason or may share the unsupported-recipient pathway; the current plan allows implementer judgment, which is reasonable.

## Smallest viable iteration

The smallest useful slice is exactly the planned hard cutover for the single `everyone` route:

- Generate/display `everyone@<club-slug>.clubs.memba.io`.
- Accept inbound mail only for `everyone@known-club.clubs.memba.io`.
- Reject unsupported local parts, unknown club subdomains, unsupported domains, and old flat addresses.
- Preserve existing authorization, delivery, rejection, and reply-header semantics.
- Update tests, acceptance scenarios, docs, and smoke-test configuration for the new address shape.

Further routes such as aliases, channels, groups, or compatibility forwarding should remain out of scope.

## Required plan edits

None required.

## Validation plan

Success can be proven by:

1. Unit/domain tests showing `kmc` renders as `everyone@kmc.clubs.memba.io`.
2. Destination-resolution tests proving:
   - `everyone@kmc.clubs.memba.io` resolves to KMC.
   - unsupported local parts are rejected.
   - unknown club subdomains are rejected.
   - unsupported domains are rejected.
   - `kmc@clubs.memba.io` is no longer accepted.
3. Acceptance tests proving primary and alternate member senders can create club messages through the new address.
4. Existing rejection-path tests rerun under the new address shape for unknown senders, inactive members, non-members, unsupported attachments, and missing usable plain text.
5. Reply-by-email tests proving `Reply-To` uses the new visible destination while `In-Reply-To` / `References` continue to control reply routing.
6. UI tests proving the member dashboard and compose surfaces show the new address and mailto link.
7. Documentation/runbook review confirming wildcard Postmark/DNS setup and smoke-test defaults use `*.clubs.memba.io` and `everyone@test.clubs.memba.io`.
8. Production inbound smoke test passing after Matt confirms wildcard Postmark/DNS configuration.
9. `dev check` passing.

{"context_updates":{"gemini_review_decision":"READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":0,"gemini_review_blocking_gaps":"None","gemini_review_required_edits":"None"}}