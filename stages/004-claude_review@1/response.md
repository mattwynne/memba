# Review Report

## Decision: NOT READY

## Confidence: High

## Blocking Gaps

1. **Plan truncated** - The first 134 lines were omitted from the review, which likely contain the Goals, Scope, Non-goals, and Acceptance Criteria sections. Cannot evaluate core plan elements without this content.

2. **Route shape unresolved** - The exact route pattern for member message detail is still an open decision. This is fundamental to implementation as it affects route helpers, authorization guards, links from message lists, and breadcrumbs. Example needed: `/clubs/:club_id/messages/:id` or alternative.

3. **Compose UX placement unresolved** - Whether compose is a separate route/page or a modal/state affects which LiveViews to create, how navigation works, and where form state lives. Must be decided before implementation begins.

4. **Receipt display approach unresolved** - Whether receipt statuses are grouped (with counts/summary bar) or a simple table/list affects database queries, rendering logic, and test assertions. The wireframe suggests one approach but implementation is uncommitted.

5. **Icon source unresolved** - While seemingly minor, the exact icons must be specified before component implementation. The plan mentions preferring existing `<.icon>`/Heroicons but doesn't commit.

## Non-blocking Improvements

1. The query-string `club_id` approach is acknowledged as temporary but could explicitly state: "Will be removed in iteration NNN when custom domains are implemented" or similar.

2. The "sender-included rule is intentionally provisional" could reference a specific follow-up iteration or backlog item for role-based receipt visibility.

3. The manual demo is detailed but could include expected icon names/types for step 6 to make validation more concrete.

## Smallest Viable Iteration

Start with the absolute minimum member-facing capability:

1. **Route:** `/clubs/:club_id/messages/:id` - simple, explicit, uses existing club_id pattern
2. **Compose:** Separate route `/clubs/:club_id/messages/new` - simplest implementation, no modal complexity
3. **Receipts:** Simple list/table - one row per recipient showing name, status label, icon - defer grouping/summary
4. **Icons:** Heroicons via existing `<.icon>` component - already permitted, no new dependencies

This delivers the core member message experience (send + view delivery status) without resolving complex UX questions that can be refined in subsequent iterations.

## Required Plan Edits

1. **Provide complete plan text** - Include all sections, especially Goals, Scope, Non-goals, and Acceptance Criteria.

2. **Resolve route shape** - State exact route pattern, e.g., "Member message detail will be at `/clubs/:club_id/messages/:id`"

3. **Resolve compose placement** - Choose and document: separate route (e.g., `/clubs/:club_id/messages/new`) OR modal/state from club home. Specify which LiveView files will be created/modified.

4. **Resolve receipt display** - Choose and document: simple list OR grouped with summary. If simple list, specify columns (recipient name, status label, icon). If grouped, specify grouping categories and summary bar content.

5. **Resolve icon source** - Specify exact Heroicon names for each status (Sending, Delivered, Delivery problem, Opened, Bounced) OR specify alternative if not using Heroicons.

6. **Update acceptance criteria** - Once visible, ensure they specify the exact routes members navigate to, exact status labels displayed, and exact authorization checks required.

## Validation Plan

Once decisions are resolved and plan is complete:

1. Run `dev check` - must pass
2. Browser Cucumber with `member_message_deliverability.feature` untagged - must pass all scenarios
3. Targeted validation:
   - Alice sends message from member session at documented compose route
   - Alice views message detail at documented message detail route
   - Bob views same message detail with same receipt statuses
   - No member navigation to `/admin/*` paths
   - Status labels match decided mapping
   - Icons match decided Heroicon names
4. Phoenix tests cover route authorization and status label mapping
5. Manual demo as specified in validation plan section

The validation plan in the current plan is already thorough - it just needs the open decisions resolved so it can be executed.

{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":5,"claude_review_blocking_gaps":"Plan truncated preventing evaluation of Goals/Scope/Acceptance Criteria; Route shape unresolved; Compose UX placement unresolved; Receipt display approach unresolved; Icon source unresolved","claude_review_required_edits":"Provide complete plan text; Resolve and document route shape; Resolve and document compose placement; Resolve and document receipt display approach; Resolve and document icon source"}}