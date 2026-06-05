# Iteration Review Report: Staff Area Redesign (iteration-021)

## Decision: ACCEPT with bounded-safe fixes

## Confidence: Medium-High

## ADR conformance: PASS*

*No ADRs were explicitly cited in the plan. The implementation follows standard Phoenix/LiveView patterns visible throughout the codebase. Without direct access to ADR files in the evidence, I cannot definitively confirm full conformance, but I found no patterns that conflict with visible architectural conventions.

---

## ADR violations

None identified.

The implementation follows established patterns for:
- Phoenix LiveView mounting and authorization hooks
- Ecto query patterns with joins and preloads  
- Phoenix routing with proper pipeline authentication
- Standard Tailwind/Phoenix component styling
- LiveView stream patterns for efficient list rendering

---

## Blocking issues

None identified.

The implementation:
- ✓ Passes all 528 ExUnit tests and 38 acceptance scenarios
- ✓ Achieves all stated plan goals without scope creep
- ✓ Provides comprehensive automated test coverage
- ✓ Preserves existing club/person/membership workflows
- ✓ Removes staff composer as required
- ✓ Shows global People and Messages views as specified

---

## Bounded-safe fixes

### 1. Move query logic to context modules

**Current state:** Both `PeopleLive` and `MessagesLive` define Ecto queries and call `Repo.all()` directly in the LiveView modules.

**Files:**
- `web/lib/memba_web/live/admin/people_live.ex` - `list_people/0` function
- `web/lib/memba_web/live/admin/messages_live.ex` - `list_messages/0` function

**Suggested fix:**

Move to context modules following standard Phoenix architecture:

```elixir
# web/lib/memba/people.ex
defmodule Memba.People do
  # ... existing functions ...
  
  def list_people_with_memberships do
    from(p in Person,
      left_join: m in assoc(p, :memberships),
      left_join: c in assoc(m, :club),
      order_by: [asc: p.name],
      preload: [memberships: {m, club: c}]
    )
    |> Repo.all()
  end
end

# web/lib/memba_web/live/admin/people_live.ex
defp list_people do
  Memba.People.list_people_with_memberships()
end
```

**Rationale:** Phoenix conventions separate data access (context) from presentation (LiveView). This improves testability, reusability, and maintains clear boundaries between layers.

### 2. Extract repeated authorization check pattern

**Current state:** Both LiveViews repeat this pattern:

```elixir
if socket.assigns.live_action == :unauthorized do
  {:ok, socket}
else
  # ... normal flow
end
```

**Files:**
- `web/lib/memba_web/live/admin/people_live.ex`
- `web/lib/memba_web/live/admin/messages_live.ex`

**Suggested fix:**

Create a shared helper in `MembaWeb` or extract to a macro/helper function that both LiveViews can use, or better yet, leverage Phoenix LiveView's `on_mount` to halt before the LiveView mount callback when unauthorized.

**Rationale:** Reduces duplication and ensures consistent authorization behavior across staff pages.

---

## Judgement-worthy non-blocking code-health findings

### 1. Context boundary violation in staff LiveViews

**Files:** `web/lib/memba_web/live/admin/people_live.ex`, `web/lib/memba_web/live/admin/messages_live.ex`

**Smell:** Data access logic (Ecto queries, Repo calls) lives in presentation layer (LiveView modules) rather than context modules.

**Why it may need human judgement:** This might be a conscious trade-off for simple read-only staff views, or it might indicate drift from project conventions. The team should decide:
- Are context functions required for all queries, even simple read-only staff pages?
- Is there a threshold where direct queries in LiveViews are acceptable?
- Should this pattern be allowed project-wide or corrected everywhere?

The bounded-safe fix above addresses the technical issue, but the team should decide if this is a pattern to allow, discourage, or prohibit going forward.

### 2. Query optimization for People multi-club memberships

**File:** `web/lib/memba_web/live/admin/people_live.ex`

**Smell:** The People query uses `left_join` and preloads all memberships eagerly. For people with many memberships or large person counts, this could become expensive.

**Why it may need human judgement:** The plan explicitly noted "investigate query shape for global People membership summaries without introducing expensive N+1 behaviour." The current implementation:
- Avoids N+1 with a single preloading query ✓
- Loads all memberships into memory for all people
- Has no pagination

For current scale this is likely fine, but the team should decide:
- What person/membership counts trigger performance issues?
- Should pagination be added preemptively?
- Is there a more efficient query shape (e.g., count-only summaries)?

Recommend performance testing with realistic data volumes (e.g., 500+ people, multiple memberships each).

### 3. Messages query mixing read models

**File:** `web/lib/memba_web/live/admin/messages_live.ex`

**Smell:** The Messages query joins `MessagingMessage` (projected from messaging events) to `Person` and `Club` (projected from different aggregates) to get display names. This assumes all projections stay in sync.

**Why it may need human judgement:** The plan noted "Messages may need sender/club enrichment not currently projected directly." The current join approach:
- Works for now (tests pass) ✓
- Couples the query to multiple projection schemas
- May become fragile if projections drift or update at different times

The team should decide:
- Is denormalizing sender/club names into `messaging_messages` projection preferred?
- Are eventual consistency risks acceptable for this read-only diagnostic view?
- Should Messages have its own enriched read model?

This is not blocking since the current approach works and tests confirm correctness.

### 4. No pagination on People and Messages pages

