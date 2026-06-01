# Member receipt detail LiveView polish

Date: 2026-06-01
Status: ready

## Goal

Polish the member-facing message receipt detail experience so members can understand a club message's reach at a glance, then expand only the receipt groups they care about.

After this iteration, the existing member message detail route should behave like the wireframe's receipt screen: a LiveView-powered page with a “Who got this” summary bar, visible counts and percentages for each member-facing status, descriptive receipt groups collapsed by default, and expand/collapse interaction that reveals recipient rows without exposing operator diagnostics.

## Background / Context

Iteration 011 delivered the working member-facing message journey:

- signed-in members can open their club home;
- Alice can send a message to all active club members;
- members can open a member-facing message detail page;
- member receipt statuses are grouped and displayed with the simplified vocabulary `Sending`, `Delivered`, `Delivery problem`, and `Opened`;
- staff/operator diagnostics remain under `/admin/*`.

The design reference is richer than the current implementation, especially for message receipts. Use these iteration 011 design files as the visual target:

- `docs/iterations/011-member-facing-message-behaviour/designs/Member Messaging Wireframes.html`
- `docs/iterations/011-member-facing-message-behaviour/designs/wireframes/receipts.jsx`
- `docs/iterations/011-member-facing-message-behaviour/designs/wireframes/wireframes.css`

Current implementation notes:

- `GET /messages/:message_id?club_id=<club_id>` is currently handled by `MembaWeb.PageController.show_message/2` and `web/lib/memba_web/controllers/page_html/message.html.heex`.
- `MembaWeb.MemberReceiptPresentation` already maps internal receipt statuses to member-facing labels and Heroicons.
- The existing browser Cucumber scenarios already prove the business rule that members see simple shared receipt statuses.

## Scope

### In scope

- Convert or replace the member message detail page with a Phoenix LiveView at the same member-facing route shape: `GET /messages/:message_id?club_id=<club_id>`.
- Preserve existing route semantics and failure behaviours:
  - unauthenticated visitors are sent through the existing magic-link sign-in flow, preserving return path;
  - signed-in users must be active members of the selected `club_id`;
  - message detail is shown only when the message belongs to the selected club;
  - signed-in non-members/inactive members receive the existing forbidden response;
  - message/club mismatch or missing messages receive existing not-found behaviour.
- Add a “Who got this” summary section above the grouped receipt rows:
  - segmented horizontal status bar;
  - visible count and percentage for each status;
  - status order: `Opened`, `Delivered`, `Sending`, `Delivery problem`;
  - percentages calculated from the addressed receipt count, with deterministic handling when there are zero receipts.
- Add member-friendly status descriptions matching the wireframe intent:
  - `Opened`: read it;
  - `Delivered`: arrived, not opened yet;
  - `Sending`: on its way;
  - `Delivery problem`: we couldn't reach them.
- Render receipt groups collapsed by default.
- Add LiveView expand/collapse behaviour for each visible status group:
  - render group headers only for statuses with at least one receipt;
  - clicking a group header toggles that group;
  - expanded groups reveal the recipient rows for that status;
  - collapsing hides those rows again;
  - each recipient row keeps stable attributes needed by existing browser acceptance support, including `data-testid="member-receipt"`, `data-recipient-name`, and `data-receipt-status`.
- Polish the member receipt detail layout toward `receipts.jsx`, using Phoenix/Tailwind conventions and the existing `<.icon>` component.
- Keep member-facing pages free of operator-only information: delivery IDs, provider event names, webhook metadata, raw provider delivery statuses, recipient email addresses, and failure reasons.
- Keep staff/operator diagnostics unchanged under `/admin/*`.
- Keep existing browser Cucumber scenarios green without changing `acceptance-tests/features/member_message_deliverability.feature`.
- Keep `dev check` green.

### Out of scope

- Dashboard/home-page visual polish.
- Separate compose route, compose success screen, or compose error screen.
- Changing message sending, recipient resolution, delivery projection, Postmark/webhook behaviour, or receipt status vocabulary.
- Real-time receipt updates while a member is viewing the page, unless this falls out trivially from the LiveView conversion.
- Sender-inclusion policy changes.
- Recipient selection, drafts, scheduling, attachments, replies, templates, or rich editor behaviour.
- Custom club domains or host-based club resolution.

## Iteration Type

Behaviour-facing presentation and interaction polish.

The underlying business rule does not change: active club members can see simplified shared receipt statuses for addressed members. The user-observable improvement is that the member receipt page becomes easier to scan and interact with through a LiveView summary and collapsible groups.

## Acceptance Scenarios / Feature Files

BDD decision: Not useful for this slice.

No Gherkin feature-file changes are planned. `acceptance-tests/features/member_message_deliverability.feature` already documents the relevant member-facing rule: members see simple shared receipt statuses for everyone addressed. Iteration 012 changes the presentation and interaction of that already-covered rule.

The existing scenarios should remain unchanged and meaningful. Implementation may update browser acceptance support so row assertions expand the relevant receipt group before checking addressed members. That keeps the stakeholder language focused on the rule (“members see shared receipt statuses”) rather than the UI mechanics of opening a collapsible section. Focused LiveView tests will specify the new presentation behaviour: summary counts, initial collapsed state, toggling, row visibility, and zero-count status handling.

## Acceptance Criteria

