# Iteration 057 Review: Admin Group Email Conversations

## Decision: ACCEPT

## Confidence: Medium

## ADR conformance: PASS

## ADR violations
None identified. Across all three independent review passes, the implementation evidence is consistent with Memba's event-sourcing/CQRS boundaries:

- Email slug identity is modeled as an aggregate-owned, immutable routing key, distinct from group display name and system-group identity — matching DDD/event-sourcing guidance on identity ownership.
- Messaging authorization is represented as projected conversation-to-group access (`ConversationGroupAccess`) rather than inferred at query time from recipients — matching the read-model/query-side separation CQRS requires.
- The `club_members_only` new-conversation policy is implemented as a fixed named policy boundary rather than an ad hoc persisted setting, matching the plan's explicit deferral.
- Existing provider/message-keyed inbound-email idempotency is preserved unchanged, and the group lookup does not introduce a second, conflicting notion of message identity.
- Existing Everyone-only web surfaces remain unchanged while the underlying group-ID query API becomes general — preparation without premature UI exposure, as the plan required.

No evidence surfaced of an ADR-mandated component (Commanded aggregate, projector, idempotency guard) being bypassed or replaced with a simpler local substitute in *product* code.

## Blocking issues
None in the reviewed product code. One process item needs resolution before this iteration is considered fully closed (see below), but it does not indicate a defect in the shipped behaviour.

1. **Unconfirmed persistence of the two review-repair edits.** `apply_review_fixes` reported editing `web/test/support/messaging_fixtures.ex`, `web/config/test.exs`, and `docs/specs/2026-09-02-groups-and-conversation-access-vision.md`, and stated the changes were "staged but not committed." The subsequent `verify_review_repair` step found **zero working-tree diff** between the pre- and post-repair snapshots. The most likely explanation is a verification-script gap (it compared unstaged `git diff` output, which will show nothing if the agent's edits were `git add`-staged), rather than the edits having been silently discarded — but this cannot be confirmed from the evidence provided. Before closing the iteration, a human (or a corrected verification step using `git diff --cached` or `git diff HEAD`) should confirm whether:
   - the Groups vision doc at `docs/specs/2026-09-02-groups-and-conversation-access-vision.md` actually reflects the accepted `club_members_only` new-conversation policy (the plan explicitly calls this out as required "before delivery"), and
   - the test-infrastructure documentation clarifications actually landed.
   This is flagged as blocking-for-closure rather than blocking-for-merge because it is documentation, not code, and does not affect ADR conformance, test coverage, or shipped behaviour.

## Bounded-safe fixes
1. `web/test/support/messaging_fixtures.ex`: `insert_group_accessible_message!/1` creates a `ConversationGroupAccess` grant only when `message_id == conversation_id` (i.e., only for roots); replies assume the root/grant already exist. This precondition should be stated explicitly in the function doc (not just inferable from the code), or split into two clearly named entry points (e.g., `insert_group_accessible_root_message!/1` and `insert_reply_message!/1`) so future callers can't misuse it for a reply without an existing root.
2. Same file: the `"write"` access-level literal is duplicated as a raw string default rather than referencing whatever canonical access-level vocabulary the `ConversationGroupAccess` schema/projector uses, if one exists. Point the fixture at that shared constant to avoid silent drift.
3. `web/config/test.exs`: the new 16-connection pool floor should carry an inline comment naming the single-scheduler-sandbox / Commanded 5-second consistency-timeout scenario it protects against, so it isn't later mistaken for arbitrary tuning and accidentally lowered.

## Judgement-worthy non-blocking code-health findings
1. **Fixture bypasses the command/aggregate path** (`web/test/support/messaging_fixtures.ex`) — Directly `Repo.insert!`-ing `Message` and `ConversationGroupAccess` rows is a standard, fast pattern for read-model/query-focused tests, but it means these tests can never catch a future invariant added at the command/aggregate layer (e.g., a new authorization rule enforced in the domain but not mirrored in the fixture). Worth confirming, per the plan's Validation Plan, that the *other* focused tests for group destination resolution, sender policy, and reply authorisation actually exercise real commands/events rather than only this fixture.
2. **Test-pool floor is a fixed magic number tied to current concurrency** (`web/config/test.exs`) — The 16-connection minimum solves today's single-scheduler sandbox starvation but is coupled to the current number of concurrently-acknowledging projectors. It may go stale (too low) if projector count grows, or mask a genuine responsiveness problem in the consistency-wait path rather than fixing it. Not a merge blocker; worth a future look at making the consistency wait itself more robust rather than only widening the pool.
3. **Known redundant root-message delivery to an Admin sender** — Explicitly and correctly deferred by the plan; flagged here only so it isn't inadvertently "cleaned up" later without a product decision on whether sender copies are delivery records, mailbox copies, or both.

## Suggested fixes
- Re-run (or manually confirm) the Groups vision doc update and test-infrastructure documentation edits using `git diff --cached`/`git diff HEAD` rather than plain `git diff`, since the repair agent reported staging rather than committing its changes.
- Apply bounded-safe fixes 1–3 above as low-risk follow-up polish; none are required to keep this merged, but 1–2 reduce real drift risk in the Messaging test suite.

## Validation notes
- `dev check` (`dev ci`) passed on the committed state both before and after the test-infra fix, with the full Cucumber acceptance suite green (122 scenarios / 877 steps) and 1,129 unit/integration tests passing, including static/formatting checks.
- The only tracked change surfaced by `fix_dev_check` was `web/config/test.exs` (pool-size floor), scoped to test infrastructure; no product code, migration, or feature file was touched by that fix.
- All three independent review passes (Claude, Codex, Gemini) reached ACCEPT with PASS on ADR conformance and no blocking findings, converging on the same two non-blocking documentation/maintainability items now tracked as bounded-safe fixes above.
- No `*.feature` files were modified at any point in this review cycle, preserving acceptance criteria as originally authored.
- The `verify_review_repair` failure (no working-tree diff detected after the claimed doc/test edits) is a validation gap in the *review process*, not in the underlying implementation's dev-check evidence; it should be resolved by re-verifying against the index/HEAD rather than re-running the full implementation.