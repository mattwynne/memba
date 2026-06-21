## Decision: READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/042-club-email-subdomains/plan.md`.

## Blocking gaps

1. None.

## Non-blocking improvements

1. Clarify whether implementation may proceed if Matt’s Postmark/DNS wildcard setup is not yet complete, with the production smoke test deferred until after the external prerequisite. The plan already names the prerequisite, but an explicit “app implementation can proceed; production smoke is blocked until DNS/Postmark is ready” note would reduce ambiguity.
2. Name the likely app modules/helpers once discovered, if known from prior iterations. The current implementation plan is specific enough, but naming modules would make handoff slightly faster.
3. Consider explicitly stating the expected rejection reason/copy for the old flat address versus unsupported local part. The plan allows implementer discretion, which is acceptable, but stricter copy expectations would make acceptance testing more precise.

## Smallest viable iteration

The smallest useful slice is the hard cutover of club-wide inbound email from `<club-slug>@clubs.memba.io` to `everyone@<club-slug>.clubs.memba.io`, including:

- address display updates on member-facing surfaces;
- inbound parsing/resolution for `everyone@<club>.clubs.memba.io`;
- rejection of unsupported local parts, unknown club subdomains, unsupported domains, and the old flat address;
- preservation of existing inbound authorization/message semantics;
- reply destination update while preserving iteration 041 header-based reply routing;
- updated tests, docs, smoke-test defaults, and `dev check`.

That slice is coherent and already matches the plan. Cutting it smaller would risk shipping a visible address that either cannot receive mail or cannot be validated end-to-end.

## Required plan edits

None.

## Validation plan

Success should be proven by:

1. Unit/domain tests showing `kmc` renders as `everyone@kmc.clubs.memba.io`.
2. Destination-resolution tests proving:
   - `everyone@kmc.clubs.memba.io` resolves to KMC;
   - unsupported local parts are rejected;
   - unknown club subdomains are rejected;
   - unsupported domains are rejected;
   - `kmc@clubs.memba.io` is rejected/no longer accepted.
3. Acceptance tests updated or enabled for the new address shape, including primary sender, alternate sender, unknown sender, non-member, unsupported attachments, HTML-only/missing plain text, and body handling behaviours.
4. UI/member-facing tests asserting dashboard and compose surfaces display/mailto the new canonical address.
5. Reply-by-email tests proving reply emails expose `everyone@<club>.clubs.memba.io` while routing still depends on recognized same-club `In-Reply-To` / `References` headers.
6. Documentation and smoke-test config updated for wildcard Postmark/DNS and `everyone@test.clubs.memba.io`.
7. Production inbound smoke test passing after Matt completes the external Postmark/DNS setup.
8. `dev check` passing.

{"context_updates":{"gemini_review_decision":"READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":0,"gemini_review_blocking_gaps":"None","gemini_review_required_edits":"None"}}