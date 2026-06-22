# Problems

## The replies feature diverges from its designs, and the conversations overview has no replies-aware design

Observed: 2026-06-22

Status: Unresolved. Target designs now exist (see "Designs produced" below); the app changes to close the gaps are not yet done.

Surfaced while extending the gallery-walk collector to cover the replies feature (iterations 039–041) and comparing the captured actuals against the design wireframes. The full surface-by-surface comparison is in [`docs/replies-wireframe-gaps.md`](../replies-wireframe-gaps.md). Seeding a real reply thread into the dev data made the gaps visible in screenshots.

The clearest problem: the **club-home overview lists each reply as its own top-level message row**. Seeding two replies to "Saturday ridge walk" produced three separate "Saturday ridge walk" rows (the original plus one per reply), each with its own sender and delivery bar. There is no conversation grouping and no reply count, and — unlike the other surfaces — there was no wireframe to build against, because the only club-home overview design predates conversations.

The conversation detail page and the reply-by-email surfaces also diverge from the designs that do exist:

- Conversation page: follow control is a button (design: a toggle); delivery receipts fill a large panel (design: one collapsed line); the composer sits above the replies (design: below); there is no "Replies · N" header; replies have no timestamps and the original has no sent date.
- Reply-composer states (posted confirmation, blank-reply validation error) were never wireframed.
- Stop-following page was never wireframed, and currently renders on the public marketing nav (Sign in / Request access), which is wrong for someone arriving from an email unsubscribe link.
- Reply-notification email: subject carries a `[club-slug]` prefix the design omits; the design comment still describes a conversation plus-address even though routing pivoted to email headers in iteration 041 (the annotation is stale, not the app).
- Inbound-rejection email: the `From` brands the club ("… via Memba"), but the design's deliberate dial is Memba-the-carrier (`Memba <post@memba.io>`) because a delivery failure comes from the carrier, not the club — even though the email body is already Memba-voiced. Its `Reply-To` also points at a personal dev address rather than a support address.

Designs produced (2026-06-22, local wireframes to be pushed to claude.ai/design via `/design-sync`):

- [`design-system/wireframes/member-conversation-overview.html`](../../design-system/wireframes/member-conversation-overview.html) — NEW: the club home as one row per conversation, activity-led, with a reply count and last-activity.
- [`design-system/wireframes/member-conversation.html`](../../design-system/wireframes/member-conversation.html) — local canonical target for the conversation page, plus the posted and validation-error composer states.
- [`design-system/wireframes/conversation-stop-following.html`](../../design-system/wireframes/conversation-stop-following.html) — NEW: the stop-following confirmation page (success + invalid-link), with a minimal Memba-mark header.
- Email gaps reference the existing `emails/reply-notification.html` and `emails/inbound-rejection.html` cloud designs; the reply-notification routing annotation should be corrected there.

Expected:

- The overview groups a conversation into a single row with a reply count and last activity, instead of leaking each reply as a separate message.
- The conversation page matches the conversation wireframe: toggle follow control, demoted/collapsed delivery, composer below the replies, a "Replies · N" header, per-reply timestamps, and a sent date on the original.
- Reply-composer posted and validation-error states match the new wireframe.
- The stop-following page uses the minimal Memba-mark header, not the marketing nav.
- The reply-notification subject drops the `[club-slug]` prefix and the design's routing note is corrected to header-based threading.
- The inbound-rejection email speaks as Memba-the-carrier in its `From`, and replies route to a support address.
