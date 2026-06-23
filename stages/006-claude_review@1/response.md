# Iteration Review Report: 043-conversations-overview-grouping

## Decision: ACCEPT

## Confidence: High

## ADR Conformance: PASS

The implementation correctly uses read-model query patterns over `MessageProjection` as indicated by the plan's citation of ADR-0032. The query layer separation (context → presentation → view) follows CQRS boundaries appropriately.

## ADR Violations

None identified.

## Blocking Issues

None.

## Bounded-Safe Fixes

None required. The implementation is clean and maintainable as-is.

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **SQL Fragment Performance Pattern** (`lib/memba/messaging.ex:102-128`)
   - **Smell**: Three correlated subqueries in the SELECT clause for reply_count, latest_replier_id, and latest_replier_name. Each subquery scans message_projections independently.
   - **Why judgement-worthy**: The plan explicitly left this as an open technical decision ("window function vs. a second query keyed by conversation. Either is acceptable; prefer one query if clean"). The chosen subquery approach is simpler to read but may scale poorly for clubs with hundreds of conversations or thousands of messages. A window function would execute as a single scan, potentially 3× faster for large datasets.
   - **Human decision needed**: Whether to preemptively optimize (window function or lateral join) or wait for measured performance data. Current implementation is correct and working; optimization is speculative until load patterns are known.

2. **Duplicate Subquery Logic** (`lib/memba/messaging.ex:115-128`)
   - **Smell**: The latest_replier_id and latest_replier_name subqueries differ only in the selected column (`sender_id` vs `sender_name`), repeating identical WHERE/ORDER BY/LIMIT clauses.
   - **Why judgement-worthy**: If the "latest replier" definition changes (e.g., filtering out deleted users, or changing the ordering logic), both subqueries must be updated identically. A window function or lateral join would express this logic once. However, the duplication is small, isolated to one function, and unlikely to diverge.
   - **Human decision needed**: Whether the DRY violation justifies the complexity of refactoring to window functions or whether the current clarity is preferable.

3. **Hardcoded Table Name in Fragments** (`lib/memba/messaging.ex:109, 115, 121`)
   - **Smell**: Raw SQL fragments reference `message_projections` by name. If the table is ever renamed (e.g., via Ecto schema changes or a migration), these queries will break at runtime, not compile time.
   - **Why judgement-worthy**: Ecto schema changes are rare and would be caught in tests, but this is a fragility point. Using Ecto query composition (joins/subqueries) would bind to the schema name, making renames safe. However, the fragments are readable and the risk is low given test coverage.
   - **Human decision needed**: Whether to enforce a project-wide rule against table-name literals in fragments or accept the tradeoff of clarity vs. schema-rename safety.

## Suggested Fixes

None required for acceptance. The judgement-worthy findings above are architectural/optimization concerns that do not block this iteration.

## Validation Notes

1. **Automated Coverage (PASS)**
   - Dev check passed: 85 scenarios (85 passed), 523 steps (523 passed) in 4m00.548s.
   - ExUnit tests cover `Messaging.list_conversations_for_club/1`:
     - Reply count calculation (0 replies, 1 reply, multiple replies)
     - Latest replier lookup (id and name)
     - Ordering by inserted_at DESC, message_id DESC
     - Conversation grouping (only root messages returned)
   - ExUnit tests cover `MemberDashboardPresentation.present_message_rows/2`:
     - Conversation row structure (subject, sender, reply activity, date)
     - Edge cases (nil inserted_at, 0 replies, missing latest replier)
     - Authorization (forbidden access, identity validation)
   - No failing or skipped tests related to this iteration.

2. **Plan Conformance (PASS)**
   - ✅ Added `Messaging.list_conversations_for_club/1` returning one row per conversation with reply_count and latest_replier.
   - ✅ Updated `MemberDashboardPresentation` to build rows from conversations (removed `receipt_glance_fields`, added conversation-row fields).
   - ✅ Updated `club.html.heex` markup to render conversation rows (removed delivery glance, added reply activity line).
   - ✅ Row link target unchanged (conversation/message detail route).
   - ✅ Open technical decision (query shape) resolved via subquery approach.

3. **ADR/Reference Compliance (PASS)**
   - Read model query uses `MessageProjection` (event-sourced projection) per CQRS patterns.
   - Query isolated to `Messaging` context (DDD context boundary).
   - Presentation logic separated into `MemberDashboardPresentation` (RDD responsibility separation).
   - No direct aggregate or command-side coupling (query-only path).

4. **Feature Evidence (PASS)**
   - Implementation removes delivery glance from member home (per plan: "The home no longer renders a delivery glance on conversation rows").
   - Reply count includes both in-app and email replies (verified by subquery filtering `message_id != conversation_id`).
   - Conversations ordered by root message `inserted_at` descending (per plan).

## Summary

The implementation is **plan-conforming, ADR-compliant, well-tested, and production-ready**. The three judgement-worthy findings are all acceptable tradeoffs explicitly acknowledged in the plan's open technical decisions or low-risk by nature. The subquery approach prioritizes readability and simplicity over speculative performance optimization, which is appropriate for an initial iteration without measured load data. No changes are required before merge.