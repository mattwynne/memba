# Admins create usable custom groups

Date: 2026-09-13
Status: implementing

Stakeholder review complete; Fabro plan validation pending.

## Goal

A club admin creates a named group, becomes its first member, and immediately uses it for private web and email conversations.

## Background / Context

Depends on [061](../061-discover-club-groups/plan.md). Existing Membership `Club` state already owns groups, separate `GroupEmailSlugAssigned` events, group memberships and club membership/roles. Existing Messaging and web routes are group-aware. Extend these foundations, not a new group service or event store.

The reviewed creation design now has live name validation and a live generated email preview. This is a suggestion before creation, not a reservation. Name and email slug remain separate stored properties.

## Related Problems

- [Custom groups need renaming](../../problems/2026-09-12-custom-groups-cannot-be-renamed.md): leaves unresolved; separate name/slug identity avoids blocking that later work.
- [Retired groups need archiving](../../problems/2026-09-12-retired-custom-groups-need-archiving.md): leaves unresolved; empty groups are not archived.
- [CQRS/event-sourcing drift](../../problems/2026-06-17-cqrs-event-sourcing-design-drift.md): relevant constraint, not a general cleanup. Authoritative uniqueness and creation belong in the existing Club consistency boundary, not projection-only preflights.
- [Sender receives own group email](../../problems/2026-09-03-sender-receives-own-group-email.md): intentionally unresolved. Preserve existing sender-copy/follower behaviour.

## Scope

### In scope

- Admin-only custom creation with creator membership and a stable generated email address.
- Club-unique names, case/outer-space insensitive; club-unique stored slugs with numeric collision suffixes.
- Live name feedback and generated-address preview using the same rules as authoritative creation.
- Existing private web composition, inbound new conversations, replies and recipient scoping for custom groups.
- Club-departure safety before custom groups ship: departure ends custom memberships and clears their follows; club rejoin restores neither.

### Out of scope

Adding anyone other than the creator (063), group leave/remove controls (064), welcome emails for additions (063), Request access (065), renaming, slug editing, archiving/deletion, public/self-join groups, custom email policies and bespoke technical-failure flows. Creator welcome notification is not introduced here; creation itself confirms membership.

## Iteration Type

Behaviour-facing. Rule: an active club admin can create a private, addressable group and becomes its first member. Identity validation and safe club departure are necessary to ship this capability.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

- `acceptance-tests/features/custom_group_creation.feature`: actor permission, creation/creator, name and slug uniqueness, separate identity, live validation/preview and creation races. Tag `@iteration-062`; domain examples carry `@todo-domain @todo-ui`, live-input examples `@not-domain @todo-ui`.
- `acceptance-tests/features/custom_group_conversations.feature`: existing website/email semantics proven for a named group; `@iteration-062 @todo-domain @todo-ui`.
- `acceptance-tests/features/custom_group_lifecycle.feature`: club-departure/rejoin safeguards tagged 062; later additions/removals remain separately tagged 063/064.

Matt reviewed the rules and HTML prototype during planning.

## Allowed acceptance feature changes

- The three exact files above: implement this slice's tagged examples and remove/narrow only their runner-debt tags. Preserve later iteration tags/debt and existing regression features. Low-level fixture setup may establish a named group with several members without exposing 063's user action.
- `acceptance-tests/features/member_message_deliverability.feature`: no scenario changes required. Keep its unknown-route fixture genuinely absent; existing Admin/Everyone posting and unknown-destination coverage must remain.

## Designs

- `design-system/templates/club-group-new.html`: name-only form, live domain validation/email preview, created states.
- `design-system/templates/club-groups.html` and `design-system/explorations/custom-groups-prototype.html`: generic joined group and compose flows.

Show New group only to admins. Live preview updates without losing focus/caret; untouched blank is neutral and an edited blank or duplicate has inline feedback. On creation, land on the ordinary Members list containing the creator. Omit Add member until 063; keep Conversations and its contextual New message action usable. No single-member promotional panel. All compose audience wording/count/address comes from the selected group, matching the deployed HEEx consolidation. Cloud sync is pending; reviewed local HTML is sufficient.

## Acceptance Criteria

