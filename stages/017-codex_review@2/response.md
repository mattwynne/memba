# Iteration 047 Review: Conversation Delivery Details

## Decision: REJECT

## Confidence: Medium

The core feature appears plan-conforming and `dev ci` passed, but the review context still contains unresolved review blockers. The attempted repair pass claimed these were already handled or covered, yet produced no working-tree diff and the repair verification failed. Given the plan explicitly calls out the no-receipts state and this page relies on computed delivery percentages, those behaviours need concrete code/test evidence or a follow-up implementation pass before merge.

## ADR conformance: PASS

No ADR violations detected from the supplied evidence.

The implementation appears to stay in the intended read-side Phoenix/LiveView layer:

- Adds member-scoped routing and LiveView UI.
- Uses existing messaging/read-model APIs.
- Keeps receipt display shaping in the web/presentation layer.
- Does not appear to modify aggregates, commands, events, projections, event streams, or delivery infrastructure.

## ADR violations

None.

## Blocking issues

1. **Unverified zero-recipient delivery state**

   - Files: `web/lib/memba_web/live/member_message_delivery_live/show.html.heex`, `web/test/memba_web/live/member_message_delivery_live/show_test.exs`
   - The plan explicitly notes that if a message has no receipts yet, the page should show an empty/none state.
   - The repair pass claimed this was already present and covered, but no diff or concrete evidence verified it.
   - Required: either show existing test/template evidence, or add an explicit empty state and LiveView coverage.

2. **Unverified delivery-bar percentage safety**

   - Files: `web/lib/memba_web/live/member_message_delivery_live/show.ex`, `web/lib/memba_web/live/member_message_delivery_live/show.html.heex`, relevant LiveView tests
   - The delivery summary bar depends on computed widths.
   - Zero-recipient messages must not produce division-by-zero failures, `NaN`, `Infinity`, malformed styles, or broken rendering.
   - Required: rendered-output test coverage for normal and zero-total cases, or clear existing evidence.

3. **Receipt summary/count ownership remains unverified**

   - Files: `web/lib/memba_web/member_email_delivery_presentation.ex`, `web/lib/memba_web/live/member_message_delivery_live/show.ex`
   - Reviewers flagged that counts/percentages should live with the receipt presentation model if that module already owns grouping.
   - The repair pass claimed this is already true, but verification produced no diff and no concrete evidence.
   - Required: confirm `MemberEmailDeliveryPresentation.present_receipts/1` returns the summary/count/percentage shape consumed by the LiveView, or move that logic there.

4. **Delivery LiveView redirect control flow remains unverified**

   - File: `web/lib/memba_web/live/member_message_delivery_live/show.ex`
   - The delivery page must not continue assigning receipts/counts after an unauthorized or not-found redirect path.
   - The repair pass claimed the current `mount/3` already uses a clean `case` flow, but this was not verified by a diff or excerpt.
   - Required: confirm the redirect/not-found branches return immediately, or refactor `mount/3` to make that control flow explicit.

## Bounded-safe fixes

1. **Add/confirm explicit empty-state rendering**

   Add a branch for `total_count == 0`, for example:

   ```heex
   <%= if @receipts.summary.total_count == 0 do %>
     <p>No delivery receipts yet.</p>
   <% else %>
     ...
   <% end %>
   ```

   Exact copy should match the current UI tone.

2. **Cover zero-total and normal percentage rendering**

   Add LiveView tests asserting:

   - zero recipients renders the empty state;
   - no recipient groups render for zero recipients, if that is the intended UI;
   - rendered HTML does not contain `NaN`, `Infinity`, or invalid widths;
   - non-zero mixed deliveries render expected bar segment widths.

3. **Centralize summary data in `MemberEmailDeliveryPresentation`**

   If not already present, have `present_receipts/1` return a complete presentation model, such as:

   ```elixir
   %{
     summary: %{
       total_count: total,
       delivered_count: delivered_count,
       failed_count: failed_count,
       pending_count: pending_count,
       delivered_percentage: delivered_percentage,
       failed_percentage: failed_percentage,
       pending_percentage: pending_percentage
     },
     groups: ...
   }
   ```

   Then keep the LiveView as a loader/assigner, not a second presenter.

4. **Make `mount/3` authorization flow auditable**

   Prefer:

   ```elixir
   case load_member_message(...) do
     {:ok, message} ->
       ...
       {:ok, socket}

     {:error, :not_found} ->
       {:ok, redirect(socket, to: ~p"/messages")}

     {:error, :forbidden} ->
       {:ok, redirect(socket, to: ~p"/messages")}
   end
   ```

   The key requirement is that receipt loading and presentation assignment only happen in the authorized `{:ok, message}` branch.

## Judgement-worthy non-blocking code-health findings

1. **Potential authorization-loader duplication**

   - Files: `web/lib/memba_web/live/member_message_delivery_live/show.ex`, existing member conversation/message detail loader code
   - Smell: the new delivery page must enforce exactly the same member/club authorization as the conversation page. If the logic was copied instead of shared, future authorization changes may drift.
   - Why it may need human judgement: small duplication may be acceptable for this iteration, but authz duplication is a higher-risk maintenance smell.

2. **Dynamic inline width styles**

   - Files: `web/lib/memba_web/live/member_message_delivery_live/show.html.heex`
   - Smell: delivery-bar segments likely use dynamic inline `style` attributes for widths.
   - Why it may need human judgement: this is reasonable for proportional bars, but if more visualizations are added, a CSS custom-property convention may be cleaner.

3. **Broad global delivery CSS class names**

   - File: `web/assets/css/app.css`
   - Smell: classes such as `delivery-summary`, `delivery-bar`, `delivery-group`, `recipient`, and `deliv-*` are globally scoped.
   - Why it may need human judgement: this follows the iteration plan and design-system mirror, so it is not a blocker, but these names are broad enough to collide with future UI unless intentionally reserved.

## Suggested fixes

Before merge, resolve the four blocking items by either:

1. Providing concrete code/test evidence that they are already satisfied; or
2. Applying a small implementation/test pass that:
   - adds explicit zero-recipient UI;
   - tests zero-recipient and normal percentage rendering;
   - verifies or centralizes delivery summary counts in `MemberEmailDeliveryPresentation`;
   - makes delivery LiveView redirect control flow explicit.

No acceptance feature-file edits are needed.

## Validation notes

- Preflight sandbox check passed.
- `dev ci` / dev check passed.
- Acceptance excerpt shows `85 scenarios (85 passed)` and `523 steps (523 passed)`.
- Plan-conformance was already accepted before this review.
- No ADR violation is evident.
- The review repair verification failed because the repair pass produced no working-tree diff, leaving the synthesized blockers unresolved in the current review context.