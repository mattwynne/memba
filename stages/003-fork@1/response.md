# Iteration Plan Review: 006-deliveries-overview

## Decision: NOT READY

## Confidence: Medium

The plan has good structure, clear scope, and a solid validation approach, but contains specific gaps in acceptance criteria and business decisions that should be resolved before implementation to avoid mid-stream design decisions.

---

## Blocking Gaps

1. **Acceptance criteria missing table structure**: The acceptance criteria mention "a table" and "delivery records" but don't specify which columns/fields will be displayed (recipient email? message subject? timestamp? delivery channel?). This is a core business decision needed before implementation.

2. **Ordering not in acceptance criteria**: Technical decisions mention "preferably newest or most recently updated first" but this isn't in the acceptance criteria as a testable requirement. The ordering choice affects both implementation and testing.

3. **"Stale problem reasons" undefined**: The criterion "Delivered/opened rows do not show stale problem reasons" is vague. What makes a reason "stale"? This likely means "successful statuses shouldn't show error reasons from earlier attempts" but should be stated explicitly.

4. **Empty state not covered**: No acceptance criterion for what operators see when there are no deliveries to display.

---

## Non-blocking Improvements

1. **Name specific modules**: Implementation step 5 mentions "the deliveries LiveView" but doesn't name it (e.g., `MembaWeb.DeliveriesLive.Index`). Naming it in the plan reduces cognitive load during implementation.

2. **Specify query function signature**: Step 3 mentions "options-shaped list function" but doesn't show a signature or location (e.g., `Memba.Messaging.list_deliveries(opts \\ [])` in `memba/messaging.ex`).

3. **Clarify status display rules**: The plan mentions delayed/bounced/spam/opened but doesn't explicitly state what happens for other possible statuses or null/missing reason text.

4. **Add error state criterion**: What should happen if the query fails or the database is unavailable?

5. **Specify LiveView data strategy**: Should the table use streams or assigns? This affects the implementation approach.

---

## Smallest Viable Iteration

The current plan is already minimal and focused. It could be reduced further by:

- Skipping the browser acceptance migration (keep `@todo-web` tags and just add PhoenixTest coverage)
- Showing only delivered/failed statuses without opened tracking

However, these reductions would compromise the stated goal of replacing domain-level-only testing with browser visibility. **The current scope is appropriate as the smallest useful slice.**

---

## Required Plan Edits

### 1. Add to Acceptance Criteria (between "table lists email deliveries" and "delayed, bounced"):

```markdown
- The table displays these columns in order: recipient email, message subject, 
  delivery status, timestamp, and reason text (when applicable).
- Records are ordered by most recent timestamp first.
- When no deliveries exist, the page displays "No deliveries recorded" with 
  appropriate empty-state messaging.
```

### 2. Replace the vague "stale problem reasons" criterion with:

```markdown
- Delivered and opened records display their status but do not show problem 
  reason text; problem reasons are only displayed for delayed, bounced, and 
  spam complaint statuses.
```

### 3. Add to Implementation Plan (before step 4):

```markdown
3a. Name the LiveView module `MembaWeb.DeliveriesLive.Index` and the query 
    function `Memba.Messaging.list_deliveries/1`.
```

### 4. Add to Technical Decisions (in "intended technical shape"):

```markdown
- Table columns: recipient email, message subject/title, status, timestamp, 
  reason (for problem statuses only)
- Default ordering: newest timestamp first (determined by delivery event timestamp)
- Empty state: "No deliveries recorded" message when the list is empty
```

---

## Validation Plan

After making the required edits, the iteration will be ready when:

### Pre-implementation verification:
1. Review updated acceptance criteria with a stakeholder/operator (even informal) to confirm the column selection and empty state meet their needs
2. Confirm the table structure aligns with data available in the existing delivery projection

### Implementation validation:
The validation plan in the document is already solid:

1. **Automated tests pass**: 
   - PhoenixTest coverage for LiveView table rendering and data display
   - Browser acceptance tests run operator scenarios without `@todo-web` tags
   - Domain acceptance tests still pass via `dev check`

2. **Manual demo succeeds**:
   - Create club, send 2+ messages
   - POST various Postmark events (delivered, delayed, bounced, spam, opened)
   - Visit `/deliveries` and verify:
     - All records appear in one table
     - Multiple messages are represented
     - Statuses and reason text display correctly
     - Successful deliveries don't show stale error reasons
     - Ordering is newest-first

3. **Stop condition**: All acceptance criteria pass, `dev check` passes, and the manual demo shows the expected behavior.

---

## Summary

This plan is **well-structured and nearly ready**. The scope is focused, the implementation steps are clear, and the validation approach is sound. However, **specific decisions about table structure, ordering, and status display should be made during planning rather than during implementation** to ensure smooth execution and avoid rework.

Making the four required edits above will move this plan to READY with HIGH confidence.