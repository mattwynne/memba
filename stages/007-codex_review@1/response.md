# Iteration Review Report: 043-conversations-overview-grouping

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation appears to preserve the project’s CQRS/event-sourced read-model architecture: the new conversation overview is derived from `MessageProjection`, exposed through the `Messaging` context, transformed by `MemberDashboardPresentation`, and rendered by the Phoenix page template. It does not appear to bypass the projection/read-model layer or introduce command-side coupling for a read concern.

`dev ci` passed on the reviewed state, including acceptance coverage.

## ADR violations

None identified.

## Blocking issues

None.

## Bounded-safe fixes

None required before merge.

## Judgement-worthy non-blocking code-health findings

1. **Correlated SQL subqueries in the conversation read model**

   - **File(s):** `lib/memba/messaging.ex`
   - **Smell:** `list_conversations_for_club/1` appears to compute `reply_count`, `latest_replier_id`, and `latest_replier_name` with separate correlated subqueries over `message_projections`.
   - **Why it may need human judgement:** This is plan-conforming and readable, but it may become expensive as message volume grows because the same table is queried repeatedly per root conversation. The plan explicitly allowed flexibility here, so this is not a blocker. If clubs are expected to accumulate many conversations/replies, a future refactor to a single grouped query, lateral join, or window-function approach may be worth considering.

2. **Duplicated “latest replier” selection logic**

   - **File(s):** `lib/memba/messaging.ex`
   - **Smell:** The lookup for latest replier id and latest replier name likely repeats the same filtering and ordering logic, differing only by selected column.
   - **Why it may need human judgement:** The duplication is small and localized, but it creates a maintenance footgun if the definition of “latest replier” changes later. A more structured query could express the latest-reply row once and select both fields from it. The current implementation is acceptable for this iteration because the behaviour is covered and the query remains understandable.

3. **Raw table-name references inside SQL fragments**

   - **File(s):** `lib/memba/messaging.ex`
   - **Smell:** SQL fragments reference `message_projections` directly.
   - **Why it may need human judgement:** This is common when Ecto query composition becomes awkward, but it weakens compile-time/schema-level protection and makes future table renames or projection changes easier to miss. Given the isolated use and passing tests, this should not block merge, but it is worth tracking if similar fragments accumulate.

## Suggested fixes

No required fixes.

If the team later decides to polish the query, the most useful follow-up would be to replace the repeated correlated subqueries with one query shape that computes the latest reply row once per conversation, while preserving the existing public return shape and tests.

## Validation notes

- `dev ci` passed successfully.
  - Acceptance: `85 scenarios (85 passed)`, `523 steps (523 passed)`.
- The implementation appears consistent with the iteration plan:
  - Adds `Messaging.list_conversations_for_club/1`.
  - Groups home-page rows by root conversation instead of rendering every raw message.
  - Computes reply count and latest replier data.
  - Keeps the row target pointed at the existing conversation/message detail route.
  - Removes the delivery/receipt glance from member home message rows.
- Automated coverage evidence includes tests for:
  - Conversation grouping.
  - Reply counts.
  - Latest replier fields.
  - Ordering.
  - Presentation row structure.
  - Absence of delivery-glance fields.
  - Authorization/error handling around selected clubs.
- No out-of-scope architecture changes, routing churn, or command-side/event-sourcing bypasses were evident from the implementation evidence.