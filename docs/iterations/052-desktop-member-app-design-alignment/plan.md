# 052 — Desktop member app design-system alignment

Date: 2026-07-09

Status: implementing

## Goal

Align the **desktop** member app pages as far as possible to the checked-in design-system
wireframes without adding new product behaviour, new permissions, new routing semantics,
notification changes, or data-model changes.

This is a presentation-only follow-on to the detailed gallery comparisons of the member message
show page and member club home. The design-system wireframes are the source of truth for this
slice.

## Background / Context

A close visual comparison of the gallery walk screenshots against the checked-in wireframes found
that the surfaces using shared design-system classes match closely, while surfaces still hand-rolled
with Tailwind drift repeatedly:

- `tmp/gallery/app__member-message-read__desktop.png` and
  `tmp/gallery/app__member-reply-posted__desktop.png` differ from
  `design-system/wireframes/member-conversation.html` in message-card spacing, composer treatment,
  footer chrome, copy, and class structure.
- `tmp/gallery/app__member-club-home__desktop.png` differs from
  `design-system/wireframes/club-home.html` by showing an extra `Prefer email?` card and, before
  iteration 051 lands, by missing the design-system conversation row/avatar-stack structure.
- The same comparison reaffirmed the 2026-07-09 code-health note: `.app-frame`, `.app-card`,
  `.app-bar*`, `.section-tab*`, `.member-row*`, `.detail-head*`, `.follow-toggle*`, and
  `.delivery-*` are already ported and align well; `.message*`, `.composer*`, and `.page-title`
  are not ported/used on the message detail page.

Matt resolved the remaining design-vs-app questions in favour of the wireframes:

1. Member app pages should show only the compact **Powered by Memba** footer; the full public
   footer is for marketing/legal/public pages.
2. The message detail back link should say **All conversations**.
3. The reply composer helper sentence should be removed.
4. `Replying as ...` should be lighter inline text near the composer title, not a right-aligned
   pill.
5. Posted success feedback should be a quiet wireframe-style composer note, not a prominent green
   alert.
6. The desktop club-home `Prefer email?` card should be removed to match the desktop wireframe.
7. All mobile versions are out of scope for now; Matt will do another design iteration on them.

Iteration 051 is already in progress and owns the club-home participant avatar-stack plus the
club-home `.conversation*` / `.avatar-stack` class port. This iteration must not duplicate that
work; it should either build on 051 after it lands or explicitly avoid the overlapping files/lines.

## Related Problems

- [`docs/code-health.md`](../../code-health.md), 2026-07-09 entry — **partially addresses** the
  design-system CSS reuse gap by taking the message-detail slice (`.message*`, `.composer*`,
  `.page-title`). The club-home `.conversation*` / `.avatar-stack` slice belongs to iteration 051.
- [`docs/design-gaps-2026-07-09.md`](../../design-gaps-2026-07-09.md) — **partially addresses**
  gap #5 and the remaining desktop presentation-only gaps around the member message page and club
  home. It deliberately leaves the About tab, member-since dates, staff-console IA, and mobile
  designs unresolved.
- [`docs/problems/2026-06-22-replies-feature-design-gaps.md`](../../problems/2026-06-22-replies-feature-design-gaps.md)
  — **further addresses** the conversation/message-detail design drift, using the current checked-in
  `member-conversation.html` wireframe as the target.
- [`docs/problems/2026-06-22-conversation-page-design-barer-than-app.md`](../../problems/2026-06-22-conversation-page-design-barer-than-app.md)
  — **superseded for this slice by Matt's 2026-07-09 decisions**. Earlier we had considered keeping
  some richer app treatment; Matt has now confirmed the wireframes are right for the five questioned
  areas in this iteration.
- [`docs/problems/2026-07-09-club-about-tab-missing.md`](../../problems/2026-07-09-club-about-tab-missing.md)
  — **intentionally left unresolved** because adding the About tab needs description data/source and
  editing-permission decisions, which are outside this no-new-behaviour slice.

