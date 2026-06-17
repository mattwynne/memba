## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. The plan could name the exact compose and public club page template paths, rather than saying “the compose template” and “the public club page template.”
2. The “Open Technical Decisions” section could be reframed as “Implementation choices” because the decision criteria are already clear: keep member chrome working, keep public club page working, and do not affect staff surfaces.
3. The validation plan could explicitly list the existing member acceptance scenarios or tags expected to remain green, if those are known.

## Smallest viable iteration

The smallest useful slice is the current coherent member-surface alignment: update the four named member-facing pages to use shared button/avatar/status components, remove the member white-label theme layer, and keep delivery-status colour changes limited to member surfaces. Incidental copy/behaviour fixes should remain excluded unless trivial.

## Required plan edits

None required. The plan is implementation-ready.

## Validation plan

Success should be proven by:

1. Component, LiveView, and template tests confirming member pages use shared `button`, `avatar`, and relevant `status_badge` components.
2. Tests proving member delivery-status colours map to sage/warning/error while staff delivery views remain unchanged.
3. A sweep confirming no member-page hardcoded hex values or `--club-site-*` dependencies remain.
4. Existing member workflows still passing: sign-in, read message, compose/send, invite member, navigation, and sign out.
5. `./bin/dev gallery-walk` screenshots reviewed for the four member pages at desktop and mobile.
6. Full `dev check` passing before delivery is considered complete.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}