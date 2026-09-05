# Iteration 057 Review: Admin Group Email Conversations

## Decision: ACCEPT

## Confidence: Medium

## ADR conformance: PASS (with a visibility caveat — see Validation notes)

## ADR violations
None identified from the available evidence. The plan's stated constraints (immutable email slug as a distinct routing key from group display name and system-group identity; fixed named policy boundary rather than a persisted setting; provider/message-keyed email idempotency preserved for the new group lookup) are consistent with event-sourcing/CQRS separation of concerns (aggregate-owned identity/slug, projection-driven read model, idempotent command handling) and nothing in the visible evidence contradicts them. I was not able to directly re-read the full diff of aggregate/command/projection code in this session (the implementation-evidence tool output was truncated to its final ~200 lines, showing only `MembaWeb.MessagingFixtures`), so this PASS should be treated as "no contradicting evidence found," not an exhaustive line-by-line ADR audit.

## Blocking issues
None identified from the available evidence.

- Dev check passed cleanly both before and after the `fix_dev_check` stage, including the full Cucumber acceptance suite (122 scenarios / 877 steps, all passed) and the unit/integration suite.
- The only code change in `fix_dev_check` (`web/config/test.exs` pool-size minimum) is test-infrastructure-only and does not touch product code, migrations, or feature files, so it does not reopen the plan-conformance gate.
- Nothing in the plan's stated capability, risks, or open decisions surfaces an unaddressed gap based on the evidence reviewed.

## Bounded-safe fixes
1. `web/test/support/messaging_fixtures.ex`: the fixture hardcodes `access_level: Keyword.get(attrs, :access_level, "write")` as a raw string literal. If the domain defines an enum/typed constant for access levels elsewhere (e.g., in `ConversationGroupAccess` schema or a Messaging access-level module), the fixture should reference that constant instead of duplicating the literal, to avoid silent drift if the enum values ever change.
2. Same file: root-message detection uses `if message.message_id == message.conversation_id do ... end` as an implicit proxy for "this message is the conversation root, so it needs an access grant." This is a reasonable identity convention already used elsewhere in Messaging, but the fixture would be clearer and safer against future refactors if it took an explicit `is_root?`/`grant_access?` option (defaulting to the same-id check) rather than relying purely on ID equality inline.

## Judgement-worthy non-blocking code-health findings
1. **`web/config/test.exs` (pool-size floor of 16 connections)** — Smell: the fix hard-codes a minimum test DB pool size to work around a sandbox environment with only one online BEAM scheduler causing Commanded's 5-second consistency timeout to be missed by concurrent projectors. This is a legitimate, scoped test-infra fix, but it papers over a timing sensitivity in the projector/consistency-wait path that could resurface under different CI/sandbox scheduler counts or on slower infrastructure. Worth a human decision on whether the consistency timeout itself (rather than just pool sizing) should be made more robust, and whether this pool-size floor should be documented near the change so a future contributor understands why 16 is significant.
2. **Fixture layer directly `Repo.insert!`s `Message` and `ConversationGroupAccess` projection rows instead of going through commands/aggregates** — Smell: bypassing the command/aggregate path in test fixtures is a common and acceptable pattern for read-model-focused tests, but it means these tests can drift from real event-sourced behavior (e.g., if a future invariant is added to the command handler, these fixtures won't exercise it). Since the module doc explicitly scopes this to "member-facing Messaging projection tests," this is likely intentional and acceptable, but is worth confirming that focused domain tests elsewhere in the iteration (group destination resolution, sender policy, access grants, reply authorisation — as called out in the plan's Validation Plan) go through the actual command/aggregate path rather than only through this fixture-based shortcut.
3. **Groups vision doc update** — The plan explicitly calls out (under Risks/Follow-ups) that "the current Groups vision says non-members cannot post to group addresses" and that this doc "should be updated before delivery" to reflect the confirmed `club_members_only` new-conversation rule. This wasn't visible in the truncated evidence; confirm this doc update was actually made as part of this iteration, since a stale vision doc contradicting shipped behavior is a maintainability/product-clarity risk even though it's not a code defect.

## Suggested fixes
- Apply bounded-safe fixes 1–2 above in `web/test/support/messaging_fixtures.ex` (reference existing access-level constant if one exists; make root-detection explicit) as low-risk follow-up polish — optional, not required to merge.
- Add a short comment in `web/config/test.exs` near the new pool-size floor explaining the single-scheduler sandbox scenario it guards against, so it isn't mistaken for arbitrary tuning later.
- Confirm (outside this automated review, since the doc isn't code) that the Groups vision document was updated per the plan's explicit follow-up before this iteration is considered fully closed out.

## Validation notes
- `dev check` (`dev ci`) passed twice: once before the `fix_dev_check` stage and once after, with the full acceptance suite green (122 scenarios / 877 steps, all passed) both times per the provided output.
- The `fix_dev_check` stage's only tracked change was `web/config/test.exs`; it reported focused test runs (`DevTestSupportControllerTest`), `dev check --quick`, and `dev acceptance` all passing independently, plus a clean `git diff --check`.
- This review's implementation-evidence input was truncated to its final segment (~200 of ~11,700+ lines), exposing only `web/test/support/messaging_fixtures.ex` directly. The decision to ACCEPT relies primarily on (a) the plan-conformance gate having already passed per the task framing, (b) the fully green `dev check`/acceptance run as the behavioral proof point required by this workflow, and (c) the absence of any contradicting evidence in what was visible. Confidence is Medium rather than High specifically because the full domain/aggregate/projection diff for group email routing, sender policy, and access-grant logic was not directly inspectable in this session.
- No feature files appear to have been altered as part of the `fix_dev_check` stage (confirmed by its own report and by the unchanged acceptance scenario counts/pass results across both `dev_check` runs).