## Scope

### In scope

#### Message/conversation detail — desktop presentation

Use [`design-system/wireframes/member-conversation.html`](../../../design-system/wireframes/member-conversation.html)
as the source of truth.

- Port the message-detail design-system classes from the design CSS into `web/assets/css/app.css`,
  following the same exact-name pattern already used for `.app-frame`, `.member-row*`,
  `.follow-toggle*`, and `.delivery-*`:
  - `.message`, `.message--original`, `.message__avatar`, `.message__body`, `.message__head`,
    `.message__name`, `.message__time`, `.message__text`, `.message__menu`, `.message__kebab`,
    `.message-menu`
  - `.composer`, `.composer__head`, `.composer__title`, `.composer__as`, `.composer__actions`,
    `.composer__note`, `.composer__error`
  - `.page-title`
- Rewrite the message detail template/component markup to use those semantic classes instead of
  the current bespoke Tailwind-heavy message-card and composer structure.
- Change the message detail back link copy from `Club home` to `All conversations`.
- Remove the reply composer helper sentence (`Your reply inherits the subject and is emailed to
  current followers except you.`).
- Render `Replying as <name>` as lighter inline composer text near the composer title, matching the
  wireframe, not as a right-aligned pill.
- Render posted success feedback as quiet composer note copy (`Your reply is being sent.`), not as a
  prominent full-width green alert.
- Tighten message-card/composer spacing and body alignment to match the wireframe: no large vertical
  dead space, no over-indented message text, no oversized composer panel treatment.
- Keep existing behaviour intact: same replies, same timestamps, same kebab delivery-details menu,
  same follow/unfollow semantics, same post-reply form behaviour.

#### Desktop club home — presentation-only remainder

Use [`design-system/wireframes/club-home.html`](../../../design-system/wireframes/club-home.html) as
the source of truth for desktop only.

- Remove the separate desktop `Prefer email?` card from the club-home Conversations panel.
- Do not duplicate iteration 051's participant avatar-stack work or the `.conversation*` /
  `.avatar-stack` class port. If 051 has landed, preserve/build on it; if 051 is still in flight,
  avoid conflicting changes and leave any overlap for rebase/coordination.

#### Member app shell/footer policy

- Member-authenticated app pages should render only the compact `Powered by Memba` app footer.
- The full public footer with copyright/About/Terms/Privacy/Contact/commit hash remains for
  marketing/legal/public pages and should not appear below authenticated member app cards.
- Apply this at the shared layout/component level if practical so message detail and club home both
  follow the same policy.

### Out of scope

- **All mobile design alignment.** Do not align to `mobile-club-home.html` or
  `mobile-message-detail.html` in this iteration. Matt will do another design iteration on mobile.
- Mobile new-message form changes; Matt says the current new-message mobile design is correct.
- The club-home **About** tab. It needs club description data, source/editing decisions, and likely
  routing/panel decisions.
- Member-since dates. Existing timestamps are not trustworthy for imported/migrated clubs.
- Iteration 051's participant avatar-stack implementation and club-home `.conversation*` /
  `.avatar-stack` class port.
- New permissions, routing rules, notification rules, data-model changes, database migrations,
  commands/events/projections, or new email behaviour.
- Staff/admin design alignment.

## Iteration Type

**Behaviour-facing, presentation-only.** Members will see different copy/layout/chrome on existing
pages, but no member gains or loses a capability and no persisted business state or notification
rule changes.

## Acceptance Scenarios / Feature Files

**Useful but limited.** This is member-visible, so a small number of stakeholder-readable scenarios
should lock down the user-facing decisions. CSS class names, exact spacing, and pixel-level visual
alignment should be validated by Phoenix tests and the detailed gallery-walk comparison rather than
Gherkin.

Update existing coverage rather than adding a new feature file:

