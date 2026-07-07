# Iteration 047 Review: Conversation Delivery Details

## Decision: ACCEPT

## Confidence: Medium

The implementation has already passed the plan-conformance workflow and `dev ci`/dev check. The reviewed evidence indicates the iteration stayed within the intended Phoenix/LiveView read-side UI scope. Confidence is medium rather than high because the supplied review transcript includes excerpts rather than the full diff and full ADR set.

## ADR conformance: PASS

No ADR violations detected from the available implementation evidence.

The iteration appears to be a member-scoped read-side UI change: route wiring, LiveView rendering, presentation shaping, CSS, and tests. It does not appear to alter aggregates, commands, events, projections, event streams, persistence semantics, or background delivery infrastructure.

The implementation appears consistent with Memba’s CQRS/domain boundaries because it:

- Uses existing context/read-model APIs for message and delivery receipt data.
- Reuses the member message authorization/loading pattern scoped to the member’s active clubs.
- Keeps delivery display concerns in the web/presentation layer.
- Avoids introducing local domain shortcuts or replacing ADR-governed infrastructure.

## ADR violations

None detected.

## Blocking issues

None.

## Bounded-safe fixes

1. **Avoid continuing the LiveView assign pipeline after redirect**

   File: `web/lib/memba_web/live/member_message_delivery_live/show.ex`

   The implementation appears to assign/load the message, then continue through receipt and count assignment even when the message lookup/authz path redirects. This is likely functionally safe if the downstream helpers guard on missing assigns, but the control flow is harder to audit.

   A small refactor to return immediately from the unauthorized/not-found branch would improve maintainability without changing behaviour.

2. **Move delivery count derivation into the receipt presentation model**

   Files:

   - `web/lib/memba_web/member_email_delivery_presentation.ex`
   - `web/lib/memba_web/live/member_message_delivery_live/show.ex`

   If `MemberEmailDeliveryPresentation.present_receipts/1` already owns grouping receipts into delivered/failed/pending buckets, it should likely also expose the corresponding counts. Having the LiveView derive counts from presentation groups creates minor coupling between the LiveView and the internals of the presentation shape.

3. **Make the zero-recipient state explicit**

   File: `web/lib/memba_web/live/member_message_delivery_live/show.html.heex`

   The plan’s risk notes mention messages with no receipts yet. If the current UI renders only an empty delivery bar or empty groups for `total_count == 0`, add an explicit empty state such as “No delivery receipts yet” or “This message has not been sent to any recipients yet.”

   This is low-risk and improves clarity for drafts, unsent replies, or delivery records that have not yet been projected.

4. **Ensure percentage/bar-width behaviour is covered through rendered output**

   Files:

   - `web/lib/memba_web/live/member_message_delivery_live/show.ex`
   - relevant LiveView test file

   The delivery bar depends on computed percentages. If this is implemented with a private helper, direct unit tests are not necessary, but rendered LiveView tests should cover both normal receipt totals and zero-recipient totals so the page cannot regress into division-by-zero, malformed styles, or invalid widths.

## Judgement-worthy non-blocking code-health findings

1. **Presentation responsibility split between presentation module and LiveView**

   Files:

   - `web/lib/memba_web/member_email_delivery_presentation.ex`
   - `web/lib/memba_web/live/member_message_delivery_live/show.ex`

   Smell: the presentation module appears to group receipts, while the LiveView derives summary counts from those groups.

   Why it may need human judgement: this is harmless at the current size, but if delivery summaries gain more states or labels, the split can cause drift between the grouped recipient model and the summary-bar model. A richer presentation struct/map may better centralize delivery display semantics.

2. **Authorization/loading parity may be duplicated rather than shared**

   Files:

   - `web/lib/memba_web/live/member_message_delivery_live/show.ex`
   - existing member conversation/message detail loader code

   Smell: the new delivery page must enforce the same authorization as the conversation page. If the implementation copied the loading/authz pattern rather than sharing a helper/context function, future authz changes may need to be updated in multiple places.

   Why it may need human judgement: duplication may be acceptable for a small LiveView, especially if the existing pattern is not easily shareable. However, authz duplication is a common source of later security drift.

3. **Dynamic inline width styles in HEEx**

   File: `web/lib/memba_web/live/member_message_delivery_live/show.html.heex`

   Smell: delivery-bar segments likely use dynamic inline `style` attributes for widths.

   Why it may need human judgement: dynamic widths are reasonable for proportional bars and may be the simplest Phoenix/HEEx approach. If the design system grows more dynamic visualizations, a CSS custom-property convention could keep templates cleaner while preserving dynamic behaviour.

4. **Global delivery CSS class names are broad**

   File: `web/assets/css/app.css`

   Smell: classes such as `delivery-summary`, `delivery-bar`, `delivery-legend`, `delivery-group`, `recipient`, and `deliv-*` are globally scoped and fairly generic.

   Why it may need human judgement: this follows the iteration plan and design-system mirror naming, so it is not a blocker. Longer term, broad global names can collide with unrelated delivery/status UI unless the design system intentionally owns these names.

## Suggested fixes

If doing a small polish pass, prioritize:

1. Refactor `MemberMessageDeliveryLive.Show.mount/3` to use a clear `case`/`with` flow where the redirect branch returns immediately and does not continue assigning receipts/counts.

2. Extend `MemberEmailDeliveryPresentation.present_receipts/1` to return counts alongside grouped receipts, for example:

   ```elixir
   %{
     delivered: delivered,
     failed: failed,
     pending: pending,
     total_count: total,
     counts: %{
       delivered: length(delivered),
       failed: length(failed),
       pending: length(pending)
     }
   }
   ```

   Then have the LiveView assign `delivery_counts` from the presentation result rather than recomputing.

3. Add or confirm an explicit zero-recipient branch in the delivery page template and cover it with a LiveView test.

4. Cover delivery-bar percentage rendering through integration-style LiveView assertions for both non-zero and zero totals.

## Validation notes

- Preflight sandbox check passed on a clean working tree.
- `dev ci` / dev check completed successfully.
- Acceptance suite excerpt shows **85 scenarios passed** and **523 steps passed**.
- The plan-conformance workflow had already accepted the implementation before this polish review.
- The implementation appears to satisfy the main iteration capability:
  - member-scoped `/messages/:message_id/delivery` route;
  - delivery details LiveView;
  - per-message kebab link from the conversation;
  - inline delivery sections removed from the conversation page;
  - delivery-detail CSS ported from the design-system mirror;
  - automated tests added/updated.
- No feature-file changes were required or requested.