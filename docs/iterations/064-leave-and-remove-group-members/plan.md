# Leave custom groups and remove their members

Date: 2026-09-13
Status: validated

Stakeholder review complete; Fabro plan validation pending.

## Goal

Group members and club admins can remove people from a custom group, and members can leave. Removal ends access and future emails immediately and clears follows; empty groups remain available for later repopulation.

## Background / Context

Depends on [063](../063-add-custom-group-members/plan.md), including the creation and club-departure safeguards from 062. This exposes the matching removal operation using the same custom-group manager policy. Matt explicitly rejected automatic archiving and later confirmed that old conversation follows must not resume after re-add.

The business distinction is between leaving a group and leaving the club. Removing a club admin from Board must not remove their Admin role or their ability to manage Board's membership.

## Related Problems

- [Retired groups need archiving](../../problems/2026-09-12-retired-custom-groups-need-archiving.md): intentionally unresolved. Last-member departure leaves the group unchanged, not archived or deleted.
- [Renaming](../../problems/2026-09-12-custom-groups-cannot-be-renamed.md): intentionally unresolved.
- [CQRS/event-sourcing drift](../../problems/2026-06-17-cqrs-event-sourcing-design-drift.md): constraint for the named cross-context follow-cleanup policy, not an invitation to redesign Messaging.

## Scope

### In scope

- Custom-group members can remove other members or themselves; club admins can remove any custom-group member without belonging.
- Clear, group-specific Leave/Remove controls and confirmation; preserve club membership/roles.
- Immediate server-side read/write/follow and future email eligibility revocation, including already-open views and previously followed conversations.
- Clear follows on departure; explicit re-add restores history and normal membership, not former follow preferences.
- Last-member departure, unchanged empty groups, and normal admin repopulation through 063.

### Out of scope

Archiving/deleting groups, expiring links, role changes, club removal UI, public/self-join groups, removal notifications, special empty-group email rejection, technical-failure screens and a new app-wide error system.

## Iteration Type

Behaviour-facing. Rule: custom-group membership can be ended by a group member or club admin, ending participation and followed notifications without deleting the group or changing club membership.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

- `acceptance-tests/features/custom_group_membership.feature`: removal by member/outside admin, ordinary non-member refusal and system-group guards.
- `acceptance-tests/features/custom_group_lifecycle.feature`: access/mail revocation, delivered copies, re-add without old follows, explicit follow again, last-member departure and repopulation.

This slice's examples carry `@iteration-064 @todo-domain @todo-ui`. Other rules in those files retain 062/063 tags and state. Matt reviewed the rules and HTML prototype during planning.

## Allowed acceptance feature changes

- Only the two files above: implement the 064 examples and remove/narrow their runner-debt tags. Preserve existing 062/063 scenarios and all current Everyone/Admin/reply regressions. Do not weaken revocation examples to make asynchronous propagation convenient.

## Designs

- `design-system/templates/club-group-members.html`: Leave/Remove confirmations, ordinary and empty membership lists.
- `design-system/templates/club-group-non-member.html`: former-member placeholder and outside-admin view.
- `design-system/explorations/custom-groups-prototype.html`: final transitions, including last-member leave.

Controls must say which group is affected, not suggest club removal. Reuse normal member rows and the active-tab action pattern. After leaving, a regular member remains on that group's now-restricted surface; an admin retains membership management without Conversations. Until 065, the placeholder still uses the Admin email only. Do not add an archive prompt, removal email or custom infrastructure-failure state. Reviewed local design is sufficient; cloud sync is pending.

## Acceptance Criteria

- Bob can remove Alice from Board even if Alice is a club admin; Alice keeps her role and management power but loses Board conversations/emails until explicitly rejoining.
- Dan can remove a Board member while remaining outside Board; Eve cannot remove anyone while outside Board and not a club admin.
- Members can leave, including the last member. An empty group keeps its name, address and conversation history and remains listed for the club.
- Removal immediately changes effective authorization and future email eligibility; guessed/stale links, open LiveViews, direct replies and follow actions cannot retain access.
- Replies to formerly followed conversations and future roots are not emailed while absent. Group-related follows are cleared, not merely hidden by a membership filter.
- Re-add grants full history and the ordinary welcome but no previous follows. Explicitly following again restores normal future reply notifications.
- Already-delivered/provider-handed-off emails cannot be recalled. Do not hand new private deliveries to the provider after known access loss.
- Everyone/Admin membership policies, last-Admin protection and club membership remain unchanged.

## Open Business Decisions

None known. Matt explicitly chose empty-but-existing groups, no archive-on-empty, full history on re-add and fresh follows after re-add.

## Implementation Plan

1. Add an actor-bearing custom-group removal use case/command, using the same Club-owned authorization as 063. Validate custom-group identity and actor/target club identities; permit self-removal and last-member removal. Reuse `GroupMemberRemoved`; do not route this operation through club-member or role-removal commands.
2. Extend the 062 follow-cleanup collaboration to explicit group removal. Use public Messaging APIs and idempotent `UnfollowConversation` facts; include auto-followed roots/replies, not only manually followed rows. A late cleanup event must not erase a newly established follow after a genuine re-add. Order cleanup with removal completion or use event generation/version identity so stale work cannot act on a later membership. Preserve unrelated groups' follows and existing system-group behaviour.
3. Apply current authorization throughout group/conversation queries, actions and queued-delivery handoff. Refresh `MemberDashboardLive`, conversation views and membership panels on relevant read-model events so content disappears after revocation; hiding tabs alone is insufficient. Avoid sending stale queued private content to removed recipients using existing delivery-status/error mechanisms rather than a new UI workflow.
4. Extend shared custom-group member rows with Remove/Leave confirmation and post-removal surfaces. Preserve ordinary member lists, actor role labels, route context, focus handling and the single tab action slot. Empty groups use existing admin additions, with no new lifecycle status.
5. Implement domain/browser examples and focused aggregate, follower-policy, queued-delivery, rapid remove/re-add and LiveView tests. Include replay/idempotency, preserved unrelated follows, delivered-copy limits and existing system/club invariants. Run `dev check` on the exact final delivery state.

## Open Technical Decisions

Use the already-established 062 removal/follow-cleanup boundary rather than adding a second cleanup process. Membership is the authority for active access; Messaging owns follows and delivery. Avoid direct cross-context projection writes. Keep a newly granted follow distinguishable from stale cleanup work; test the selected ordering mechanism explicitly.

## New Capability

People can stop participating in a group, and the group can govern its own membership without changing club roles or destroying its history.

## Validation Plan

- Planning parser/debt exclusions; stakeholder review completed during discovery and prototype review.
- Test each actor/target combination including removing a club admin and the last member.
- Follow a conversation, remove the person, send root/reply, inspect no future delivery; explicitly re-add and verify history without follow restoration; follow again and verify new notifications.
- Exercise removal while a conversation is open and while delivery is queued; distinguish unsent work from already-handed-off email.
- Replay removal events and race removal/re-add/follow to prove no stale restore or over-broad follow deletion.
- Preserve all existing system-group and last-club-member tests; run both acceptance runners and `dev check`.

## Risks / Follow-ups

Read access and email sending cross asynchronous boundaries. “Immediate” cannot mean recalling already delivered messages, but it does require current authority at each new action/handoff and a safe remove/re-add ordering. Multi-group conversation editing remains out of scope; preserve the existing effective-access union and do not delete unrelated follows. Archive/rename needs are captured separately, not implicit consequences of an empty group.
