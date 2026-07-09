# 051 — Club home: conversation participant avatar-stack

Date: 2026-07-09

Status: merged

## Goal

Club-home conversation rows show who else is in the conversation — an avatar-stack of distinct
participants, capped with a "+N" overflow — matching `design-system/wireframes/club-home.html`.
This is the half of gap #1 from the [2026-07-09 design gap pass](../../design-gaps-2026-07-09.md)
that iteration 050 didn't take, because it needs a new query rather than a template change.

## Background / Context

The 2026-07-09 gap pass found club-home conversation rows missing two things versus the design:
a message preview (closed by iteration 050) and a participant avatar-stack (this iteration).
Matt asked for this to be built next.

Closing this properly also means finally porting the design system's `.conversation__participants`
and `.avatar-stack` classes into `app.css` — they don't exist there today (see
[`docs/code-health.md`](../../code-health.md), 2026-07-09 entry, and gap #5 in the analysis doc).
The avatar-stack has no other natural home to render into, so this iteration closes that specific
slice of the class-reuse gap as a side effect, without attempting the rest of it (the conversation
page's `.message*`/`.composer*`/`.page-title` classes remain untouched).

## Related Problems

- [`docs/design-gaps-2026-07-09.md`](../../design-gaps-2026-07-09.md) — gap #1 (avatar-stack half)
  and gap #5 (CSS-class reuse, `.conversation__participants`/`.avatar-stack` slice only).

## Scope

### In scope

- A new `Messaging` query returning the distinct repliers of a conversation (excluding the root
  sender, who already has the row's big avatar), ordered by first reply, for use alongside the
  existing reply-count/latest-replier data already loaded by `conversations_for_club_query/1`.
- Club-home conversation rows render an avatar-stack of participants (excluding the row's own
  large originator avatar, matching the design: the big avatar is the originator, the stack is
  everyone else), capped to the first 3 with a "+N" overflow badge for the rest, reusing the
  existing `<.avatar>` component's deterministic initials/color scheme.
- Port the row-relevant `.conversation`, `.conversation__*`, and `.avatar-stack` classes from the
  design system into `app.css`, and rewrite the club-home conversation row template to use them
  instead of the current ad hoc Tailwind classes (this also closes the preview-text/heading work
  from iteration 050 onto the "real" shared classes rather than leaving it on bespoke Tailwind).
- Update the shared acceptance feature file(s) used for the club-home conversation rows.

### Out of scope

- `.message*`/`.composer*`/`.page-title` classes for the conversation/message detail page — a
  separate slice of gap #5, not touched here.
- Any change to reply counts, latest-replier labels, or conversation grouping logic.
- The club "About" tab and member-since dates — tracked separately as
  [problems](../../problems/README.md), not scheduled.

## Iteration Type

**Behaviour-facing.** Adds a new observable element (the avatar-stack) to an existing club-home
row.

## Decisions (made 2026-07-09)

Matt answered all three open questions from the draft, confirming the recommended defaults:

1. **Participants are distinct repliers, excluding the original sender** (who already has the
   row's big avatar), **ordered by first reply.** Order is stable and doesn't reshuffle the row's
   avatar order as new replies arrive.
2. **"+N" counts distinct additional participants, not additional replies.** A 2-person
   back-and-forth thread shows 0 extra avatars regardless of reply count — the existing
   reply-count label already covers volume.
3. **Cap is 3** visible avatars before the "+N" overflow badge, matching the design mockup.

## Designs

**Design of record:** [`design-system/wireframes/club-home.html`](../../../design-system/wireframes/club-home.html)
— Conversations panel, `.conversation__participants`/`.avatar-stack` markup.

## Acceptance Criteria

- Each club-home conversation row shows an avatar-stack of distinct repliers (excluding the row's
  own originator avatar), ordered by first reply, de-duplicated when the same participant replies
  multiple times, capped to 3, with a "+N" overflow badge counting distinct additional
  participants when there are more than 3.
- A conversation with no replies shows no avatar-stack (nothing to add beyond the originator).
- `app.css` gains the row-relevant `.conversation`, `.conversation__*`, and `.avatar-stack`
  classes; `club.html.heex`'s conversation row uses them instead of the current Tailwind
  implementation.
- `dev check` passes; acceptance coverage added for the avatar-stack.

## Acceptance Scenarios / Feature Files

- Update `acceptance-tests/features/club_message_replies.feature`.
- Extend the existing rule `Rule: On the club home, each conversation is one entry with its reply count`
  with stakeholder-readable coverage for:
  - a conversation with no replies shows no participant avatar-stack;
  - 1–3 distinct repliers are shown in first-reply order;
  - the originator is excluded from the stack;
  - duplicate replies by the same participant are de-duplicated;
  - 4+ distinct repliers show the first 3 avatars plus a "+N" overflow badge counting the remaining
    distinct participants.

## Allowed acceptance feature changes

- `acceptance-tests/features/club_message_replies.feature`: implementation may add or update
  `@iteration-051` scenarios under `Rule: On the club home, each conversation is one entry with
  its reply count` for the avatar-stack coverage listed above (no replies → no stack; 1–3 distinct
  repliers in first-reply order; originator excluded; duplicate repliers de-duplicated; 4+ distinct
  repliers → first 3 avatars + "+N"). It must not retag, reorder, or otherwise modify any existing
  scenario, rule, or tag outside the new `@iteration-051` scenarios (in particular, no changes to
  the `@iteration-039`/`@iteration-040`/`@iteration-041`/`@not-ui`/`@iteration-050` tags already in
  this file) — this iteration adds one new capability to existing rows, it does not touch anything
  else in this feature file.
- Matching Cucumber step definitions/support files under the domain and browser acceptance test
  trees may be added or updated as needed to execute the new `@iteration-051` scenarios.

## Implementation Plan

1. Add a participants query (likely alongside `reply_counts_query`/`latest_replies_query` in
   `Messaging.conversations_for_club_query/1`): distinct `sender_id` per `conversation_id` across
   replies only (excluding the root sender), ordered by first reply time.
2. Thread participant data through `MemberDashboardPresentation.present_message_rows/2`, capping
   to the first 3 and computing the distinct-additional-participant count for the overflow badge.
3. Port the row-relevant `.conversation`/`.conversation__*`/`.avatar-stack` classes into `app.css`
   (mirroring `memba.css`'s definitions for those classes).
4. Rewrite the club-home conversation row in `club.html.heex` to use the ported classes,
   rendering the avatar-stack via the existing `<.avatar>` component for each participant plus an
   overflow badge.
5. Add/update acceptance and unit test coverage for participant ordering, the overflow count, and
   the no-replies-yet case.
6. Run `./bin/dev gallery-walk` and compare against `design-system/wireframes/club-home.html`.
7. Run `dev check` and confirm it is green.

## New Capability

Members can see at a glance who else is participating in a conversation from the club home,
without opening it.

## Validation Plan

- **Automated:** `Messaging` query tests for participant ordering/dedup/cap; presentation/LiveView
  tests for the rendered avatar-stack and overflow badge.
- **Visual:** `./bin/dev gallery-walk`; compare against `design-system/wireframes/club-home.html`.
- **Manual:** open the club home with a conversation that has 0, 1–3, and 4+ distinct repliers;
  confirm the stack and overflow badge render correctly at each count.

## Risks / Follow-ups

- This only closes the club-home-row slice of the CSS-class-reuse gap (`docs/code-health.md`,
  2026-07-09 entry). The conversation/message detail page's `.message*`/`.composer*`/`.page-title`
  classes remain unported — tracked there, not here.