- Only an active admin in the destination club can create a custom group; client-supplied actor/club identities cannot widen authority.
- Creation records name, stable slug and creator membership together, without a visible orphan group on partial completion.
- Trim names; compare case-insensitively within the club, including Everyone/Admin names. Reuse nonblank display-name semantics, not an ASCII-only display-name restriction.
- Generate an address-safe slug from the initial name, store it separately, and choose the first available numeric suffix from 2 if occupied. Existing system slugs are occupied too. The final slug stays within the existing 32-character limit, shortening the stem to fit a suffix. If no ASCII stem is produced, use `group` and normal suffixing. These technical defaults retain display-name freedom and the prototype's fallback.
- Live preview and validation use the same rules as creation. Recheck at the authoritative boundary: concurrent same-name attempts cannot both succeed; distinct names with a slug collision get different stored addresses. A stale preview never reserves an address or overwrites another group.
- Web messages target the selected group. Active club members may email a known group address to start a conversation without joining; this grants no read/follow/reply access. Existing follower-only reply rules remain.
- Loss of club membership records the end of all custom memberships; rejoining Everyone does not reactivate them. Clear follows for those private-group conversations before they could resume after re-add. No custom group is silently archived or deleted.

## Open Business Decisions

None known. The normalization/fallback/suffix details above are implementation defaults, not a new slug-editing feature. Existing sender-copy behaviour is deliberately preserved.

## Implementation Plan

1. Add a thin authenticated Membership use case and actor-bearing custom-creation command, handled by the existing Club aggregate. Validate current active admin authority, same-club identity, group-name uniqueness and slug allocation inside that serialized boundary. Preserve trusted system/backfill command behaviour and historical events. Use a retry-stable group ID so retry does not silently become a second creation or change its address.
2. Emit the existing group-created, slug-assigned and creator-added facts as one successful decision. Extend aggregate state/projection constraints only as necessary for normalized name uniqueness; keep projections as projections. Make new user-facing operations distinguish custom groups structurally, not by arbitrary display-name checks.
3. Close the custom-membership departure gap now. Native `RemoveClubMember` currently emits only `ClubMemberRemoved`, and `SystemGroupMembership` removes only Everyone/Admin. Extend the Club-owned lifecycle to emit custom removals for the departing membership and keep legacy/replay handling safe. Arrange an idempotent Membership-to-Messaging policy for clearing affected follows, using public APIs and existing unfollow commands; do not put cross-context side effects in projectors. Ensure removal completion/rapid re-add cannot reactivate stale follows. Existing last-member/last-Admin invariants stay intact.
4. Add the new-group LiveView/form using shared inputs and route helpers. Use server-side live validation/preview, rechecking at submit, with accessible field associations. Reuse normal pending/success and generic technical-error treatment. Extend group queries/routing only where the existing generic paths need it.
5. Prove custom-group email routing and conversation authorisation using existing public Membership/Messaging APIs. Keep departure/rejoin safe at action and email-recipient/provider-handoff boundaries; never send private content to someone whose access has ended. Preserve already-handed-off email semantics; do not add an error dashboard or email retry product.
6. Implement the tagged scenarios and targeted Club concurrency, identity, replay, departure/rejoin, slug-length and LiveView typing tests. Run `dev check` on the exact delivery state.

## Open Technical Decisions

Use the existing `Membership.Slug` helper for base generation and validation without changing club-slug policy; a small custom-group allocator supplies fallback/suffixes. Use named commands/policies rather than growing anonymous orchestration in `membership.ex`. No new foundational architecture is needed. Final policy module names can follow existing project conventions; ordering, replay idempotency and privacy must be tested, not left implicit.

## New Capability

An admin can make Board a real conversation audience with a permanent email identity, using existing group messaging immediately.

## Validation Plan

- Parse tagged scenarios while planning; keep pending behaviour excluded in each runner.
- Aggregate tests: concurrent names/slugs, protected system identities, actor authorization, atomic creator membership and replay parity.
- LiveView/browser: type, clear, correct a duplicate, preserve caret, preview a collision, submit and compare the actual address.
- Domain/browser: web/email group audience and no access gained from non-member email posting; preserve current replies/recipient regressions.
- Lifecycle tests: club departure/rejoin never restores groups/follows, including rapid transitions and an already-open view.
- Full `dev check` on the exact committed/staged delivery state.

## Risks / Follow-ups

Do not broaden discovery APIs into participation APIs. Do not rely on a projection uniqueness preview as the final guarantee. Do not copy the prototype's client-side authorization as production security. The follow-clearing policy crosses contexts and must be replay-safe and ordered; its use for explicit group removal is extended in 064. Unrelated CQRS cleanup, sender-copy suppression and archive/rename work remain deferred.
