# 044 — Conversation page: align to the conversation wireframe

Date: 2026-06-22
Status: draft

## Goal

Bring the member message-detail page (`MemberMessageLive.Show` / `PageHTML.message`) in
line with its design, `wireframes/member-conversation.html` — adopting the toggle follow
control, a demoted/collapsed delivery summary, the composer below the replies, a
"Replies · N" header, per-reply timestamps, and a sent date — while keeping the app's
richer card treatment where it is better than the wireframe (and updating the wireframe to
match those).

## Background / Context

Comparing the live conversation page against `wireframes/member-conversation.html` (see
`docs/replies-wireframe-gaps.md`, bucket B) found several divergences. Some are the app
lagging the design (follow control, delivery prominence, composer placement, missing
counts/timestamps/date); others are the app being *richer* than the design (the boxed
original-message card, the composer's "Replying as" affordance), which we keep and fix in
the design instead.

## Related Problems

- [`docs/problems/2026-06-22-replies-feature-design-gaps.md`](../../problems/2026-06-22-replies-feature-design-gaps.md)
  — **partially addressed.** Resolves bucket B (conversation-page alignment). Leaves
  unresolved C (email From/subject) and D (stop-following page header).
- [`docs/problems/2026-06-22-conversation-page-design-barer-than-app.md`](../../problems/2026-06-22-conversation-page-design-barer-than-app.md)
  — **addressed by the fast-follow design update** in this iteration: the wireframe was
  barer than the app for the composer and the original/reply cards; the design is updated
  to keep the app's richer treatment.

## Scope

### In scope

The member conversation/message-detail page only:
- Follow control: replace the button card with a **toggle switch** (same follow/unfollow behaviour).
- Delivery: **collapse** the "Message delivery" summary + "Members by delivery status"
  detail into a single summary line, **expandable** to today's full detail. Collapsed by default.
- Reply composer: move it **below** the reply list; keep the "Replying as \<name\>" pill,
  drop the verbose helper sentence ("best of both").
- Add a **"Replies · N"** header above the replies.
- Add a **timestamp** to each reply.
- Add the **sent date** to the original-message meta line.

### Out of scope

- The conversations overview (iteration 043), the staff/admin views, email surfaces (C),
  and the stop-following page (D).
- Any change to follow/reply/delivery **behaviour** — this is presentation only.
- Permission gating of delivery detail (everyone who can see the page keeps current access).

### Kept as-is (app is richer; design updated instead)

- The boxed **original-message card** (avatar + "Club message/Original" treatment).
- The **reply cards** (consistent with the original card).
- The composer's "Replying as \<name\>" affordance.

## Iteration Type

Behaviour-facing surface, but **presentational alignment** — no new user-observable rule.
The follow toggle drives the same follow/unfollow commands; the delivery collapse is a UI
disclosure; counts/timestamps/date are display. Comparable to iterations 034/036/037.

## Acceptance Scenarios / Feature Files

BDD decision: **Not useful for this slice.** The follow and reply behaviours are already
covered by `acceptance-tests/features/club_message_replies.feature` (iterations 039–041),
and this slice changes how that behaviour is *presented*, not the rules. No Gherkin is
added or changed. Validation is by LiveView/component tests and a gallery-walk screenshot
(see Validation Plan).

## Designs

- Target design exists and is synced: `wireframes/member-conversation.html` (it already
  shows the toggle, collapsed delivery, composer-below, "Replies · N", timestamps, sent date).
- **Fast-follow design update** required so the design keeps the app's richer treatment:
  render the original message and replies as **cards** (not inline rows) and give the
  composer the **"Replying as \<name\>"** affordance. Mock + render-verify headless + push
  via `DesignSync` (Claude Code). This closes the "design barer than app" problem note.

## Acceptance Criteria

- The follow control is a toggle that reflects and changes follow state (on = following).
- The delivery section is collapsed to a one-line summary by default and can be expanded
  to the existing members-by-delivery-status detail.
- The reply composer appears **after** the reply list and shows "Replying as \<name\>".
- When there is at least one reply, a "Replies · N" header appears above the reply list
  (N = reply count). When there are no replies, the header **and** the reply list are
  omitted entirely — only the original message, follow control, and composer show.
- Each reply shows its posted timestamp.
- The original-message meta shows the sent date.
- The original message and replies remain boxed cards.

## Open Business Decisions

None known.

## Implementation Plan

1. `PageHTML.message` (`message.html.heex`):
   - Replace `#member-conversation-follow-control`'s button(s) with a daisyUI toggle bound
     to `follow_conversation` / `unfollow_conversation` (drive the existing events from the
     toggle's change), preserving `data-following` / `data-can-follow`.
   - Wrap `#member-receipt-summary` + `#member-receipts-section` in a disclosure that is
     collapsed by default, with a one-line summary header and an expand control; keep the
     existing expanded markup as the revealed detail.
   - Move `#member-message-reply-composer` to render after `#member-conversation-replies`;
     remove the helper sentence, keep the "Replying as" pill.
   - Add a "Replies · N" heading above `#member-conversation-replies`.
   - Add a timestamp to each `conversation_entry_card` reply.
   - Add the sent date to `#member-message-meta`.
2. `MemberMessageLive.Show` / `MemberMessageDetail`: supply a reply count, per-reply
   timestamps, and the original sent date to the template if not already available. The
   delivery disclosure is **server-driven**: add a `delivery_expanded?` assign (default
   `false`) and a `toggle_delivery` `phx-click` event, consistent with the existing
   `toggle_receipt_group` pattern. The collapsed summary reuses the existing member
   delivery summary copy; timestamps/date use the app's existing formatting helpers.
3. When the reply count is zero, render neither the "Replies · N" header nor the reply
   list — only the original message, follow control, and composer.
4. No changes to commands, projections, or follow/reply behaviour.

## Open Technical Decisions

None known. (The delivery disclosure is server-driven, per Implementation Plan step 2.)

## New Capability

The conversation page reads as a conversation: a clear follow toggle, the thread front and
centre with reply counts and times, the composer at the end, and delivery tucked away until
asked for — instead of delivery receipts dominating the page.

## Validation Plan

- LiveView/component tests for `MemberMessageLive.Show` asserting: the follow toggle is
  present and reflects/toggles state; the delivery detail is collapsed by default and
  expands (and collapses again) via the server-driven toggle; the composer renders after
  the replies and shows "Replying as"; a "Replies · N" header with the right count when
  replies exist; the header and list are omitted when there are none; per-reply timestamps;
  the sent date on the original.
- Existing `club_message_replies.feature` scenarios stay green (behaviour unchanged).
- A `bin/dev gallery-walk` screenshot of the member message-detail confirming the new layout.

## Risks / Follow-ups

- The delivery disclosure must keep the existing receipt detail reachable (collapsed, not
  removed) so managers can still inspect delivery.
- Buckets C (emails) and D (stop-following) remain in the gaps problem note.
- The fast-follow design update must land so the design system stops disagreeing with the app.
