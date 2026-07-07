# Iteration 047 Review: Conversation Delivery Details

## Decision: REJECT

## Confidence: Medium

The implementation appears broadly plan-conforming and `dev ci` passed, but the review context still has unresolved blocker-class concerns around zero-recipient behaviour, delivery-bar percentage safety, presentation ownership, and LiveView redirect control flow. A repair pass claimed these were already handled or covered, but verification found no working-tree diff from the repair baseline, so the review evidence still does not prove those blockers are resolved.

This is likely close to mergeable, but the remaining issues need either concrete code/test evidence or a small follow-up implementation/test pass.

## ADR conformance: PASS

No ADR violations are evident from the supplied implementation evidence.

The change appears to stay within the intended read-side Phoenix/LiveView scope:

- Adds a member-scoped LiveView route for `/messages/:message_id/delivery`.
- Reuses existing messaging/read-model APIs.
- Keeps receipt display shaping in the web/presentation layer.
- Does not appear to alter aggregates, commands, events, projections, event streams, or delivery infrastructure.
- Does not appear to replace ADR-governed Commanded/CQRS/event-sourcing infrastructure with local substitutes.

## ADR violations

None detected.

## Blocking issues

1. **Zero-recipient delivery state remains unverified**

   - Files: `web/lib/memba_web/live/member_message_delivery_live/show.html.heex`, `web/test/memba_web/live/member_message_delivery_live/show_test.exs`
   - The plan explicitly calls out the no-receipts case: “if a message has no receipts yet, the page shows an empty/none state.”
   - The repair pass claimed this was already present and covered, but produced no verified diff.
   - This is behavioural, not just polish. The delivery page must render a clear empty state for messages with no receipts, and automated coverage should prove it.

2. **Delivery-bar percentage safety remains unverified**

   - Files: `web/lib/memba_web/live/member_message_delivery_live/show.ex`, `web/lib/memba_web/live/member_message_delivery_live/show.html.heex`, related LiveView tests
   - The delivery summary bar depends on computed percentage widths.
   - Zero-recipient messages must not produce division-by-zero failures, `NaN`, `Infinity`, malformed styles, or broken rendering.
   - Green `dev ci` is useful, but the visible evidence does not prove the zero-total case or rendered percentage output is covered.

3. **Receipt summary/count ownership remains unverified**

   - Files: `web/lib/memba_web/member_email_delivery_presentation.ex`, `web/lib/memba_web/live/member_message_delivery_live/show.ex`
   - The review concern is that grouping, counts, and percentages should live together in the receipt presentation model rather than being partly recomputed in the LiveView.
   - The repair agent claimed `MemberEmailDeliveryPresentation.present_receipts/1` already returns counts and percentages, and that the LiveView consumes them, but the verification stage produced no code diff or excerpt proving this.
   - If the LiveView is deriving counts from presentation internals, that is maintainability coupling that should be fixed before merge or explicitly accepted by a human reviewer.

4. **Delivery LiveView redirect control flow remains unverified**

   - File: `web/lib/memba_web/live/member_message_delivery_live/show.ex`
   - The LiveView should not continue assigning/loading receipts after an unauthorized or not-found message branch.
   - The repair agent claimed the current `mount/3` already uses an immediate-return `case` flow, but this was not verified by a diff or code excerpt.
   - This is less severe than the zero-recipient and percentage issues, but because it concerns authorization/error control flow it should be proven before merge.

## Bounded-safe fixes

1. **Add or prove explicit empty-state rendering**

   Add/confirm a branch similar to:

   ```heex
   <%= if @delivery.summary.total_count == 0 do %>
     <p>No delivery receipts yet.</p>
   <% else %>
     ...
   <% end %>
   ```

   The exact copy should match the existing product tone and design.

2. **Add rendered-output tests for zero-recipient and normal percentage cases**

   Add LiveView tests asserting:

   - a no-receipts message renders the empty state;
   - no recipient groups render when there are no receipts, if that is the intended UI;
   - rendered HTML does not contain `NaN`, `Infinity`, or invalid width styles;
   - a mixed receipt set renders expected percentage widths.

3. **Centralize delivery summary data in `MemberEmailDeliveryPresentation`**

   If not already implemented, have `present_receipts/1` return a complete presentation model, for example:

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

   Then keep the LiveView responsible for loading/assigning, not recomputing delivery summary semantics.

4. **Make `mount/3` authorization flow explicit**

   Prefer a structure where receipt loading only occurs in the authorized branch:

   ```elixir
   case load_member_message(...) do
     {:ok, message} ->
       ...
       {:ok, socket}

     {:error, :not_found} ->
       {:ok, redirect(socket, to: fallback_path)}

     {:error, :forbidden} ->
       {:ok, redirect(socket, to: fallback_path)}
   end
   ```

## Judgement-worthy non-blocking code-health findings

1. **Potential authorization-loader duplication**

   - Files: `web/lib/memba_web/live/member_message_delivery_live/show.ex`, existing member conversation/message detail loader code
   - Smell: the delivery page must enforce exactly the same member/club authorization as the conversation page. If the logic was copied rather than shared, future changes could drift.
   - Why it may need human judgement: small duplication may be acceptable for a focused LiveView, but duplicated authz logic is a common long-term security maintenance risk.

2. **Dynamic inline width styles**

   - Files: `web/lib/memba_web/live/member_message_delivery_live/show.html.heex`
   - Smell: delivery-bar segments likely use dynamic `style` attributes for widths.
   - Why it may need human judgement: inline dynamic widths are reasonable for proportional bars, but if this pattern spreads, a CSS custom-property convention may make templates cleaner and easier to audit.

3. **Broad global CSS class names**

   - File: `web/assets/css/app.css`
   - Smell: classes such as `delivery-summary`, `delivery-bar`, `delivery-legend`, `delivery-group`, `recipient`, and `deliv-*` are globally scoped and fairly generic.
   - Why it may need human judgement: the plan explicitly asked to port design-system names 1:1, so this should not block the iteration. Longer term, these names should either be intentionally reserved by the design system or scoped to avoid future collisions.

## Suggested fixes

Before merge, do one of the following:

1. Provide concrete code/test evidence proving all four blockers are already satisfied; or
2. Apply a small follow-up implementation/test pass that:
   - adds or confirms explicit no-receipts empty-state UI;
   - adds rendered-output tests for zero-recipient and normal percentage rendering;
   - ensures delivery counts/percentages come from `MemberEmailDeliveryPresentation`;
   - makes delivery LiveView redirect branches return before receipt assignment.

No acceptance feature-file edits are needed.

After any code/test changes, run the project-required check again:

```sh
PATH="$PWD/bin:$PATH" dev ci
```

## Validation notes

- Preflight sandbox check passed.
- `dev ci` / dev check passed.
- Acceptance suite excerpt shows `85 scenarios (85 passed)` and `523 steps (523 passed)`.
- No acceptance feature-file changes were indicated.
- Plan-conformance had already passed before this polish review.
- Review repair verification failed because the repair pass produced no working-tree diff relative to its captured baseline.
- The implementation appears close, but the remaining blocker-class concerns need verified code/test evidence before acceptance.