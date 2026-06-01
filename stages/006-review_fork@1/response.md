# Iteration Review Report

**Decision:** ACCEPT with conditions  
**Confidence:** Medium  
**ADR conformance:** CANNOT VERIFY (ADR documents not accessible in review context)

## ADR Violations

**Cannot definitively assess** - The review context does not include ADR document content from `docs/adr/`. The plan does not cite specific ADRs. Key architectural patterns that should be governed by ADRs:

1. **Data access pattern** - Implementation uses raw SQL queries (`Memba.Postgres.query`) instead of Ecto queries or context boundaries
2. **Read vs. write model separation** - Tests show Commanded usage (CQRS write side), but no ADR reference for read-side query patterns
3. **Authorization duplication** - SQL-level authorization logic may duplicate domain rules

**Recommendation:** Human verification needed to confirm whether the direct SQL query pattern aligns with documented CQRS read-side architecture or violates context/Ecto ADRs.

## Blocking Issues

None identified given:
- Dev check passed (230 tests, 0 failures)
- Plan conformance gate already passed
- Authorization behavior preserved and tested
- UI functionality comprehensively tested

## Bounded-Safe Fixes

1. **Extract testable business logic to presentation module**
   - Move `build_summary/1`, `build_receipt_groups/1`, `calculate_percent/2` to `MembaWeb.MemberMessageLive.ReceiptPresenter` or similar
   - Add focused unit tests for percentage calculations, grouping logic
   - Current location in LiveView makes business logic harder to test in isolation

2. **Add docstrings to public and private functions**
   ```elixir
   # Current:
   defp calculate_percent(count, total) when total == 0, do: 0
   
   # Suggested:
   @doc """
   Calculates percentage as a whole number, rounding to nearest integer.
   Returns 0 for zero total to avoid division by zero.
   """
   defp calculate_percent(count, total) when total == 0, do: 0
   ```

3. **Consistent test organization**
   - Group related tests with nested `describe` blocks for better readability:
   ```elixir
   describe "receipt summary display" do
     describe "with mixed statuses" do
       # all statuses shown tests
     end
     
     describe "with zero counts" do
       # zero count tests  
     end
   end
   ```

4. **Type specs for helper functions**
   ```elixir
   @spec build_summary([map()]) :: map()
   defp build_summary(receipts) do
   ```

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Files:** `web/lib/memba_web/live/member_message_live/show.ex` (lines 20-95)  
   **Smell:** Direct SQL queries bypass Ecto schemas, queries, and context boundaries  
   **Why judgement needed:** 
   - Pattern may be intentional for CQRS read-side (evidence: Commanded usage in tests)
   - Or may violate established context/Ecto conventions if not documented
   - Creates coupling to raw database schema without type safety
   - Authorization logic duplicated in SQL vs. domain layer
   - Should verify against unread ADRs for data access patterns and CQRS architecture decisions

2. **Files:** `web/lib/memba_web/live/member_message_live/show.ex` (lines 97-145)  
   **Smell:** Business logic (percentage calculation, status grouping) embedded in LiveView module  
   **Why judgement needed:**
   - Reduces testability (can only test through LiveView integration tests currently)
   - Mixes presentation concerns with calculations
   - Consider whether this logic belongs in a context, projection, or view model
   - Not blocking since tests cover behavior, but affects maintainability

3. **Files:** `web/lib/memba_web/live/member_message_live/show.ex` (lines 48-92)  
   **Smell:** Manual result mapping without schema validation  
   **Why judgement needed:**
   - Maps raw query results to plain maps: `%{id: row["id"], title: row["title"], ...}`
   - No compile-time guarantees about field presence or types
   - Consider embedded schemas or typed structs for read models
   - Increases risk of runtime errors if database schema changes