- `acceptance-tests/features/club_message_replies.feature`
  - Add or update an `@iteration-052` message-detail scenario covering:
    - the back link reads `All conversations`;
    - the reply composer does not show the helper sentence;
    - the reply composer still identifies who the member is replying as;
    - after posting, the member still sees `Your reply is being sent.`;
    - conversation entries still show sender, timestamp, and body after the class refactor.
  - Add or update an `@iteration-052` club-home scenario covering:
    - the desktop Conversations panel no longer shows the `Prefer email?` card/copy.

Do not add Gherkin for the full-footer policy unless there is already a natural browser scenario;
prefer rendered layout tests because the footer is application chrome, not a conversation rule.

## Allowed acceptance feature changes

- `acceptance-tests/features/club_message_replies.feature`: implementation may add or update
  `@iteration-052` scenarios for the message-detail and club-home presentation points listed above.
  It must not retag, reorder, or otherwise modify unrelated existing scenarios/rules/tags outside
  the new `@iteration-052` coverage.
- Matching Cucumber step definitions/support files under the domain and browser acceptance test
  trees may be added or updated as needed to execute the new `@iteration-052` scenarios.

## Designs

DesignSync is not available in this Pi session. Existing checked-in design sources are sufficient
because this iteration aligns to already-checked-in desktop wireframes and does not require new
visible states.

Designs of record:

- [`design-system/wireframes/member-conversation.html`](../../../design-system/wireframes/member-conversation.html)
  — desktop member message/conversation detail, message card classes, composer classes, back-link
  wording, compact footer, posted/error composer states.
- [`design-system/wireframes/club-home.html`](../../../design-system/wireframes/club-home.html)
  — desktop club home. Use it to remove the extra `Prefer email?` card and preserve the design's
  compact footer. The participant avatar-stack part is owned by iteration 051.

Explicitly not designs of record for this iteration:

- `design-system/wireframes/mobile-club-home.html`
- `design-system/wireframes/mobile-message-detail.html`
- other mobile wireframes

Matt will revisit mobile designs separately.

## Acceptance Criteria

- Message detail uses the ported `.message*`, `.composer*`, and `.page-title` design-system classes
  for its message cards, composer, and title instead of bespoke Tailwind-heavy equivalents.
- Message detail back link reads `All conversations`.
- Message detail reply composer no longer renders the helper sentence.
- `Replying as <name>` appears as light inline composer text near the title, not as a separate
  right-aligned pill.
- Posted reply success feedback appears as quiet composer note text, not as a prominent green alert.
- Message card spacing/body alignment and composer scale visually match the desktop wireframe in
  the gallery comparison.
- Desktop club home no longer renders the `Prefer email?` card.
- Authenticated member app pages no longer render the full public footer below the compact
  `Powered by Memba` footer; marketing/legal/public pages retain the full footer.
- Existing member behaviours still work: following/unfollowing, opening delivery details from the
  kebab, posting a reply, viewing replies/timestamps, switching club-home tabs, and starting a new
  message.
- `dev check` passes.

## Open Business Decisions

None known. Matt confirmed that wireframes are right for the questioned areas, desktop `Prefer
email?` should go, and mobile is out of scope.

## Implementation Plan

1. Inspect the current design-system CSS definitions for `.message*`, `.composer*`, and
   `.page-title` and port them into `web/assets/css/app.css` using exact class names.
2. Rewrite the message detail HEEx/component markup to use the ported semantic classes while
   preserving IDs/test hooks and LiveView events needed by existing tests.
3. Apply the five message-detail decisions: `All conversations`, no helper sentence, inline
   `Replying as`, quiet posted note, compact member-app footer only.
4. Remove the desktop club-home `Prefer email?` card/copy.
5. Adjust shared member app layout/footer rendering so authenticated member app pages use only the
   compact app footer and public/marketing/legal pages keep the full public footer.
