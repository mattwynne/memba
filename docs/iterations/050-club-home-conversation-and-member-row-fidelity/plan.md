# 050 — Club home conversation & member-list fidelity fixes

Date: 2026-07-09

Status: merged

## Goal

Close the highest-value, lowest-ambiguity gaps found by a design-vs-implementation gap pass
(`docs/design-gaps-2026-07-09.md`) across iterations 044–049: club-home conversation rows show a
message preview, a duplicate "Invite member" button is removed, and the conversation page drops
two elements, two headings, and shrinks an oversized headline to match the current design.

## Background / Context

Matt asked for a "close the loop" pass: run (and extend) the gallery walk, then do a detailed gap
analysis of the shipped app against `claude.ai/design`, and draft the next iteration. The plan was
first drafted with five open business decisions and left in **draft** status since Matt wasn't
available to review live. He then interviewed through all five; this version reflects his answers
(see Decisions below) and is **ready** for validation/implementation.

The gap pass (`docs/design-gaps-2026-07-09.md`) pulled designs directly from the cloud project
(not just the local mirror, though the mirror turned out to be byte-identical for every file
checked) and found six gaps. Two are structurally larger and stay out of this iteration: an
"About" tab with no backing data model, and a staff-console design that conflicts with itself
(two different checked-in staff-console files, needing a product decision on which is canonical
before any build work).

## Related Problems

- [`docs/design-gaps-2026-07-09.md`](../../design-gaps-2026-07-09.md) — the gap pass this
  iteration was scoped from. Gaps #1 (preview half only), #3, and #3a.

## Decisions (made 2026-07-09)

Matt answered all five open questions from the draft:

1. **Remove all four flagged UI elements to match the design exactly:** the ORIGINAL
   MESSAGE/REPLY badges, the duplicate "From {sender}" line, the "Recent club messages" heading,
   and the "Current members" heading.
2. **`membership.inserted_at` is not an acceptable "member since" date.** Real clubs will have
   migrated/imported membership history, so a trustworthy join date needs to handle import — that
   is a separate feature, not a one-line query change. **The member-row join-date item is pulled
   out of this iteration entirely** and moved to backlog (see Out of scope).
3. **Message preview uses CSS line-clamp**, not character-count truncation — render the full body
   text and let CSS clamp it to one line, so it stays correct across font/width changes.
4. **Sequencing after 050 is not decided yet** — revisit once this iteration ships.

## Scope

### In scope

- **Club-home conversation rows show a one-line message preview.** `message_row.body` is already
  present in `MemberDashboardPresentation.present_message_rows/2` — render it in `club.html.heex`'s
  conversation row and clamp it to one line with CSS (`-webkit-line-clamp` or equivalent), not by
  truncating the string server-side.
- **Drop the "ORIGINAL MESSAGE"/"REPLY" badge on conversation entries.** Remove
  `conversation_entry_label/1` and its rendering in `page_html.ex`'s `conversation_entry_card/1` —
  the current design differentiates the original message only by card tint/ring.
- **Drop the duplicate "From {sender}" line on the conversation page.** Remove the
  `#member-message-meta` paragraph in `message.html.heex` — sender name and time already appear
  once, on the original-message card itself.
- **Shrink the conversation subject from a hero headline to a normal page title.** Confirmed in
  the gallery screenshot (`app__member-message-read__desktop.png`) that
  `text-4xl`/`sm:text-5xl` (`message.html.heex:29-34`) renders every conversation subject at
  marketing-splash scale; the design's `.page-title` is a normal heading.
- **Remove the "Recent club messages" heading** above the Conversations panel list
  (`club.html.heex:84-87`) — the design has no heading there, going straight from the tab row into
  the list.
- **Remove the "Current members" heading** above the Members panel list
  (`club.html.heex:209-211`) — same reasoning.