4. **Files:** `web/test/memba_web/live/member_message_live_test.exs` (all)  
   **Smell:** Business logic calculations not unit tested  
   **Why judgement needed:**
   - Percentage rounding logic only tested through LiveView integration tests
   - Group building, filtering logic only tested end-to-end
   - If extracted to presentation module (bounded-safe fix #1), should add isolated unit tests
   - Current coverage proves behavior but makes debugging harder

5. **Files:** `web/lib/memba_web/router.ex` (line change from controller to LiveView)  
   **Smell:** Route pattern change not documented  
   **Why judgement needed:**
   - Migration from `get "/messages/:message_id", MemberMessageController, :show` to `live "/messages/:message_id", MemberMessageLive.Show, :show`
   - Old controller deleted, HTML view deleted
   - Should document why LiveView is preferred for this route vs. other member routes
   - Pattern consistency: are other member views moving to LiveView or staying as controllers?

## Suggested Fixes

### If bounded-safe refactoring applied:

**Extract presentation logic (fix #1):**

```elixir
# web/lib/memba_web/live/member_message_live/receipt_presenter.ex
defmodule MembaWeb.MemberMessageLive.ReceiptPresenter do
  @moduledoc """
  Presentation logic for member message receipt summaries and grouping.
  """

  @doc """
  Builds summary statistics with counts and percentages for all receipt statuses.
  Zero-count statuses are included in the summary.
  """
  @spec build_summary([map()]) :: map()
  def build_summary(receipts) do
    # ... existing logic
  end

  @doc """
  Groups non-empty receipt statuses into collapsible sections.
  Zero-count statuses are excluded from groups.
  """
  @spec build_receipt_groups([map()]) :: [map()]
  def build_receipt_groups(receipts) do
    # ... existing logic
  end

  @doc """
  Calculates whole-number percentage, rounding to nearest integer.
  Returns 0 when total is 0 to avoid division errors.
  """
  @spec calculate_percent(non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  def calculate_percent(count, total) when total == 0, do: 0
  # ... rest
end
```

**Update LiveView to use presenter:**

```elixir
# In show.ex
alias MembaWeb.MemberMessageLive.ReceiptPresenter

# Replace current calls:
receipt_groups = ReceiptPresenter.build_receipt_groups(addressed_receipts)
summary = ReceiptPresenter.build_summary(addressed_receipts)
```

**Add presenter unit tests:**

```elixir
# web/test/memba_web/live/member_message_live/receipt_presenter_test.exs
defmodule MembaWeb.MemberMessageLive.ReceiptPresenterTest do
  use ExUnit.Case, async: true
  alias MembaWeb.MemberMessageLive.ReceiptPresenter

  describe "calculate_percent/2" do
    test "returns 0 when total is 0" do
      assert ReceiptPresenter.calculate_percent(0, 0) == 0
    end

    test "rounds percentages to nearest whole number" do
      assert ReceiptPresenter.calculate_percent(1, 3) == 33
      assert ReceiptPresenter.calculate_percent(2, 3) == 67
    end
    # ... more edge cases
  end

  describe "build_summary/1" do
    # ... focused tests
  end
end
```

## Validation Notes

**Automated checks completed:**
- ✅ Dev check passed (230 tests, 0 failures)
- ✅ Compilation clean
- ✅ No warnings

**Test coverage verified:**
- ✅ Authorization: unauthorized user, different club member
- ✅ Not found handling with redirect
- ✅ Summary display with all statuses including zero counts
- ✅ Receipt groups: non-zero statuses, collapse/expand behavior
- ✅ Data privacy: no operator-only fields
- ✅ Route authorization through `club_member_required` pipeline

**Plan conformance:**
- ✅ LiveView conversion complete
- ✅ Summary bar implemented
- ✅ Collapsible groups by status
- ✅ Zero-count statuses in summary only
- ✅ All groups collapsed by default
- ✅ No custom JavaScript
- ✅ Test attributes preserved
- ⚠️ Acceptance test updates: not visible in diff but dev check passed, suggesting tests adapted or didn't require changes

**Manual validation recommended:**
1. Verify acceptance tests still pass with groups collapsed by default
2. Confirm raw SQL query pattern aligns with unread ADRs for CQRS read models
3. Review whether business logic should live in presentation layer or domain contexts

**Confidence rationale:**
- Medium confidence due to inability to verify ADR conformance without access to ADR documents
- High confidence in functional correctness based on comprehensive tests
- Architectural pattern (direct SQL) needs human review against project standards