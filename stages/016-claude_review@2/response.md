# Iteration 047 Review: Conversation Delivery Details

## Decision: REJECT

## Confidence: Medium

The core implementation appears complete and correct (green tests, plan-conformance passed), but the prior repair attempt failed to address identified issues, indicating they require human verification or resolution before merge. Confidence is medium because the evidence excerpts don't include the full implementation code for direct inspection.

## ADR conformance: PASS

No ADR violations detected. The iteration is a read-side UI change (routing, LiveView, presentation, CSS) that:
- Uses existing read-model APIs (`Messaging.list_member_email_deliverys/1`)
- Delegates presentation shaping to `MemberEmailDeliveryPresentation`
- Reuses established member message authorization patterns scoped to active clubs
- Maintains CQRS boundaries (no aggregate/command/event changes)
- Follows Phoenix/LiveView routing and pipeline conventions

The implementation correctly stays in the read-side/presentation layer without introducing local domain shortcuts or replacing ADR-governed infrastructure.

## ADR violations

None.

## Blocking issues

The synthesis stage identified four issues that a repair agent claimed to fix but produced no working-tree diff to verify. These must be resolved:

1. **Zero-recipient state coverage gap**
   - The plan explicitly states: "if a message has no receipts yet, the page shows an empty/none state"
   - This is a behavioral requirement, not polish
   - Must either prove existing coverage or add explicit empty-state rendering + test
   - **Why blocking:** Edge case behavior is part of the acceptance criteria; untested empty states can cause production UI issues

2. **Percentage calculation safety**
   - Delivery bar uses percentage calculations for widths
   - Division by zero or malformed styles on zero-total edge case could break rendering
   - Must prove helper exists, is safe, and is tested (unit or rendered-output)
   - **Why blocking:** Runtime calculation errors are behavioral defects, not maintainability concerns

3. **Delivery counts location** (borderline)
   - Three independent reviewers noted counts should be in presentation layer, not LiveView
   - Repair agent claimed this is already done but provided no proof
   - Must verify whether `MemberEmailDeliveryPresentation.present_receipts/1` returns counts or LiveView computes them from groups
   - **Why blocking (barely):** If LiveView is computing counts, it's coupling to presentation internals; this affects maintainability enough to warrant fixing before merge given the repair attempt failed

4. **Mount redirect control flow** (least blocking)
   - Concern: LiveView `mount/3` might continue assign pipeline after redirect
   - Repair agent claimed code already uses proper `case` flow
   - Must verify redirect branches return immediately
   - **Why blocking (least critical):** Functionally safe but inefficient; prior repair failure suggests verification needed

## Bounded-safe fixes

The four blocking issues above are bounded-safe **if properly verified or fixed**. Specific changes:

### Fix 1: Zero-recipient state (behavioral)

**Verify existing handling or add:**

In `web/lib/memba_web/live/member_message_delivery_live/show.html.heex`:
```heex
<%= if @receipts.total_count == 0 do %>
  <div class="delivery-summary">
    <p class="text-sm text-gray-500">This message has not been sent to any recipients yet.</p>
  </div>
<% else %>
  <!-- existing bar/legend/groups -->
<% end %>
```

**Add test in `web/test/memba_web/live/member_message_delivery_live/show_test.exs`:**
```elixir
test "renders empty state when message has no receipts", %{conn: conn, member: member} do
  message = insert(:message, conversation: build(:conversation, club: member.club), receipts: [])
  
  {:ok, view, _html} = live(conn, ~p"/messages/#{message.id}/delivery")
  
  assert has_element?(view, "p", "not been sent to any recipients yet")
  refute has_element?(view, ".delivery-bar")
  refute has_element?(view, ".delivery-group")
end
```

### Fix 2: Percentage calculation (behavioral)

**In `web/lib/memba_web/live/member_message_delivery_live/show.ex`:**
```elixir
defp percentage(_count, 0), do: 0
defp percentage(count, total) when total > 0, do: Float.round(count / total * 100, 1)
```

