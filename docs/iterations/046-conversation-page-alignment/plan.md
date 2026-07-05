# 046 — Conversation page: follow toggle, replies-first, message timestamps

Date: 2026-07-04
Status: draft

> Draft — to be finalised and validated when its turn comes (after 044 shell + 045 tabs). Written
> against the 2026-07-04 refreshed `member-conversation.html`. Repurposes the 046 slot (previously
> a duplicate club-home-tabs draft, now superseded by 045).

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

**BDD decision: Not useful for this slice (tentative).** No new rule; follow/reply behaviour is
unchanged and covered by existing conversation/replies scenarios. To confirm when finalised.

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

_To be finalised when this slice is shaped for delivery (after 044 + 045). Sketch:_

1. Replace the `#member-conversation-follow-control` card + Follow/Stop buttons with a compact
   follow **toggle** beside the subject, wired to the existing follow/unfollow events and gating.
2. Move the `#member-message-reply-composer` block to render **after** the replies list, keeping
   "Replying as" and the posted / validation-error states.
3. Add a `Replies` count/heading only if the design keeps one (the refreshed design does not — omit).
4. Expose the original-message and per-reply **timestamp** in the conversation-entry presentation
   (`member_message_detail.ex`) if not already, format it, and render it in each message card head.
5. Apply the boxed message-card markup/classes to the original and reply cards per the design.
6. Update LiveView tests for the toggle, composer-below-replies order, and timestamps.
7. Run `./bin/dev gallery-walk`; compare to `member-conversation.html`. Run `dev check`.

## Open Technical Decisions

- **Timestamp source:** confirm the conversation-entry presentation exposes a message time; if not,
  add it from the message projection and format it for display.

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
