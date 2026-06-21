## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. Name the most likely modules/files for the inbound address helper, destination resolver, dashboard/compose UI, and reply email generation if the author wants implementation to be faster.
2. Clarify the implementation dependency on iteration 041’s final merged shape: whether 042 should wait for 041 to be merged, or adapt in-branch if both are active.
3. Make the external prerequisite stop condition slightly more explicit: if Matt has not completed Postmark/DNS wildcard setup, implementation can complete app changes and `dev check`, but production smoke validation remains pending.

## Smallest viable iteration

The smallest useful slice is the hard cutover of the canonical club-wide inbound address from `<club-slug>@clubs.memba.io` to `everyone@<club-slug>.clubs.memba.io`, including:

- address generation/display on member-facing surfaces;
- inbound recipient parsing and rejection of unsupported local parts, unknown club subdomains, unsupported domains, and the old flat address;
- preservation of existing authorization/body/idempotency/rejection semantics;
- reply email visible destination updated to the new address while preserving iteration 041 header-based routing;
- acceptance/domain tests and production smoke-test config/docs updated to the new shape.

That slice is coherent and already matches the plan’s scope.

## Required plan edits

None required before implementation.

## Validation plan

Success should be proven by:

1. Unit/domain tests showing `kmc` renders as `everyone@kmc.clubs.memba.io`.
2. Destination resolution tests proving:
   - `everyone@kmc.clubs.memba.io` resolves to KMC;
   - unsupported local parts are rejected;
   - unknown club subdomains are rejected;
   - unsupported domains are rejected;
   - `kmc@clubs.memba.io` is no longer accepted.
3. Existing inbound email behaviour tests rerun under the new address shape, including primary email, alternate email, unknown sender, inactive/non-member, attachment rejection, missing usable plain text, and body handling.
4. Reply-by-email tests confirming replies still route by recognized same-club `In-Reply-To` / `References` headers while visible reply destinations use `everyone@<club-slug>.clubs.memba.io`.
5. UI tests confirming dashboard and compose surfaces display/mailto the new address.
6. Acceptance feature scenarios updated or un-todoed as implementation makes them executable.
7. Postmark/DNS and smoke-test docs/config updated for `*.clubs.memba.io` and `everyone@test.clubs.memba.io`.
8. `dev check` passing.
9. After Matt completes wildcard Postmark/DNS setup, production inbound smoke test passing against `everyone@test.clubs.memba.io`.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}