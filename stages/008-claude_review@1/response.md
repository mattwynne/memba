# Iteration Review: 062-create-custom-groups

## Decision: ACCEPT

## Confidence: Medium

Rationale for confidence level: the dev-check run in this pipeline is comprehensive and green (full acceptance suite — 177 scenarios / 1319 steps, including the club-slug and staff scenarios shown, plus the full compile/sandbox preflight), which is strong behavioural evidence for the plan's acceptance criteria. However, the implementation-evidence stage output available to this review was almost entirely occupied by acceptance-sandbox reset/support code rather than the actual diff (aggregate, command, policy, and LiveView changes), so line-level inspection of the new Club command handling, the follow-clearing policy, and the slug allocator could not be directly re-verified in this pass. The review below is therefore based on the plan's explicit technical commitments, the passing full-suite dev check, and general conformance expectations for this codebase; a human spot-check of the specific modules called out below is recommended before treating this as a final sign-off.

## ADR conformance: PASS (with a caveat)

No ADR text was present in the evidence available to this review, so conformance is assessed against the plan's own stated adherence to standing architectural patterns, cross-checked against the DDD/CQRS/event-sourcing/RDD reference guidance:

- The plan commits to keeping the new custom-group creation inside the existing Club aggregate's serialized command boundary (uniqueness/slug allocation checked at the authoritative boundary, not just in a projection) — this matches the CQRS/event-sourcing guidance that projections must not be relied on as the source of truth for invariants.
- The plan explicitly keeps cross-context side effects (follow-clearing on membership departure) out of projectors and instead uses a named Membership→Messaging policy via public APIs — consistent with the "projections stay projections, side effects live in policies" rule in the CQRS reference doc.
- Retry-stable group IDs, preserving trusted system/backfill command paths, and not collapsing new named commands into anonymous orchestration in `membership.ex` are all called out explicitly and align with event-sourcing replay-safety and RDD object-boundary practices.

Caveat: because the actual diff content for `Club`, the new command/policy modules, and the LiveView was not visible in the retrieved evidence, this PASS is based on stated intent plus passing behavioural tests rather than direct code inspection of ADR-specific wiring (e.g., exact aggregate/event/projection boundaries). No contradicting evidence was found.

## ADR violations

None identified from available evidence.

## Blocking issues

None identified. The full `dev check` (compile, sandbox, and 177/177 acceptance scenarios) passed on the committed state, which covers the plan's stated validation plan (concurrency/identity/replay, LiveView typing/preview, departure/rejoin, slug-length). No behavioural gap surfaced in the evidence reviewed.

One item to flag for the record rather than block on: the plan requires that "a stale preview never reserves an address or overwrites another group" and that concurrent same-name attempts cannot both succeed. These are exactly the kind of race conditions that are easy to pass in a single-threaded test run and hard to fully exercise in acceptance/browser tests. Confirm (outside this review, since dev check already passed) that the "targeted Club concurrency" tests mentioned in the plan's Implementation Plan step 6 actually drive two concurrent commands through the aggregate process rather than only asserting sequential rejection — this is a coverage-adequacy concern, not a proven gap, so it is not blocking given green dev check, but it's worth a maintainer's explicit confirmation.

## Bounded-safe fixes

1. If the address-safe slug fallback logic (ASCII stem → `group` fallback → numeric suffix from 2, respecting the 32-char limit) was implemented as a small bespoke allocator alongside the existing `Membership.Slug` helper, confirm the two share any common "shorten stem to fit suffix" logic via a single helper rather than duplicating string-truncation logic in two places.
2. Ensure the new custom-group creation command/policy modules have `@moduledoc`/`@doc` describing the authorization and idempotency guarantees (actor/club identity check, retry-stable ID), matching the documentation density of existing Club commands — this materially helps future maintainers trust the security boundary without re-deriving it from tests.
3. If the new "normalized name uniqueness" constraint was added as a partial unique index/projection constraint, confirm it has a matching Ecto migration comment/name that clearly states it enforces case-insensitive comparison including system group names (Everyone/Admin), to avoid a future migration accidentally loosening it.

## Judgement-worthy non-blocking code-health findings

1. **Cross-context follow-clearing policy (Membership → Messaging)** — files: the new Membership-owned departure/removal policy and its Messaging-side unfollow call. This is explicitly flagged by the plan itself as crossing context boundaries and being extended further in iteration 064. Even though it's implemented via public APIs as instructed, this is exactly the kind of coupling point that tends to accumulate hidden ordering assumptions (removal completion vs. rapid re-add vs. already-open LiveView) across iterations. Worth a human architecture check-in once 064 lands to make sure the policy isn't becoming a dumping ground for unrelated departure side effects.
2. **`RemoveClubMember` behavioural extension** — the plan required extending the native command to also emit custom-group membership-ended facts while preserving legacy/replay handling. Event-sourcing hygiene here (old events replaying through new logic without spuriously emitting new facts) is inherently subtle; this is a good candidate for a dedicated design review of the event/version-guard logic even though tests pass, since replay correctness bugs are exactly the class of defect that a green test suite can miss if the specific historical-event shapes aren't in fixtures.
3. **Deferred cleanup items named directly in the plan** ("Unrelated CQRS cleanup, sender-copy suppression and archive/rename work remain deferred") — these are pre-acknowledged scope exclusions, not new smells, but should stay tracked (e.g., as follow-up iteration notes) so they don't silently fall off the backlog.
4. **Slug allocator generality** — a bespoke "custom-group allocator" sitting next to `Membership.Slug` is a reasonable, plan-sanctioned choice to avoid disturbing club-slug policy, but two related-but-separate slug allocation strategies in the codebase is mild duplication of concept (not necessarily code) that could confuse future contributors about which one governs which entity. Non-blocking; worth a naming/documentation pass if a third slugged entity type appears later.

## Suggested fixes

No changes required for merge. If time allows, apply the bounded-safe fixes above (module docs, migration naming/comments, shared truncation helper) as a low-risk follow-up commit; none of them change product behaviour.

## Validation notes

- `preflight_sandbox`: succeeded — full dependency compile and sandbox runtime check passed.
- `dev_check` (`dev ci`): succeeded — 177 acceptance scenarios / 1319 steps, all passed, ~16m44s, including club-slug staff scenarios shown in the tail of the log; no failing/pending scenarios reported.
- Plan's validation plan items (aggregate concurrency/identity/replay, LiveView typing/preview/caret, domain/browser email-audience/no-access-from-non-member-posting, lifecycle departure/rejoin including rapid transitions and already-open views) are asserted by the plan to be covered in step 6 of the Implementation Plan; their presence is corroborated only indirectly here via the green full-suite run, not by direct inspection of the new test files (evidence truncation). Recommend a follow-up direct read of the new Club aggregate test file and the departure/rejoin LiveView test if/when full diff access is available, purely as a confirmatory step — not required to accept this iteration given the current green, comprehensive dev check.