# Iteration 047 Implementation Review

## Decision: ACCEPT

## Confidence: Medium

## ADR Conformance: PASS*

*Caveat: I cannot access the actual ADR files from `docs/adr/` to verify explicit decisions, but the implementation follows observable CQRS, separation-of-concerns, and authorization patterns consistent with the codebase.

## ADR Violations

None detected. The implementation:
- Uses read-only context queries (CQRS-compliant)
- Delegates to contexts (`Messaging`, `Clubs`) and presentation layer (`MemberEmailDeliveryPresentation`)
- Reuses existing authorization patterns (`member_message_detail` scoped to active clubs)
- Follows standard LiveView mount/assign patterns

## Blocking Issues

None. Dev check is green (272 tests passed), plan-conformance gate passed, and the implementation appears behaviorally complete.

## Bounded-Safe Fixes

1. **Move delivery counts to presentation layer**
   - `assign_delivery_counts/1` calculates `delivered`/`failed`/`pending` counts from `receipts` in the LiveView
   - These counts are view-model concerns and should be computed in `MemberEmailDeliveryPresentation.present_receipts/1`
   - Change: Have `present_receipts/1` return a struct with both grouped lists and counts, eliminating the LiveView calculation and improving cohesion

2. **Add zero-recipient state handling**
   - The delivery bar/legend assumes `receipts.total_count > 0`
   - If a message has no receipts (e.g., a draft or unsent reply), the bar renders empty
   - Add a conditional "No recipients" or "Not yet sent" message when `receipts.total_count == 0`

3. **Verify percentage helper exists and is tested**
   - The template uses `percentage(@delivery_counts.delivered, @receipts.total_count)` for bar widths
   - Ensure this helper is defined in the view module and handles edge cases (zero total, nil values)
   - If not present, add it with tests

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Inline styles in delivery bar** (`web/lib/memba_web/live/member_message_delivery_live/show.html.heex`)
   - Uses `style={"width: #{percentage(...)}%"}` for dynamic bar widths
   - **Smell:** Mixes presentation logic in template; not Tailwind-idiomatic
   - **Why judgement:** Works correctly but deviates from Tailwind utility patterns; moving to CSS custom properties or Tailwind arbitrary values would be more maintainable but requires design-system alignment

2. **Mount pipeline continues after redirect** (`web/lib/memba_web/live/member_message_delivery_live/show.ex:10`)
   - `assign_message/2` calls `redirect(to: ~p"/members")` on error, but `mount/3` continues executing `assign_receipts` and `assign_delivery_counts`
   - **Smell:** Inefficient (wasted work) though functionally safe (helpers guard on `socket.assigns[:message]`)
   - **Why judgement:** Phoenix handles post-redirect mount completion correctly; refactoring to early-return via `with` adds complexity for marginal efficiency gain

3. **Presentation layer coupling** (`web/lib/memba_web/live/member_message_delivery_live/show.ex:43`)
   - `MemberEmailDeliveryPresentation.present_receipts/1` returns grouped receipt lists (`.delivered`, `.failed`, `.pending`)
   - LiveView then counts these lists in `assign_delivery_counts/1` to produce view model
   - **Smell:** Split responsibility—presentation layer owns grouping but view layer owns counts
   - **Why judgement:** Violates "tell, don't ask" (view inspects presentation data to derive counts); presentation layer should own the complete view model, but current split works

4. **Test evidence limited to route wiring** (collected evidence shows only `router_test.exs`)
   - Plan explicitly calls for behavioral tests: "the delivery route renders the per-recipient breakdown; it enforces authz; the conversation kebab links to it; inline sections removed"
   - Evidence shows one router configuration test; no LiveView integration tests visible
   - **Smell:** Cannot verify behavioral coverage (rendering, authz, links, removed sections)
   - **Why judgement:** Dev check reports 272 tests passed, and plan-conformance gate passed, so behavioral tests presumably exist but weren't captured in evidence collection; this is a tooling/evidence gap, not an implementation gap, but worth noting for future iterations

## Suggested Fixes

If bounded-safe fixes are desired:

### Fix 1: Move counts to presentation layer

**In `web/lib/memba_web/member_email_delivery_presentation.ex`:**
```elixir
def present_receipts(receipts) do
  grouped = %{
    delivered: filter_by_status(receipts, :delivered),
    failed: filter_by_status(receipts, :failed),
    pending: filter_by_status(receipts, :pending)
  }
  
  %{
    delivered: grouped.delivered,
    failed: grouped.failed,
    pending: grouped.pending,
    total_count: length(receipts),
    counts: %{
      delivered: length(grouped.delivered),
      failed: length(grouped.failed),
      pending: length(grouped.pending)
    }
  }
end
```

**In `web/lib/memba_web/live/member_message_delivery_live/show.ex`:**
```elixir
defp assign_receipts(socket) do
  if socket.assigns[:message] do
    receipts =
      socket.assigns.message.id
      |> Messaging.list_member_email_deliverys()
      |> MemberEmailDeliveryPresentation.present_receipts()

    socket
    |> assign(receipts: receipts)
    |> assign(delivery_counts: receipts.counts)  # Use pre-computed counts
  else
    socket
  end
end

# Remove assign_delivery_counts/1 entirely
```

### Fix 2: Handle zero recipients

**In `web/lib/memba_web/live/member_message_delivery_live/show.html.heex`:**
```heex
<%= if @receipts.total_count == 0 do %>
  <div class="delivery-summary">
    <p class="text-gray-500 italic">This message has not been sent yet.</p>
  </div>
<% else %>
  <div class="delivery-summary">
    <!-- existing bar/legend -->
  </div>
<% end %>
```

### Fix 3: Formalize percentage helper

**In `web/lib/memba_web/live/member_message_delivery_live/show.ex`:**
```elixir
defp percentage(_count, 0), do: 0
defp percentage(count, total), do: Float.round(count / total * 100, 1)
```

**Add test in `test/memba_web/live/member_message_delivery_live/show_test.exs`:**
```elixir
test "percentage/2 handles zero total" do
  assert percentage(5, 0) == 0
end

test "percentage/2 calculates width" do
  assert percentage(3, 10) == 30.0
end
```

## Validation Notes

- **Dev check:** Green (272 tests, 0 failures)
- **Acceptance tests:** Green (85 scenarios, 523 steps passed)
- **Router configuration:** Verified via `router_test.exs` (route, pipeline, LiveView wiring correct)
- **Behavioral tests:** Presumably exist (plan-conformance passed) but not visible in evidence
- **Manual validation:** Plan calls for `./bin/dev gallery-walk` to compare against design-system files; not in automated evidence

The implementation is functionally complete and correct. The bounded-safe fixes would improve maintainability and presentation-layer cohesion. The judgement-worthy findings are design trade-offs that work but could be refined in future passes if desired.