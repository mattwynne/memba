# 047 — Delivery details page + relocate delivery off the conversation

Date: 2026-07-04
Status: implementing

> Written 2026-07-04 against the refreshed `member-conversation.html` + `delivery-details.html`,
> grounded in the current `message.html.heex` and `member_message_detail.ex`. Delivers after 044
> (shell), 045 (tabs), 046 (conversation alignment) in number order.

## Goal

Complete the refreshed conversation design's **delivery relocation**: add a per-message
**Delivery details** page (per `design-system/wireframes/delivery-details.html`), reached from a
**⋮ menu** on each conversation message, and **remove the two inline delivery sections** from the
conversation page.

## Background / Context

Today the conversation page (`page_html/message.html.heex`) carries two heavy inline delivery
blocks — a "Message delivery" summary bar and a "Members by delivery status" grouped breakdown —
plus a "sent to N members" meta line. The refreshed design moves all of this **off** the
conversation onto a dedicated per-message Delivery details page, reached from a ⋮ menu on the
original message and each reply. Iteration 046 aligned the conversation's follow control, ordering,
and timestamps but deliberately left the inline delivery in place; **this slice relocates it**.

The delivery data already exists: the conversation loader builds its receipt model with
`Messaging.list_member_email_deliverys(message_id) |> MemberEmailDeliveryPresentation.present_receipts()`
(summary, groups, receipts, total_count). This slice re-presents that same data on a new route.

## Related Problems

- [`docs/problems/2026-06-23-interface-too-fancy-for-simple-app-use.md`](../../problems/2026-06-23-interface-too-fancy-for-simple-app-use.md)
  — **partially addresses.** Declutters the conversation; delivery detail moves to its own page.

## Scope

### In scope

- A new **member route** `/messages/:message_id/delivery` rendering a **Delivery details** page for
  that message, with the **same authorization** as the conversation Show route.
- The page matches `delivery-details.html`: message header (subject / sender / time), a summary bar
  + legend, and grouped recipients — **problems expanded**, **delivered collapsed** — with bounce
  reasons, plus a "Back to conversation" link.
- A per-message **⋮ menu** on the original message and each reply (in `conversation_entry_card`)
  linking to that message's delivery page.
- **Remove** the inline `#member-receipt-summary` section and the "Members by delivery status"
  grouped section from `message.html.heex`, and the "sent to N members" delivery meta line.

### Out of scope

- Any change to how delivery status is computed, or to delivery **statuses** themselves.
- Staff delivery views (`/deliveries`, staff `MessagesLive`).
- The conversation follow/reply/timestamp changes (046) and the club home (045).

## Iteration Type

**Technical / UI restructure (re-presentation + new read-only route).** User-observable (delivery
moves to its own page), but **no new business rule**: the delivery data is unchanged and the new
page shows the same information already visible inline today, under the same access.

## Acceptance Scenarios / Feature Files

**BDD decision: Not useful for this slice.** No new business rule or permission is introduced — the
per-recipient delivery data is the same already shown inline and already covered by the deliverability
scenarios; the new route carries the **same authorization** as the conversation page. This is a
relocation/re-presentation, verified by LiveView/route tests. No `.feature` files change; mainline
stays green.

## Designs

**Design of record:** [`design-system/wireframes/delivery-details.html`](../../../design-system/wireframes/delivery-details.html)
(the Delivery details page) and [`design-system/wireframes/member-conversation.html`](../../../design-system/wireframes/member-conversation.html)
(the per-message ⋮ → Delivery details menu, and a conversation with no inline delivery).
**No new design needed.**

## Acceptance Criteria

- Each conversation message (original + every reply) shows a **⋮ menu** with a **Delivery details**
  item linking to `/messages/:message_id/delivery` for that message.
- The Delivery details page shows the message header, a summary bar + legend, and grouped recipients
  with **problems expanded** and **delivered collapsed**, including bounce reasons, plus a
  **Back to conversation** link.
- The conversation page **no longer** renders the inline delivery summary, the "Members by delivery
  status" breakdown, or the "sent to N members" meta line.
- The delivery route enforces the **same authorization** as viewing the conversation.
- Delivery **data and statuses are unchanged** — this only relocates the presentation.

## Open Business Decisions

None known.

## Implementation Plan

1. Add a member-scoped route `live "/messages/:message_id/delivery", MemberMessageDeliveryLive.Show`
   in `web/lib/memba_web/router.ex`, in the same authenticated member scope as the message Show route.
2. Create `MemberMessageDeliveryLive.Show` that loads the target message and its receipt model via
   `Messaging.list_member_email_deliverys/1 |> MemberEmailDeliveryPresentation.present_receipts/1`,
   scoped to the member's active clubs (reuse the `member_message_detail` load pattern and authz).
3. Build the delivery page template per `delivery-details.html`: header (subject / sender /
   `inserted_at`), summary bar + legend, grouped recipients (problems expanded, delivered collapsed).
4. Show each recipient's bounce reason for the "didn't go through" group, from the existing receipt
   presentation fields; keep the delivered group collapsed with a count.
5. Port the delivery-details CSS (`delivery-summary`, `delivery-bar`, `delivery-legend`,
   `delivery-group`, `recipient`, `deliv-*` tints) from `design-system/` into
   `web/assets/css/app.css`, names 1:1 with the mirror.
6. Add a **Back to conversation** link on the delivery page returning to the message's conversation.
7. Add a per-message **⋮ menu** to `conversation_entry_card` (`page_html.ex`) with a Delivery details
   item linking to `/messages/#{message_id}/delivery`.
8. Remove the inline `#member-receipt-summary` section and the "Members by delivery status" grouped
   section from `message.html.heex`.
9. Remove the "sent to N members" delivery meta line from the conversation subject header.
10. Add tests: the delivery route renders the per-recipient breakdown for a message; it enforces the
    same authz as the conversation; the conversation kebab links to it; the conversation no longer
    renders the inline delivery sections.
11. Run `./bin/dev gallery-walk` and compare the delivery page to `delivery-details.html` and the
    conversation to `member-conversation.html`.
12. Run `dev check` and confirm it is green (no feature-file changes).

## Open Technical Decisions

None open. **Route/module: decided —** `MemberMessageDeliveryLive.Show` at
`/messages/:message_id/delivery`, in the member scope, reusing the conversation loader's receipt
model and authorization. Replies are messages too, so each reply's ⋮ links to its own delivery page.

## New Capability

Members reach a focused **Delivery details** page per message, and the conversation page is
decluttered of inline delivery — matching the refreshed design.

## Validation Plan

- **Automated:** LiveView/route tests (delivery page renders the breakdown; authz parity; kebab
  link; inline sections removed); `dev check` green.
- **Visual:** `./bin/dev gallery-walk`; compare to `delivery-details.html` and `member-conversation.html`.
- **Manual:** open a conversation, use a message's ⋮ → Delivery details, see the breakdown, and
  return via Back to conversation.

## Risks / Follow-ups

- **Reply receipts:** replies are emailed to followers, so a reply's delivery page shows its own
  (smaller) recipient set; if a message has no receipts yet, the page shows an empty/none state.
- Depends on 044 (shell); follows 045/046 in the delivery order. Builds directly on the 046 kebab-less
  conversation (046 leaves inline delivery; 047 removes it).
