# Problem: review repair loop repeated without a verified diff

Date: 2026-07-05

## Context

We were processing queued iterations one at a time. After iteration 045 was implemented and published, we ran the Fabro review workflow:

```sh
bin/dev fabro review origin/main docs/iterations/045-club-home-section-tabs/plan.md bcc2749ab7813feab4e1c2f78ca029f0765559e4
```

Review run:

- Run ID: `01KWSYX4PFNK20DXMEPFR9PRFK`
- URL: `https://fabro.home.wynne.family/runs/01KWSYX4PFNK20DXMEPFR9PRFK`
- Plan: `docs/iterations/045-club-home-section-tabs/plan.md`
- Implementation commit reviewed: `cb0ec9ca73e97792428b53d1ef082faa734c91c1`

The review synthesis found bounded blockers around the club-home tabs:

- `fix-club-home-tab-state-js`
- `fix-club-home-tab-aria-relationships`
- `fix-club-home-tab-js-coverage`

## Expected standard

The iteration-review workflow should either:

- apply bounded review repairs, produce a concrete code/test/config diff, verify it, run `dev check`, and publish the polish; or
- if automatic repair cannot make progress, stop with clear human-input evidence after preserving the review findings.

A failed repair-verification step should not repeatedly spend full review cycles without new evidence or a changed repair strategy.

## What happened

The workflow reached `Apply Review Fixes`, then `Verify Review Repair` failed with:

```text
If no code/config/test changes were required, route to human input or make the repair prompt explicitly justify that ...
```

Instead of stopping or escalating, the workflow continued into another full review cycle. It repeated this pattern more than once:

- `Apply Review Fixes`
- `Verify Review Repair` failure with the same class of message
- `Run Dev Check`
- independent reviews
- synthesis
- another repair attempt

The run finally failed with:

```text
Failure: node "apply_review_fixes" visited 3 times (node limit 3); run is stuck in a cycle
```

The final output still reported open blockers, so the operator had to take over manually and inspect/fix the tab JS, ARIA relationships, and tests.

## Impact

This wasted a long review cycle before producing an actionable terminal signal:

- Duration: about 56 minutes.
- Cost reported by Fabro: about `$8.08`.
- Several `dev check` and multi-model review passes were repeated after repair verification had already detected that the repair path was not making acceptable progress.
- The operator had to manually reconstruct the useful findings from a failed run rather than receiving a clean handoff after the first failed repair attempt.

The product code was protected by the workflow eventually failing, but the delivery pipeline consumed time and money and delayed the requested one-iteration-at-a-time flow.

## What allowed it to happen

The review workflow appears to treat repair-verification failure as retryable in the same loop as normal post-repair review, without a strong guard that distinguishes “repair made a verified diff but needs another review” from “repair produced no acceptable diff for the same blockers.”

The repair prompt or routing also seems weak at the no-diff boundary: the verification error explicitly says the workflow should route to human input or justify that no code/config/test changes were needed, but the graph proceeded to another expensive review-and-repair loop instead.

## Observations

- This is delivery-machinery friction, not an ordinary product bug.
- The independent review/synthesis stages did their job by identifying specific blockers.
- The abnormality was in the automatic repair loop after synthesis.
- The failure was only terminal after the node visit limit was reached, not at the first point where the repair verification knew the repair contract had failed.
- The final failure message was useful, but late.

## Why this matters

Review repair is supposed to shorten the feedback loop for small polish and refactoring findings. If it can loop through full review cycles after a no-progress repair attempt, small review findings become expensive and slow, and operators learn to distrust automatic repair as a handoff point.

## Open questions

- Did `Apply Review Fixes` produce no diff, produce a diff that was later discarded, or produce a diff that `Verify Review Repair` could not recognize?
- Should `Verify Review Repair` failure route directly to human input after one no-progress attempt for the same blocker IDs?
- Should synthesis remember that the same blocker IDs already had an unsuccessful automatic repair attempt and reclassify them as human/code-health rather than requesting another automatic repair?

## Possible prevention ideas

- Add a repair-progress gate that compares blocker IDs and diff stats before allowing another automatic repair cycle.
- If repair verification says no acceptable code/config/test changes were made, stop immediately with a human-actionable summary instead of running another full review cycle.
- Persist the attempted repair evidence and exact blocker IDs in the terminal output so manual takeover starts from a concise handoff.
- Add a workflow regression test for the no-diff repair-verification path.