- **Remove the duplicate "Invite member" button on the club-home Members tab.** Confirmed in
  `app__member-club-home-members-tab__desktop.png` — the tab-row action slot and the inline
  "Current members" section header both render an "Invite member" button at once
  (`club.html.heex:213-221` is the redundant one; the design has exactly one, in the tab-row
  slot). This button lives in the same header block being removed above — implementation should
  confirm nothing else in that header needs to survive (e.g. re-check whether any test relies on
  `#member-invite-member-link` before deleting it).
- Update the named acceptance feature files below for scenarios that assert on any of the removed
  elements, or on the added preview text.

### Out of scope

- **Member-row "member since {date}"** — pulled from this iteration per Decision #2 above. Needs
  its own iteration once there's a plan for import-aware join dates (see Risks/Follow-ups).
- The conversation participant avatar-stack (design gap #1's other half) — needs a new
  participants-aggregation query; not data-ready like the rest of this slice.
- Porting `.conversation*`/`.message*`/`.composer*`/`.page-title` design-system CSS classes into
  `app.css` (gap #5 in the analysis doc) — a real fix, but a refactor of the same templates this
  iteration touches; doing it here would blur a fidelity-content change with a CSS-architecture
  change. Candidate for the next iteration, but sequencing isn't decided (Decision #4).
- The club "About" tab (gap #4) — blocked on a product decision about where the copy comes from
  and who edits it.
- The staff-console rail IA (gap #6) — two checked-in designs disagree; needs a product decision
  on which is canonical before any build work.
- The identity-dropdown "Active member since" status line (gap #7) — low priority, not bundled.

## Iteration Type

**Behaviour-facing, presentation-only.** Nothing here changes what data is captured or what
members can do; it changes what's shown. Member-observable output changes (preview text, four
elements removed, one button removed, one heading resized), so this needs acceptance coverage,
not just unit tests.

## Designs

**Design of record:**
[`design-system/wireframes/club-home.html`](../../../design-system/wireframes/club-home.html) —
Conversations panel (preview text, `conversation__preview`) and Members panel structure (no
heading, single invite action).
[`design-system/wireframes/member-conversation.html`](../../../design-system/wireframes/member-conversation.html)
— confirms the current design has no per-entry kind badge and no separate sender/time line under
the title. Both pulled fresh from claude.ai/design on 2026-07-09 and confirmed byte-identical to
the checked-in mirror.

## Acceptance Criteria

- Club-home conversation rows show the message body, visually clamped to one line via CSS.
- Conversation entries (original message and replies) no longer render an "ORIGINAL MESSAGE" or
  "REPLY" badge.
- The conversation page no longer shows a separate "From {sender}" line under the title/follow
  row.
- The conversation subject renders at the normal `.page-title` scale, not as a
  hero/marketing-scale headline.
- The Conversations panel no longer shows a "Recent club messages" heading.
- The Members panel no longer shows a "Current members" heading.
- The club-home Members tab shows exactly one "Invite member" action (the tab-row slot), not two.
- `dev check` passes; any acceptance scenarios asserting on the removed elements are updated.

## Acceptance Scenarios / Feature Files

This is behaviour-facing presentation work, so update shared Cucumber coverage in the existing
feature areas rather than adding a new feature file.

- `acceptance-tests/features/club_message_replies.feature`
  - Under `Rule: On the club home, each conversation is one entry with its reply count`, update or
    add an `@iteration-050` scenario covering the club-home Conversations panel:
    - a conversation row shows preview text from the original message body;
    - the Conversations panel does not show the "Recent club messages" heading.
  - Add or update an `@iteration-050` conversation-page scenario covering the member-visible page
    presentation:
    - conversation entries do not show "ORIGINAL MESSAGE" or "REPLY" badges;
    - the page does not show a separate duplicate "From {sender}" line under the title/follow row.
- `acceptance-tests/features/list_members.feature`
  - Add or update an `@iteration-050` scenario for the club-home Members tab covering:
    - the Members panel does not show the "Current members" heading;
    - a member who can manage members sees exactly one visible "Invite member" action.

The exact heading scale (`.page-title` vs hero heading) should be validated by the targeted
Phoenix/LiveView test and gallery-walk comparison because Gherkin should not assert CSS class or
font-size implementation details.

## Allowed acceptance feature changes

- `acceptance-tests/features/club_message_replies.feature`: implementation may add or update
  `@iteration-050` scenarios under `Rule: On the club home, each conversation is one entry with
  its reply count` (conversation-row preview text, no "Recent club messages" heading) and may add
  or update one `@iteration-050` conversation-page scenario (no ORIGINAL MESSAGE/REPLY badges, no
  duplicate "From {sender}" line). It must not retag, reorder, or otherwise modify any existing
  scenario, rule, or tag outside the new `@iteration-050` scenarios (in particular, no changes to
  the existing `@iteration-039`/`@iteration-040`/`@iteration-041`/`@not-ui` tags on unrelated reply
  rules) — this iteration is a presentation-only slice, not a tagging cleanup.
- `acceptance-tests/features/list_members.feature`: implementation may add or update an
  `@iteration-050` scenario for the club-home Members tab (no "Current members" heading; exactly
  one visible "Invite member" action for a member who can manage members). It must not modify the
  existing `@iteration-049` role-badge scenarios or any other existing scenario/tag.
- Matching Cucumber step definitions/support files under the domain and browser acceptance test
  trees may be added or updated as needed to execute the new `@iteration-050` scenarios.

## Implementation Plan

1. Add a preview element to the club-home conversation row template using `message_row.body`,
   clamped to one line with CSS (no server-side character truncation).
2. Remove `conversation_entry_label/1` and its call site in `page_html.ex`.
3. Remove the `#member-message-meta` paragraph in `message.html.heex`.
4. Resize the conversation subject heading in `message.html.heex` to match `.page-title` scale.
5. Remove the "Recent club messages" heading block from the Conversations panel in
   `club.html.heex`.
6. Remove the "Current members" heading block (including the redundant inline "Invite member"
   button) from the Members panel in `club.html.heex`; confirm the tab-row "Invite member" action
   still covers the same permission check (`@current_member_can_manage_members?`).
7. Update/remove the named acceptance scenarios and any unit test assertions tied to the removed
   elements; add coverage for the new preview text.
8. Run `./bin/dev gallery-walk` and compare the club-home and conversation-page screenshots
   against `design-system/wireframes/club-home.html` and `member-conversation.html`.
9. Run `dev check` and confirm it is green.

## Open Technical Decisions

None known — this is a small, mechanical slice now that all business decisions are resolved.

## New Capability

No new workflow capability — this is a fidelity/polish iteration. The observable change is that
members see club-home conversation previews and conversation/member-list pages that match the
design of record more closely.

## Validation Plan

- **Automated:** updated acceptance scenarios in
  `acceptance-tests/features/club_message_replies.feature` and
  `acceptance-tests/features/list_members.feature`; `page_html`/LiveView tests confirming the
  badge, meta line, and both headings are gone, and that the Members tab renders only one
  Invite-member action; a test confirming the conversation-row preview renders `message_row.body`.
- **Visual:** `./bin/dev gallery-walk`; compare the club-home Conversations/Members panels and the
  conversation page against the current `design-system/wireframes/` files.
- **Manual:** open the club home as a seeded member; confirm the preview clamps correctly for a
  long message body, and the Members tab shows only one Invite-member button for a member who can
  manage members.

## Risks / Follow-ups

- **Member-row join dates need their own iteration.** Any future work here should account for
  imported/migrated membership history from day one — likely a dedicated `joined_at` concept
  (populated by import tooling where relevant) rather than reusing `membership.inserted_at`, per
  Decision #2.
- `docs/design-gaps-2026-07-09.md` has the fuller backlog (avatar-stack, CSS-class port, About
  tab, staff-console IA) — this iteration deliberately does not attempt any of it, and sequencing
  after this iteration is not yet decided.
