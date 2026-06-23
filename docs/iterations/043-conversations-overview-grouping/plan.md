# 043 — Conversations overview: group replies with a reply count

Date: 2026-06-22
Status: draft

## Goal

On the member club home, each conversation appears as **one row** with a **reply
count**, instead of every reply showing up as its own top-level "message." After
this iteration, replies stop masquerading as new club-wide messages in the list.

## Background / Context

The reply feature (iterations 039–041) lets members reply to a club message; a reply
is a `MessageProjection` row whose `conversation_id` points at the root message.
`Messaging.list_messages_for_club/1` returns **all** messages — roots and replies —
and `MembaWeb.MemberDashboardPresentation` renders them one-per-row, so each reply
surfaces as a separate "Saturday ridge walk" entry with its own delivery bar. This
was made visible while extending the gallery-walk collector to cover replies.

## Related Problems

- [`docs/problems/2026-06-22-replies-feature-design-gaps.md`](../../problems/2026-06-22-replies-feature-design-gaps.md)
  — **partially addressed.** This iteration resolves the overview gaps (A1 replies
  leaking as separate rows, A2 missing reply count, A3 missing replies-aware design).
  It deliberately **leaves unresolved**: B (conversation-page alignment), C (email
  From/subject), D (stop-following page header). Those remain tracked in that note for
  future iterations. Full comparison: [`docs/replies-wireframe-gaps.md`](../../replies-wireframe-gaps.md).
- [`docs/problems/2026-06-22-no-conversation-unread-activity-indication.md`](../../problems/2026-06-22-no-conversation-unread-activity-indication.md)
  — **left unresolved / depends on out-of-scope read-state.** Captured during this
  planning when we deferred "new/unread activity" emphasis as scope creep.

## Scope

### In scope

- The member club-home "Recent club messages" list only (`PageHTML.club` via
  `MemberDashboardPresentation`).
- One row per conversation (the root message). Replies fold into their conversation.
- A reply count = number of replies in the conversation (both in-app and email replies).
- "latest from \<name\>" naming the most recent replier; "No replies yet" when there are none.
- Ordering by **original send time, newest first**; a new reply does **not** reorder.
- Row avatar and date reflect the **original** (originator + original send date).

### Out of scope

- The staff/admin messages list.
- The conversation-detail page, email surfaces, and the stop-following page (buckets B/C/D).
- Any per-member read state or unread/new-activity emphasis.
- The home **delivery glance** — it is being **removed** from the home (see Acceptance);
  delivery detail stays on the conversation page.

## Iteration Type

Behaviour-facing. New user-observable rule: on the club home, replies are grouped
under their conversation and a conversation shows its reply count, rather than each
reply appearing as a separate message.

## Acceptance Scenarios / Feature Files

BDD decision: **Required.** Add a Rule to
`acceptance-tests/features/club_message_replies.feature` (stays `@not-ui` — these
assert the read-model "recent conversations" the home would show, no browser driving).
Tag the new Rule `@iteration-043 @todo-domain` (the project's "domain scenario not yet
implemented" tag, excluded from the domain Cucumber run until implementation lands; the
feature is already `@not-ui`, so it is excluded from the UI run too).

Scenarios (domain language):
- A message with two replies appears as one conversation entry showing **2 replies**,
  with the latest reply from the most recent replier.
- A message with no replies shows **no replies yet**.
- Conversations are ordered by original send time, newest first — a newer reply to an
  older conversation does not move it above a newer original.

### Allowed acceptance feature changes

- `acceptance-tests/features/club_message_replies.feature` — **add** one Rule and its
  scenarios, tagged `@iteration-043 @todo-domain`. No existing scenarios change. Coverage
  is strictly added; `@todo-domain` keeps them out of the domain Cucumber run until implemented.

## Designs

- Base design exists and is synced: `wireframes/member-conversation-overview.html`
  (claude.ai/design + local mirror).
- **Fast-follow design tweaks** required to match the decisions above: make the row
  **origin-led** (avatar = originator, date = original send date) and **remove the
  delivery glance** from the rows. Mock + render-verify headless + push to the DS via
  `DesignSync` (Claude Code). No other surface changes.

## Acceptance Criteria

- The club home lists one row per conversation; a conversation's replies never appear
  as separate rows.
- Each row shows the conversation subject, "Started by \<originator\>", and either
  "\<N\> replies · latest from \<name\>" or "No replies yet".
- Rows are ordered by original send time, newest first; posting a reply does not change
  a conversation's position.
- The row avatar is the originator's; the row date is the original send date.
- The home no longer renders a delivery glance on conversation rows.
- The reply count includes both in-app replies and email replies.

## Open Business Decisions

None known.

## Implementation Plan

1. Add `Messaging.list_conversations_for_club/1`: a read-model query over
   `MessageProjection` that returns one entry per conversation (root message), each with
   `reply_count` and the latest replier (id/name), ordered by the root's `inserted_at`
   descending (secondary `message_id`). Group by `conversation_id`; the root is the row
   where `message_id == conversation_id`; replies are the rest.
2. Update `MemberDashboardPresentation` to build its message rows from
   `list_conversations_for_club/1` instead of `list_messages_for_club/1`: subject,
   originator name + initials, reply count, latest-replier name, original send date.
   Drop the receipt-glance fields from the home row.
3. Update `PageHTML.club` (`club.html.heex`) `#member-message-list` markup to the
   conversation row: originator avatar, subject, "Started by …", the reply-activity
   line, original send date. Remove the delivery glance markup.
4. Keep the row link target unchanged (the conversation/message-detail route).

## Open Technical Decisions

- Exact shape of the latest-replier lookup in the group-by (window function vs. a second
  query keyed by conversation). Either is acceptable; prefer one query if clean.

## New Capability

The club home reflects **conversations**, not raw messages: members see how active a
thread is at a glance and replies no longer clutter the list as fake new messages.

## Validation Plan

- The new `@todo-domain` read-model Cucumber scenarios in `club_message_replies.feature`
  go green (and the tag is removed) once implemented.
- An ExUnit test for `MemberDashboardPresentation` covering: grouping, reply count,
  latest replier, ordering, and the absence of receipt-glance fields.
- A `bin/dev gallery-walk` screenshot confirming the "Saturday ridge walk" conversation
  renders as a single row with its reply count on the member club home.

## Risks / Follow-ups

- Removing the home delivery glance means managers check send health on the conversation
  page; acceptable and consistent with demoting delivery.
- Buckets B (conversation page), C (emails), D (stop-following) remain in the gaps
  problem note for future iterations.
- New/unread-activity emphasis is captured as its own problem note (needs per-member read
  state) and is intentionally not part of this slice.
