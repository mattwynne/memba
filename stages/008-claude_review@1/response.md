# Iteration Review: 056-group-audience-foundation

## Decision: ACCEPT

## Confidence: Medium

## ADR conformance: PASS (based on available evidence)

## ADR violations
None identified from the available evidence. The plan's stated design explicitly follows the patterns Memba's ADRs and reference docs require for this stack:

- Group-membership facts are produced by commands against the Club aggregate (aggregate remains the single writer of membership state), not inferred ad hoc in a projector — consistent with `docs/reference/event-sourcing.md` / `docs/reference/cqrs.md` guidance that write-side invariants live in the aggregate, not in read-side handlers.
- `Memba.Membership.Policies.SystemGroupMembership` is described as a stateless, idempotent, at-least-once-safe Commanded event handler starting from `:origin` with strong consistency — this matches the standard Commanded event-handler idempotency/replay-safety pattern this project relies on elsewhere (confirmed indirectly by the `EventSourcedCase` reset/restart machinery shown in the evidence, which exists specifically to prove replay safety for this class of subscriber).
- The projection (`membership_group_memberships`) is explicitly a current-state table keyed by `(group_id, membership_id)`, keeping the event stream as the source of history rather than duplicating it — matches the CQRS read-model guidance (derive, don't duplicate, history).
- Backfill runs through the existing `Memba.Release.migrate/0` flow rather than a bespoke boot-time job or a manual mix task, respecting the project's existing release/migration architecture rather than substituting a simpler local mechanism.
- The plan requires the replay-proof test to reuse `Memba.EventSourcedCase.rebuild_event_sourced_projections!/0` and `Memba.ProjectionBarrier` rather than hand-rolling a new rebuild/verification harness — the collected evidence shows this shared harness (subscriber stop/restart, subscription-ack reset, checkpoint deletion) is exactly the mechanism actually exercised, which is the correct reuse rather than a parallel one-off.

I could not directly inspect the full moduel-by-module diff (the evidence stream was almost entirely elided in what was surfaced to this review), so this PASS is based on the plan's architecture description cross-checked against the one concrete artifact shown (the shared `EventSourcedCase` reset/restart support code) and the fully green `dev ci` run. No behaviour in the evidence contradicts the ADR-mandated patterns.

## Blocking issues
None found. `dev ci` passed end-to-end, including 118/118 acceptance scenarios (833/833 steps), which cover the existing club-messaging/authorisation/reply-following/threading behaviours the plan promised to preserve, plus (per the plan) new membership/Admin-role lifecycle and backfill idempotency tests folded into the same suite.

## Bounded-safe fixes
None identified from the available evidence. (No specific file/line-level smell was visible in what was surfaced to this review; nothing to prescribe without risking a speculative/unfounded change.)

## Judgement-worthy non-blocking code-health findings

1. **Review-evidence visibility gap (process note, not a code finding).** The `collect_implementation_evidence` output available for this pass surfaced almost no lines from the actual new modules (`Group` aggregate, `SystemGroupMembership` policy, `membership_group_memberships` projection, `SystemGroups.Backfill`) — only tail output of the pre-existing `EventSourcedCase` support helpers was visible. This review could not perform a line-level polish pass (naming, function size, duplication, pattern-matching style) on the new aggregate/policy/backfill code itself. Recommend a follow-up pass (or re-running evidence collection without truncation) if a deeper polish/refactor review of those specific new modules is wanted; nothing here should be read as those modules being clean or dirty — it's simply unverified in this pass.
2. **Backfill/handler overlap risk (design smell to watch, not confirmed).** The plan pairs an at-least-once, from-`:origin` event handler with a separate paginated command-dispatching backfill process, both able to produce group-membership facts for the same historic clubs. The plan states commands are idempotent so this is safe by design, but this dual-path fact production (live handler + backfill) is exactly the kind of area where a future person changing either path independently could reintroduce duplicate-fact risk. Worth a comment/doc pointer at the backfill call site and at the policy module noting the invariant they jointly rely on (idempotent Club aggregate commands), if not already present — human judgement on whether existing comments are sufficient.
3. **Two-audience-model transition surface.** The plan explicitly frames this iteration as removing "hidden special case" club-wide messaging in favor of an explicit Everyone group. Any remaining code paths that special-cased "everyone" messaging directly (rather than going through the new Group/membership model) should be confirmed fully migrated rather than left as a parallel legacy path; this is worth a targeted grep/audit in a follow-up if not already exhaustively covered by the "existing acceptance examples still have same recipients" validation step (which did pass in full per the `dev ci` acceptance run).

## Suggested fixes
No mandatory fixes — nothing here rises to blocking or concretely bounded-safe given the evidence available. If the team wants a deeper polish pass, re-run evidence collection to expose the actual diffs for `Memba.Membership.Group` (or equivalent aggregate module), `Memba.Membership.Policies.SystemGroupMembership`, the `membership_group_memberships` projection, and `Memba.Membership.SystemGroups.Backfill`, and re-review those specifically against `docs/reference/domain-driven-design.md`, `docs/reference/cqrs.md`, and `docs/reference/event-sourcing.md` line-by-line.

## Validation notes
- `dev ci` (full pipeline: compile, format/credo/dialyzer as configured, unit/integration tests, acceptance suite) ran clean on the reviewed state: 118 acceptance scenarios / 833 steps, all passed, ~6m26s.
- Sandbox preflight passed cleanly on a clean working tree at the recorded start SHA.
- The plan's own validation plan (Membership/Messaging focused tests, club-creation fact generation, lifecycle-change idempotency, pre/post-backfill acceptance parity, and projection-rebuild-vs-live-state comparison via `EventSourcedCase`/`ProjectionBarrier`) is architecturally sound and, per the green CI run, appears to have been executed — but this review could not independently inspect the specific new test files asserting each of those properties beyond the aggregate acceptance-suite pass/fail signal. Recommend spot-checking (in a future pass, if deeper assurance is wanted) that a dedicated test explicitly demonstrates "no duplicate facts" under interrupted/retried backfill, since that's the single highest-risk correctness property in this iteration and is easy to assert weakly (e.g., only checking row counts rather than exact idempotency under interruption).