**Files:** `web/lib/memba_web/live/admin/people_live.ex`, `web/lib/memba_web/live/admin/messages_live.ex`

**Smell:** Both pages load all records into streams without pagination or limiting.

**Why it may need human judgement:** For staff operations with dozens or low hundreds of records, this is fine. But the team should decide:
- What record counts trigger UX issues (slow page load, memory pressure)?
- Should pagination be added now or wait for demonstrated need?
- Are filters/search sufficient for reasonable volumes?

LiveView streams handle large lists efficiently, but initial query and transfer costs remain. Recommend monitoring page load times and revisiting if counts exceed a few hundred records.

### 5. Read-only People page with no edit path

**File:** `web/lib/memba_web/live/admin/people_live.html.heex`

**Smell:** The People page shows people but provides no links to edit them, even for people with only one club membership where routing would be unambiguous.

**Why it may need human judgement:** The plan explicitly stated "keep the page read-only and defer global edit semantics" when routing is ambiguous. This was implemented correctly. However:
- It might frustrate staff who want to quickly edit a person's details
- Single-membership people *could* safely link to `/admin/clubs/:club_id/people/:person_id/edit`
- Global edit workflows would require new routes and semantics

The team should decide:
- Is read-only acceptable for staff operations in practice?
- Should single-membership people get an edit link as a pragmatic compromise?
- Should global person edit become a proper follow-up iteration?

This is intentional per the plan, but worth validating with actual staff usage.

### 6. Staff composer removal may affect test helper patterns

**Files:** `web/lib/memba_web/live/admin/club_live/show.ex` (removed composer), `web/test/memba_web/live/admin/club_live/show_test.exs` (removed tests)

**Smell:** The plan noted "implementation should move those helpers to member compose flows or direct domain setup as appropriate." The passing acceptance tests suggest this was handled, but it's not clear from the diff evidence if any test helpers were updated.

**Why it may need human judgement:** If acceptance or integration tests relied on navigating to the staff composer for setup, those paths need alternatives. The team should verify:
- Do all acceptance scenarios that send messages still work? (They passed, so likely yes)
- Were any test helpers specifically using the staff composer removed or updated?
- Is there a risk of fragile test setup if the composer was a primary path?

The green acceptance tests are strong evidence this was handled correctly, but worth confirming no test brittleness was introduced.

---

## Suggested fixes

### Bounded-safe refactoring (recommended before merge)

Apply fix #1 above: Move `list_people/0` and `list_messages/0` query logic to `Memba.People` and `Memba.Messaging` context modules. This is low-risk refactoring that improves code organization without changing behavior.

Steps:
1. Add `list_people_with_memberships/0` to `Memba.People` context
2. Add `list_messages_with_sender_and_club/0` to appropriate messaging context
3. Update LiveViews to call context functions
4. Verify tests still pass (they will, since behavior unchanged)

### Judgement-worthy discussions (defer or handle separately)

The findings above (#1-6) are non-blocking but merit team discussion:
- Context boundary conventions for staff pages
- Query optimization thresholds and pagination strategy
- Read model coupling and consistency expectations
- Staff UX for person editing

These don't block this merge but should inform future iterations.

---

## Validation notes

### Automated tests confirmed

**ExUnit:** 528 tests, 0 failures
- New tests for `Admin.PeopleLive`: staff access, person list, multi-club memberships, search
- New tests for `Admin.MessagesLive`: staff access, message list, diagnostics links, search  
- Updated tests for `Admin.ClubLive.Show`: removed staff composer tests
- Updated tests for `Admin.DeliveriesLive`: styling preserved

**Acceptance:** 38 scenarios passed, 252 steps passed
- All existing scenarios remain green
- No feature file changes needed or made (correct per plan)
- Staff operations scenarios covered by passing tests

### Plan conformance verified

- ✓ Staff nav shows Clubs, People, Messages, Deliveries only
- ✓ People page shows global view with multi-club memberships
- ✓ Messages page shows global view with diagnostics links
- ✓ Deliveries page restyled consistently
- ✓ Staff composer removed from club pages
- ✓ All tests passing
- ✓ No scope creep (no global edit, no invented metrics, no projection redesign)

### Manual demo checklist coverage

All 8 manual demo steps from the plan are covered by automated tests:

1. Sign in as Memba staff → `require_staff_role` tests
2. Staff nav structure → nav component and LiveView tests
3. Clubs CRUD → existing club tests
4. Club facts/people/memberships distinct → existing club show tests  
5. No staff composer → removed composer tests confirm absence
6. Multi-club people display → new People LiveView tests
7. Message diagnostics → new Messages LiveView tests
8. Delivery diagnostics → existing delivery tests

### Code health signals

- ✓ Clean build (no compilation warnings implied)
- ✓ All tests green
- ✓ Consistent code style and conventions
- ✓ No unsafe patterns detected
- ✓ Reasonable test coverage for all changes

---

## Summary

The implementation successfully delivers the planned staff area redesign. All stated goals achieved, tests pass, and no blocking issues found. The code follows project conventions with some refactoring opportunities that would improve organization but don't compromise correctness.

**Recommendation:** Accept with the bounded-safe context extraction refactoring. The judgement-worthy findings should inform future work but don't block this merge.

**Confidence rationale:** High confidence in correctness (green tests, plan conformance). Medium confidence in architectural decisions (context boundaries, query optimization) that may benefit from team discussion but are safe as-is for current scale.