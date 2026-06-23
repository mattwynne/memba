# Iteration Review Report: 043-conversations-overview-grouping

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation appears to conform to the project’s CQRS/read-model architecture and the ADR direction cited by the plan. The new conversation overview is derived from `MessageProjection`, exposed through the `Messaging` context, transformed by `MemberDashboardPresentation`, and rendered by the Phoenix page template. It does not introduce command-side coupling, bypass the projection/read-model layer, or replace ADR-mandated infrastructure with a local shortcut.

`dev ci` passed on the reviewed state.

## ADR violations

None identified.

## Blocking issues

None.

## Bounded-safe fixes

None required before merge.

## Judgement-worthy non-blocking code-health findings

1. **Correlated subqueries in the conversation read-model query**

   - **File(s):** `lib/memba/messaging.ex`
   - **Smell:** `Messaging.list_conversations_for_club/1` appears to compute `reply_count`, `latest_replier_id`, and `latest_replier_name` with separate correlated SQL subqueries over `message_projections`.
   - **Why it may need human judgement:** This is plan-conforming and readable, but it may scale less well as clubs accumulate many conversations and replies because the same projection table is repeatedly queried per root conversation. The plan explicitly allowed flexibility here, so this is not a blocker. If message volume becomes material, a later refactor to a grouped query, lateral join, or window-function approach may be worth considering.

2. **Duplicated latest-replier selection logic**

   - **File(s):** `lib/memba/messaging.ex`
   - **Smell:** The latest replier id and latest replier name are selected via nearly identical subqueries that differ only in the selected column.
   - **Why it may need human judgement:** The duplication is localized and easy to understand, but it creates a small maintenance footgun if the definition of “latest reply” changes later. A query shape that identifies the latest reply row once and projects both fields would reduce drift risk, at the cost of added SQL/Ecto complexity.

3. **Raw table-name references in SQL fragments**

   - **File(s):** `lib/memba/messaging.ex`
   - **Smell:** SQL fragments reference `message_projections` directly.
   - **Why it may need human judgement:** This is a common pragmatic choice when Ecto composition gets awkward, but it weakens schema-level protection and makes table/projection renames easier to miss. Given the isolated usage and passing tests, this should not block the iteration, but it is worth watching if similar fragments accumulate.

## Suggested fixes

No required fixes.

If the team later chooses to polish the query, the highest-value follow-up would be to express the conversation summary in one query shape that computes the latest reply row once per conversation while preserving the current public return shape and tests.

## Validation notes

- `dev ci` passed successfully.
  - Acceptance: `85 scenarios (85 passed)`, `523 steps (523 passed)`.
- Implementation evidence indicates the iteration plan was satisfied:
  - Added `Messaging.list_conversations_for_club/1`.
  - Member home rows are built from conversations rather than raw messages.
  - Reply count and latest replier fields are available to presentation.
  - Delivery/receipt glance fields were removed from the member home row.
  - Row link target remains the existing conversation/message detail route.
- Automated coverage evidence includes tests for:
  - Conversation grouping.
  - Reply count calculation.
  - Latest replier fields.
  - Ordering.
  - Presentation row structure.
  - Absence of delivery-glance fields.
  - Authorization/error handling around selected clubs.
- No out-of-scope architecture churn, route churn, command-side coupling, or projection bypass was evident from the collected implementation evidence.