6. Add/update the allowed `@iteration-052` Cucumber scenarios and supporting step definitions if
   needed.
7. Add/update Phoenix/LiveView/rendered tests for:
   - ported class usage on message entries/composer/title;
   - absence of helper sentence and green success-alert styling;
   - `All conversations` back link;
   - no `Prefer email?` card on desktop club home;
   - no full public footer on member app pages while public pages retain it.
8. Run the detailed gallery-walk validation below, then `dev check`.

## Open Technical Decisions

- Coordinate with iteration 051 if it is still in flight. This plan should not overwrite or rework
  051's club-home conversation row/avatar-stack changes; rebase or sequence implementation after
  051 if necessary.

## New Capability

No new workflow capability. The new capability for the team is a more durable design-system class
bridge for the message-detail page, reducing future drift between the desktop wireframes and the
running member app.

## Validation Plan

### Automated

- Targeted Phoenix/LiveView/rendered tests for the message-detail template and shared member app
  layout.
- Updated `@iteration-052` acceptance scenarios in
  `acceptance-tests/features/club_message_replies.feature` for the user-facing copy/presence
  decisions.
- `dev check`.

### Detailed gallery-walk comparison

Run `./bin/dev gallery-walk` after implementation and compare the desktop gallery images against
the desktop wireframes in detail. The implementer/reviewer should record a short checklist in the
iteration notes or review context, not just say "looks close".

Compare:

- `tmp/gallery/app__member-message-read__desktop.png` →
  `design-system/wireframes/member-conversation.html`
- `tmp/gallery/app__member-reply-posted__desktop.png` →
  `design-system/wireframes/member-conversation.html` posted state
- `tmp/gallery/app__member-club-home__desktop.png` →
  `design-system/wireframes/club-home.html`
- `tmp/gallery/app__member-club-home-members-tab__desktop.png` →
  `design-system/wireframes/club-home.html` Members panel, mainly to catch footer/layout regressions

For the message detail screenshots, inspect at least:

- app card width, top-bar alignment, and compact footer only;
- back-link wording and placement;
- page-title scale vs the wireframe's normal page heading, not hero scale;
- follow toggle placement and scale;
- message-card border radius, border weight, shadow/subtle elevation, tint for the original, and
  vertical spacing between cards;
- avatar size/position, sender name weight, timestamp position, and kebab menu position;
- message body left alignment/indentation and vertical position — specifically confirm there is no
  large empty band between sender row and body text;
- composer panel background/border/padding and overall height;
- composer title/icon, inline `Replying as`, textarea height/placeholder, button size, and posted
  success note treatment;
- absence of the removed helper sentence and prominent green alert;
- absence of the full public footer/copyright/legal-link block.

For the club-home desktop screenshots, inspect at least:

- tab row/action slot alignment;
- conversation row density and structure after coordinating with iteration 051;
- absence of the `Prefer email?` card;
- compact member-app footer only, with no public footer below;
- no accidental changes to the Members panel layout or invite action.

Do **not** validate mobile screenshots against mobile wireframes in this iteration; mobile is
explicitly out of scope.

### Manual smoke

- Sign in as a seeded club member on desktop.
- Open the club home Conversations and Members tabs.
- Open a conversation, toggle follow/unfollow, open the kebab delivery-details link, and post a
  reply.
- Confirm all workflows still behave as before while the visible desktop surfaces match the
  wireframes more closely.

## Risks / Follow-ups

- If iteration 051 is not yet merged, overlapping club-home row changes may require sequencing or
  rebasing. Avoid duplicating the avatar-stack work.
- Mobile member app pages still diverge from the current checked-in mobile wireframes by design;
  Matt plans a separate mobile design iteration.
- The club-home About tab and member-since dates remain unresolved because they need product/data
  decisions.
- This closes only the message-detail part of the code-health CSS reuse gap. Future design work may
  still need more systematic visual regression coverage beyond gallery-walk review.
