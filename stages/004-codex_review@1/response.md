## Decision: READY

## Confidence: High

I read `docs/iterations/042-club-email-subdomains/plan.md` completely, including an EOF check after line 196. The plan is ready for implementation.

## Blocking gaps

None.

## Non-blocking improvements

1. Consider adding an explicit acceptance criterion for recipient address normalization, e.g. case-insensitive handling and angle-bracket/display-name parsing, since this is mentioned under implementation constraints.
2. Consider naming the likely concrete modules/files for address helper, destination resolution, and reply email generation if the implementer is expected to work quickly with minimal discovery.
3. Consider making the external stop condition slightly more explicit: app implementation can be complete before Matt’s DNS/Postmark change, but production smoke validation is blocked until that prerequisite is confirmed.

## Smallest viable iteration

The smallest useful slice is the hard cutover for the single `everyone` route:

- Generate/display `everyone@<club-slug>.clubs.memba.io`.
- Accept inbound messages only to that shape.
- Resolve the club from the subdomain.
- Reject unsupported local parts, unknown club subdomains, unsupported domains, and the old flat address.
- Preserve existing sender authorization, message creation, rejection, and reply-by-email header routing.
- Update member-facing UI, reply destination, tests, docs, and smoke-test configuration for this one canonical address shape.

The plan already excludes channels, aliases, old-address compatibility, custom domains, and rejected-email UI, so it is appropriately focused.

## Required plan edits

None.

## Validation plan

Success can be proven by:

1. Unit/domain tests showing `kmc` renders as `everyone@kmc.clubs.memba.io`.
2. Destination-resolution tests proving:
   - `everyone@kmc.clubs.memba.io` is accepted.
   - unsupported local parts are rejected.
   - unknown club subdomains are rejected.
   - unsupported domains are rejected.
   - `kmc@clubs.memba.io` is rejected/no longer accepted.
3. Acceptance tests for inbound club email under the new address shape, including primary email, alternate email, unknown sender, non-member, unsupported attachments, HTML-only/missing plain text, and existing message-processing semantics.
4. Reply-by-email tests confirming the visible reply destination changes while `In-Reply-To` / `References` still drive reply-vs-new-message routing.
5. UI tests confirming dashboard and compose surfaces display the new address and mailto link.
6. Documentation/runbook review confirming wildcard Postmark/DNS setup and smoke-test address updates.
7. Production inbound smoke test passes against `everyone@test.clubs.memba.io` after Matt completes Postmark/DNS setup.
8. `dev check` passes.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}