# 046 — Conversation page: follow toggle, replies-first, message timestamps

Date: 2026-07-04
Status: implementing

> Finalised 2026-07-04. Written against the refreshed `member-conversation.html`; grounded in the
> current `message.html.heex` and `member_message_detail.ex`. Delivers after 044 (shell) and 045
> (tabs) in number order. Repurposes the 046 slot (previously a duplicate club-home-tabs draft,
> superseded by 045).

## Goal

Align the member conversation page (`page_html/message.html.heex` / `MemberMessageDetailLive`) to
the refreshed `design-system/wireframes/member-conversation.html` **interaction model**, without
touching delivery: replace the follow card+buttons with a compact **toggle**, move the reply
**composer below the replies** (replies-first reading order), add **timestamps** to the original
message and each reply, and give messages the boxed **card** treatment.

## Background / Context

The refreshed conversation design changed the page's interaction model. Today's app shows: header
→ follow card (heading + Follow/Stop buttons) → composer → replies → two heavy inline delivery
sections. The design shows: subject with a compact follow **toggle** beside it → boxed original
message with a timestamp → reply cards with timestamps → composer at the **bottom**.

**Delivery is deliberately excluded from this slice.** The refreshed design also removes inline
delivery entirely and relocates it to a per-message ⋮ → **Delivery details** page — a change that
needs a **new page** and is its own slice (**047**). This slice leaves the existing inline delivery
sections in place (interim) and changes only the follow control, ordering, timestamps, and card
treatment.

## Related Problems

- [`docs/problems/2026-06-22-conversation-page-design-barer-than-app.md`](../../problems/2026-06-22-conversation-page-design-barer-than-app.md)
  — **partially addresses** (card treatment + composer states already shipped; this aligns the
  follow control, ordering, and timestamps).
- [`docs/problems/2026-06-23-interface-too-fancy-for-simple-app-use.md`](../../problems/2026-06-23-interface-too-fancy-for-simple-app-use.md)
  — **partially addresses** (lighter follow control; replies-first reading).

## Scope

### In scope

- Replace the follow **card + Follow/Stop-following buttons** with the compact follow **toggle**
  beside the subject, preserving the existing follow/unfollow behaviour and the can-follow gating.
- Move the reply **composer below the replies** (replies-first reading order), preserving the
  composer, "Replying as {name}", and the posted / validation-error states.
- Add a **timestamp** to the original message and to each reply card.
- Apply the boxed **message-card** treatment (original + replies) per the design.

### Out of scope

- **Delivery relocation** — the per-message ⋮ → Delivery details page and removing the inline
  delivery sections (its own slice, 047). Inline delivery stays as-is here.
- Any change to follow/reply **behaviour**, permissions, or notification rules.
- The club home (045) and member roles (048).

## Iteration Type

**Technical / UI restructure (presentation).** User-observable, but **no new business rule**:
follow, reply, and delivery behaviour are unchanged.

## Acceptance Scenarios / Feature Files

**BDD decision: Not useful for this slice.** No new business rule, permission, or lifecycle state
is introduced — follow and reply behaviour are unchanged and already covered by the existing
conversation/replies scenarios. The presentation changes (follow toggle, composer position,
timestamps, card treatment) are verified by LiveView tests. No `.feature` files change; mainline
stays green.

## Designs

**Design of record:** [`design-system/wireframes/member-conversation.html`](../../../design-system/wireframes/member-conversation.html)
(refreshed 2026-07-04) — compact follow toggle beside the title, boxed message cards with
timestamps, composer below the replies. This slice omits the design's ⋮ → Delivery details menu
and the removal of inline delivery (deferred to 047). **No new design needed.**

## Acceptance Criteria

- The follow control is a compact **toggle** beside the subject; toggling it follows / stops
  following with the same behaviour and gating as today.
- The reply **composer renders below the replies**; posting a reply and the posted / empty-reply
  validation states still work.
- The original message and each reply show a **timestamp**.
- Original message and replies render as boxed **cards** matching the design.
- Delivery behaviour and the existing delivery sections are unchanged (relocation is 047).

## Open Business Decisions

None known (delivery relocation split out to 047, confirmed intended).

## Implementation Plan

1. Add a private `format_message_time/1` helper (near `conversation_entry_card` in
   `web/lib/memba_web/controllers/page_html.ex`) that formats a `%DateTime{}` like the design
   ("3 Jun, 7:02am").
2. In `conversation_entry_card` (`page_html.ex`), render `@entry.message.inserted_at` via that
   helper in the card head, beside the sender name — a timestamp on the original and every reply.
3. Port the follow-toggle CSS (`follow-toggle` and its children) and the `detail-head` title row
   from `design-system/` into `web/assets/css/app.css`, names 1:1 with the mirror.
4. In `message.html.heex`, wrap the subject `<h1>` and the follow control in a `detail-head` row so
   the follow control sits compactly beside the title.
5. Replace the `#member-conversation-follow-control` card + Follow/Stop buttons with a compact
   follow **toggle** (checkbox/switch) that reads as following/not-following from
   `@following_conversation`.
6. Wire the toggle to the existing `follow_conversation` / `unfollow_conversation` events (fire the
   matching event from the toggle's change), unchanged server-side.
7. Preserve the non-member state: when `!@can_follow_conversation`, show the existing
   "Only current club members can follow…" explanation instead of an interactive toggle.
8. Move the `#member-message-reply-composer` block to render **after** `#member-conversation-replies`
   (composer below the replies), keeping "Replying as {name}" and the posted / validation-error states.
9. Apply the boxed message-card treatment to the original and reply cards in `conversation_entry_card`
   so they match the design (`message` / `message--original`).
10. Update `MemberMessageDetailLive` tests: follow toggle reflects and changes following state via the
    existing events; the composer renders after the replies; original + replies show a timestamp.
11. Run `./bin/dev gallery-walk` and compare the conversation screenshot to
    `design-system/wireframes/member-conversation.html`.
12. Run `dev check` and confirm it is green (no feature-file changes).

## Open Technical Decisions

None open. **Timestamp source: decided —** each conversation entry already carries the full message
struct, and the `messaging_messages` projection has `timestamps(type: :utc_datetime_usec)`, so
`@entry.message.inserted_at` is available directly; no presentation or projection change is needed,
only a display-format helper. **Follow control: decided —** a compact toggle wired to the existing
`follow_conversation` / `unfollow_conversation` events (no new events or server state).

## New Capability

The conversation page reads replies-first with a lightweight follow toggle and message timestamps —
matching the refreshed app-like design.

## Validation Plan

- **Automated:** LiveView tests (toggle, ordering, timestamps); `dev check` green.
- **Visual:** `./bin/dev gallery-walk`; compare the conversation screenshot to
  `member-conversation.html`.
- **Manual:** follow/unfollow via the toggle; post a reply; confirm replies-first order + timestamps.

## Risks / Follow-ups

- Depends on **044** (shell) and follows **045** (tabs) in the delivery order.
- **047** relocates delivery to the ⋮ → Delivery details page and removes the inline delivery
  sections this slice leaves in place.
