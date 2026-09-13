# Discover club groups without joining them

Date: 2026-09-13
Status: implementing

Stakeholder review complete; Fabro plan validation pending.

## Goal

Every active club member can discover the club's groups without gaining access to their private conversations or membership lists.

## Background / Context

Iteration 058 lists only groups the member belongs to and treats other group links as not found. Matt has replaced that policy: names are visible throughout the club, while conversation access still requires group membership. Club admins may inspect group membership without joining, but receive neither conversation access nor group emails through their admin role.

This is the first of the agreed 061–065 slices. Use `a4dbf56e9` or later remote main, including the deployed HEEx consolidation at `03e0e2578`; the earlier design worktree's local-main base was stale. Iterations 098 and 099 are deferred, not dependencies.

## Related Problems

- [Simple, app-like member interface](../../problems/2026-06-23-interface-too-fancy-for-simple-app-use.md): partially addresses the navigation problem through the reviewed group rail and consistent tab actions; does not resolve the broader design-direction note.
- [Custom-group renaming](../../problems/2026-09-12-custom-groups-cannot-be-renamed.md) and [archiving retired groups](../../problems/2026-09-12-retired-custom-groups-need-archiving.md): deliberately deferred. Do not change their status during delivery.

## Scope

### In scope

- All-group discovery for active members of the selected club, including system-group names.
- Ordinary non-member access guidance and the club Admin email address, with no conversation content or membership list.
- Members-only, read-only membership inspection for a club admin outside a custom group; hide Conversations and New message.
- Preserve the member's selected group and the existing member-only conversation, compose, reply, follow and delivery-detail boundaries.
- Reflect permission changes in an already-open LiveView without relying on sign-out or refresh.

### Out of scope

Creation (062), adding people (063), removal/leave controls (064), and Request access (065). The approved temporary placeholder offers the Admin email address only; no inert request button. No open/self-join groups, public conversations, membership dates or bespoke technical-failure UI. Existing generic app errors remain unchanged.

## Iteration Type

Behaviour-facing. Rule: discovering a group does not confer participation or ordinary-member access to its membership list.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

Update `acceptance-tests/features/group_conversations.feature`: replace the two obsolete hidden-group/not-found examples, retain the existing member-scoping and composition regressions, and add ordinary/admin non-member boundaries, club isolation and remembered selection. Changed/new scenarios carry `@iteration-061 @todo-domain @todo-ui`, except browser-only tab/remembered-state examples use `@not-domain @todo-ui`. Preserve inherited `@iteration-058`.

Matt reviewed the rules and HTML prototype during planning; no further stakeholder review is needed before validation.

## Allowed acceptance feature changes

- `acceptance-tests/features/group_conversations.feature`: change only the named discovery/privacy expectations and add this slice's examples. Remove runner-debt tags only for scenarios the corresponding runner implements; retain all iteration tags and the unaffected 058 regressions. Later Request access assertions belong to 065, not this slice.

## Designs

Reviewed local HTML accompanies these plans:

- `design-system/templates/club-groups.html`: final rail and shared group frame.
- `design-system/templates/club-group-non-member.html`: regular non-member and outside-admin views.
- `design-system/explorations/custom-groups-prototype.html`: interactive final behaviour.

Omit creation, membership mutation and Request access controls until their slices. Regular non-members see the group name and Admin contact, not member counts, group email, conversation previews/activity or member names. Outside admins can see membership metadata. These are the reviewed prototype's presentation choices, not new public-reading grants.

Use `MemberDashboardGroupTabs.group_tabs/1` for the single active-tab action position; group headers contain metadata only. Reuse `Layouts.club_site`, `MemberComponents` rows and the current Canada/open-source footer. The local designs were browser-rendered; cloud DesignSync remains unsynchronised. Existing local sources are sufficient for implementation; do not invent a replacement design.

## Acceptance Criteria

- All active club members see all current-club group names; visibility never widens to another club or signed-out visitors.
- A regular non-member opening a group gets access guidance, not not-found, but receives no private rows even in initial render, LiveView diffs or direct data/action requests.
- A club admin outside a custom group sees only its Members surface, with no conversation content, compose action or implicit email membership.
- Direct conversation/detail/reply/follow/delivery routes still require actual effective conversation access.
- Valid explicitly selected groups, including non-member placeholders, remain selected. A remembered existing same-club group opens its current permitted surface; missing/foreign selections fall back to Everyone. No membership or access is inferred from browser storage.
- Existing system-group membership and last-Admin rules are unchanged.

## Open Business Decisions

None known. Matt approved the email-only placeholder until 065 and the prototype's access distinctions.

## Implementation Plan

1. Separate discovery from participation in the Membership public query API. Add a club-scoped discovery summary for an authenticated active club member. Preserve `list_active_groups_for_member/2` as the actual-membership API: Messaging uses it for access, so broadening it would expose conversations.
2. Update `MemberDashboardPresentation` to resolve group identity within the authorised club, then load only the permitted surface. Explicitly distinguish ordinary non-member, outside admin and participating member. Do not fetch private message/member rows and merely hide them in HEEx.
3. Extend the existing stateless tabs/frame/list composition in `page_html/club.html.heex` and `member_dashboard_group_tabs.ex`. Keep one contextual action slot, correct tab/panel ARIA and keyboard behaviour. Do not restore the removed single-member promotional blank slate.
4. Preserve selected-group routing and remembered selection through `MemberDashboardLive` and its existing browser hook. Refresh discovery/access state on relevant read-model changes; reject direct actions after access loss. Keep conversation access in public Membership/Messaging APIs, not projection joins in the web layer.
5. Implement the tagged domain/browser examples and focused presentation, component and routed LiveView regressions. Verify no disclosure on guessed URLs, cross-club IDs or stale browser state; run `dev check` on the exact delivered state.

## Open Technical Decisions

None expected to block implementation. Use opaque existing group IDs and existing club-host/query routing helpers. Keep read-model changes and privacy decisions server-authoritative. No new aggregate or generic permission framework is needed.

## New Capability

Members can find a group's name and know how to ask for access. Club admins can inspect who belongs without subscribing to conversations.

## Validation Plan

- Parse shared Gherkin and confirm runner-debt exclusions while planning.
- Test discovery separately from conversation access, including direct URLs and already-open LiveView updates.
- Run both runners' new scenarios as their implementation lands and retain existing 058/system-group regressions. Update the historical 058 scenario-inventory assertion in `acceptance-tests/test/cucumber_config.test.js` to recognize scenarios evolving in later iterations without losing provenance or hiding runnable regressions.
- Manually review Eve's email-only placeholder and Dan's Members-only view on desktop/mobile.
- Run `dev check` for delivery and report its exact checked commit/state.

## Risks / Follow-ups

The highest risk is reusing the new discovery list as a conversation access grant. Keep the existing active-membership query separate. Do not turn metadata visibility into access to conversation subject lines or member lists. Request access is intentionally absent until 065; membership actions arrive in 063–064. No problem-note status updates, app-wide error redesign or unrelated refactor belongs here.
