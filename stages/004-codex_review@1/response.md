## Decision: READY

## Confidence: High

The plan file was read directly and completely from `docs/iterations/042-club-email-subdomains/plan.md`. No files were edited. The plan already has `Status: validated`.

## Blocking gaps

None.

## Non-blocking improvements

1. Consider naming the most likely implementation modules/files after the initial inspection step, if they are already known, to reduce implementation discovery time.
2. Consider specifying whether rejection copy must be user-visible, staff-visible, logged-only, or webhook-response-only for unsupported local parts and unknown club subdomains.
3. Consider adding a brief contingency note for the production smoke test if Matt’s Postmark/DNS prerequisite is not ready when implementation finishes.

## Smallest viable iteration

The smallest useful slice is the hard cutover of the canonical club-wide inbound address from `<club-slug>@clubs.memba.io` to `everyone@<club-slug>.clubs.memba.io`, including:

- address generation/display on member-facing surfaces,
- inbound destination parsing and club resolution,
- rejection of unsupported local parts, unknown club subdomains, unsupported domains, and the old flat address,
- reply notification destination update while preserving header-based reply routing,
- tests/acceptance scenarios proving the new shape,
- docs and smoke-test config updates for the wildcard Postmark setup.

That slice is coherent and appropriately sized because the visible address, inbound parser, reply destination, docs, and smoke-test expectations all need to move together for the cutover to be usable.

## Required plan edits

None.

## Validation plan

Success should be proven by:

1. Unit/domain tests confirming address generation renders `everyone@kmc.clubs.memba.io`.
2. Destination-resolution tests confirming:
   - `everyone@kmc.clubs.memba.io` is accepted,
   - unsupported local parts are rejected,
   - unknown club subdomains are rejected,
   - unsupported domains are rejected,
   - the old flat `kmc@clubs.memba.io` address is rejected or no longer accepted.
3. Existing inbound club-email acceptance coverage rerun under the new address shape for primary sender, alternate sender, unknown sender, non-member, attachment rejection, HTML-only rejection, and quote/signature stripping.
4. Reply-by-email tests from iteration 041 rerun with the new visible reply destination while preserving header-based reply routing.
5. Member dashboard and compose tests asserting the new displayed address and `mailto:` link.
6. Documentation/runbook review confirming wildcard Postmark/DNS setup and smoke-test address `everyone@test.clubs.memba.io`.
7. Production inbound smoke test passing after Matt completes the Postmark/DNS prerequisite.
8. Full `dev check` passing.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}