**Add test:**
```elixir
test "renders safe bar widths with zero recipients", %{conn: conn, member: member} do
  message = insert(:message, conversation: build(:conversation, club: member.club), receipts: [])
  
  {:ok, _view, html} = live(conn, ~p"/messages/#{message.id}/delivery")
  
  # Verify no division errors and safe 0% widths if bar renders
  refute html =~ ~r/width: NaN/
  refute html =~ ~r/width: Infinity/
end

test "renders correct bar segment widths with normal recipients", %{conn: conn, member: member} do
  message = insert(:message, 
    conversation: build(:conversation, club: member.club),
    receipts: [
      build(:receipt, status: :delivered),
      build(:receipt, status: :delivered),
      build(:receipt, status: :failed)
    ]
  )
  
  {:ok, _view, html} = live(conn, ~p"/messages/#{message.id}/delivery")
  
  assert html =~ ~r/width: 66\.7%/  # 2/3 delivered
  assert html =~ ~r/width: 33\.3%/  # 1/3 failed
end
```

### Fix 3: Verify presentation counts location

**Inspect `web/lib/memba_web/member_email_delivery_presentation.ex`:**

If `present_receipts/1` returns only grouped lists without counts, refactor:
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

**Remove count derivation from LiveView:**
```elixir
defp assign_receipts(socket) do
  if socket.assigns[:message] do
    receipts =
      socket.assigns.message.id
      |> Messaging.list_member_email_deliverys()
      |> MemberEmailDeliveryPresentation.present_receipts()

    socket
    |> assign(receipts: receipts)
    |> assign(delivery_counts: receipts.counts)  # Use pre-computed
  else
    socket
  end
end
```

**Update test in `web/test/memba_web/member_email_delivery_presentation_test.exs` to assert counts are present.**

### Fix 4: Verify mount control flow

**Inspect `web/lib/memba_web/live/member_message_delivery_live/show.ex` mount:**

If current structure continues pipeline after redirect:
```elixir
def mount(%{"message_id" => message_id}, _session, socket) do
  case load_and_authorize_message(socket, message_id) do
    {:ok, socket} ->
      socket
      |> assign_receipts()
      |> assign_delivery_counts()
      |> then(&{:ok, &1})
    
    {:error, :not_found} ->
      {:ok, redirect(socket, to: ~p"/members")}
    
    {:error, :forbidden} ->
      {:ok, redirect(socket, to: ~p"/members")}
  end
end
```

This eliminates the inefficiency of continuing assignment after redirect decision.

## Judgement-worthy non-blocking code-health findings

None beyond the four issues above. The initial reviewers noted:

1. **Dynamic inline styles for bar widths** - Standard Phoenix/HEEx pattern for dynamic widths; acceptable.
2. **Global CSS class names** - Follows design-system mirror naming convention; intentional.
3. **Authorization pattern duplication** - Common for small LiveViews; refactoring to shared helper is future optimization.

These are not blockers given the current scope and project patterns.

## Suggested fixes

Resolve the four blocking issues by either:
1. Providing evidence that each is already correctly handled in the code
2. Applying the bounded-safe fixes above

Recommended order:
1. Fix 1 (zero-state) - behavioral requirement from plan
2. Fix 2 (percentage safety) - behavioral/runtime safety
3. Fix 3 (counts location) - verify or refactor presentation coupling
4. Fix 4 (mount flow) - verify or optimize control flow

All four should be resolvable within test/presentation/LiveView code without touching aggregates, events, or acceptance features.

## Validation notes

- Dev check passed before and after repair attempt (272 tests, 85 acceptance scenarios)
- Plan-conformance gate passed
- Core functionality appears complete: route, LiveView, template, CSS, kebab link, conversation cleanup
- Router test verifies wiring and pipelines
- The repair agent's claim that fixes weren't needed conflicts with verification failure (no diff produced)
- **Key gap:** Cannot verify the four issues are resolved without either seeing implementation code or seeing successful fix diffs

The implementation is **nearly mergeable** - it's functionally complete with green tests - but the prior repair cycle's failure to produce verifiable changes means these four code-health issues must be explicitly resolved by human inspection or corrective commits.