- The member message detail route remains `GET /messages/:message_id?club_id=<club_id>` from a user's perspective.
- Existing member-message browser Cucumber scenarios continue to pass unchanged.
- The member message detail page is implemented as a LiveView or LiveView-backed route capable of server-side expand/collapse interaction.
- The page shows subject, body, sender, and addressed receipt count as before.
- The page shows a “Who got this” summary with status bar, counts, and percentages for all four member-facing statuses: `Opened`, `Delivered`, `Sending`, and `Delivery problem`.
- Percentages are calculated from the total addressed receipt count and are displayed as whole percentages whose total is sensible for users. Zero-receipt messages show `0` counts and `0%` for each status rather than crashing or displaying misleading divide-by-zero values.
- The summary always represents all four statuses, including zero-count statuses.
- The grouped recipient list renders group headers only for statuses with at least one receipt; zero-count statuses appear in the summary only.
- Visible receipt groups appear in this order: `Opened`, `Delivered`, `Sending`, `Delivery problem`.
- Visible receipt groups are collapsed by default.
- Each visible receipt group header shows icon, member-facing label, description, count, and percentage.
- Clicking a collapsed group expands it and reveals recipient rows for that status.
- Clicking an expanded group collapses it and hides recipient rows for that status.
- Collapsed groups show no recipient rows in the DOM or hide them from ordinary browser visibility assertions.
- Expanded recipient rows preserve stable browser-test attributes used by the existing acceptance support.
- The page does not expose delivery IDs, provider event names, webhook metadata, raw provider statuses, recipient email addresses, or delivery failure reasons.
- Existing authorization/error behaviours are preserved for unauthenticated visitors, non-members, inactive members, and message/club mismatches.
- Staff/operator diagnostics under `/admin/*` continue to work unchanged.
- `dev check` passes.

## Open Business Decisions

None known.

The choice to make groups collapsed by default and show both counts and percentages has been made for this slice.

## Implementation Plan

1. Inspect the current member message route, controller template, auth plugs, and existing route/feature tests around `PageController.show_message/2`.
2. Introduce a member message detail LiveView, for example `MembaWeb.MemberMessageLive.Show`, using Phoenix 1.8 routing conventions and avoiding duplicate scope aliases.
3. Route `GET /messages/:message_id` through the existing `:browser` and `:club_member_required` pipelines to the LiveView while preserving the same URL shape and `club_id` query parameter.
4. Move the existing message detail loading and authorization logic into a clear LiveView mount path or supporting context/helper:
   - require a selected club from the authenticated identity's active clubs;
   - load the message;
   - ensure `message.club_id == club_id`;
   - render existing forbidden/not-found semantics where applicable.
5. Build a receipt presentation model for the LiveView:
   - reuse `MembaWeb.MemberReceiptPresentation` for labels and icons;
   - add descriptions, display order, counts, and percentages;
   - create deterministic summary data for all four statuses;
   - create group data only for statuses whose count is greater than zero.
6. Render the polished message detail page with `<Layouts.club_site>` and Phoenix/Tailwind styling inspired by `receipts.jsx`.
7. Add LiveView state for collapsed groups:
   - all visible groups collapsed initially;
   - `handle_event("toggle_receipt_group", ...)` toggles a status key;
   - avoid custom JavaScript unless needed.
8. Preserve the existing stable DOM/test attributes for recipient rows.
9. Update browser acceptance support, if needed, so existing member-message scenarios can find addressed recipient rows by expanding the relevant visible group before asserting row content. Do not change the Gherkin feature text for this iteration.
10. Add focused LiveView/ConnCase tests covering:
   - route and authorization behaviours preserved;
   - summary counts and percentages for mixed statuses;
   - all visible groups collapsed by default;
   - expand/collapse reveals and hides rows;
   - zero-count statuses appear in the summary only, not as empty expandable groups;
   - no operator-only fields appear on the member page.
11. Run the existing member-message browser Cucumber scenarios and `dev check`.

## Open Technical Decisions

- Exact LiveView module name and whether small helper functions live in the LiveView or a presentation module. Prefer simple module boundaries that keep receipt calculations testable without over-engineering.

Resolved for this plan:

- Zero-count statuses appear in the “Who got this” summary only, with count `0` and `0%`. They do not appear as empty collapsible group headers in the recipient list.
- Existing Gherkin scenarios remain unchanged. Browser acceptance support may expand the relevant visible receipt group before asserting addressed recipient rows, while LiveView tests cover the collapse/expand UI behaviour directly.

## New Capability

Members can scan a message's reach using a summary bar with counts and percentages, then expand specific receipt groups to see which members are in each status without leaving the page.

## Validation Plan

- Run `dev check`.
- Run targeted LiveView/Phoenix tests for the new member message detail LiveView.
- Confirm existing `acceptance-tests/features/member_message_deliverability.feature` passes unchanged through the browser runner; if row assertions fail because groups are collapsed, fix the browser support to expand the relevant group rather than changing the feature language.
- Manual demo:
  - sign in as Alice;
  - open a message with mixed receipt statuses;
  - confirm the summary bar shows all four statuses, including any zero-count statuses;
  - confirm zero-count statuses do not appear as empty groups in the recipient list;
  - confirm non-empty group counts, percentages, descriptions, and default collapsed state;
  - expand and collapse each non-empty group;
  - confirm recipient rows appear only when their group is expanded;
  - confirm no operator-only details are visible;
  - confirm `/admin/*` diagnostics still show operator detail for staff.

## Risks / Follow-ups

- LiveView conversion may require carefully preserving controller-era auth and error semantics.
- Browser acceptance support may need a small update to expand the relevant group before asserting recipient rows; keep this in support code and leave the feature language unchanged.
- Percent rounding can produce totals that do not add exactly to 100%; choose a user-friendly deterministic approach and test it.
- This does not address dashboard polish or separate compose screens; those remain good future iterations.
