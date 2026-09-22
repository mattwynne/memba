# Leave custom groups and remove their members

Date: 2026-09-13
Status: draft revision

The behaviour and designs remain stakeholder-approved. The implementation approach is being revised after delivery review exposed a missing first-class group-membership model.

## Goal

Group members and club admins can remove people from a custom group, and members can leave. Removal ends access and future emails immediately and clears follows; empty groups remain available for later repopulation.

## Background / Context

Depends on [063](../063-add-custom-group-members/plan.md), including the creation and club-departure safeguards from 062. This exposes the matching removal operation using the same custom-group manager policy. Matt explicitly rejected automatic archiving and later confirmed that old conversation follows must not resume after re-add.

The business distinction is between leaving a group and leaving the club. A club membership is the enduring relationship between a person and a club. A group membership is a separate relationship within that club: it begins when the person joins the group and ends when they leave or are removed. Rejoining creates a new group membership while preserving the same club membership. Removing a club admin from Board must therefore end only that Board group membership, not their Admin role or ability to manage Board's membership.

The first delivery attempt represented group participation as a reusable active/inactive relation and tried to distinguish removal, delayed follow work and re-addition with a club-wide generation, per-member and per-conversation cutoffs, projection barriers and conversation cleanup fan-out. Independent review repeatedly found valid event orderings that escaped those inferred cutoffs. Iteration 064 now models group membership and follow authorization directly rather than extending that cleanup mechanism.

## Related Problems

- [Retired groups need archiving](../../problems/2026-09-12-retired-custom-groups-need-archiving.md): intentionally unresolved. Last-member departure leaves the group unchanged, not archived or deleted.
- [Renaming](../../problems/2026-09-12-custom-groups-cannot-be-renamed.md): intentionally unresolved.
- [CQRS/event-sourcing drift](../../problems/2026-06-17-cqrs-event-sourcing-design-drift.md): partially addressed by replacing the implicit multi-aggregate cleanup workflow with explicit group-membership facts, Messaging-owned subscription state and a durable cross-context revocation receipt.

## Scope

### In scope

- Custom-group members can remove other members or themselves; club admins can remove any custom-group member without belonging.
- Clear, group-specific Leave/Remove controls and confirmation; preserve club membership/roles.
- Immediate server-side read/write/follow and future email eligibility revocation, including already-open views and previously followed conversations.
- Clear follows on departure; explicit re-add restores history and normal membership, not former follow preferences.
- First-class group memberships: joining creates one, removal ends it, and rejoining creates a new one without changing the person's club membership.
- Messaging subscriptions record the group membership or memberships that authorized them; ending a group membership invalidates that authorization without conversation-by-conversation cleanup as the correctness mechanism.
- Durable, idempotent Membership-to-Messaging revocation with an explicit completion receipt, plus reconciliation of existing group memberships and historic follow facts into the new model.
- Last-member departure, unchanged empty groups, and normal admin repopulation through 063.

### Out of scope

Archiving/deleting groups, expiring links, role changes, club removal UI, public/self-join groups, removal notifications, special empty-group email rejection, technical-failure screens, a new app-wide error system, and redesign of Messaging outside subscription authorization and delivery eligibility.

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
- Re-add grants full history and the ordinary welcome but no previous follows. It creates a new group membership; the ended group membership and the follows it authorized remain ended. Explicitly following again under the new group membership restores normal future reply notifications.
- Already-delivered/provider-handed-off emails cannot be recalled. Do not hand new private deliveries to the provider after known access loss.
- Everyone/Admin membership policies, last-Admin protection and club membership remain unchanged.

## Open Business Decisions

None known. Matt explicitly chose empty-but-existing groups, no archive-on-empty, full history on re-add and fresh follows after re-add.

## Implementation Plan

1. Record the architecture decision before further implementation. Define club membership and group membership as separate domain concepts. Each group admission creates a new group membership; removal ends that exact group membership; re-addition creates another. Membership remains authoritative for current group participation and emits immutable facts that identify the group membership being started or ended. Preserve club membership, club roles, system-group invariants and accepted actor/target authorization.
2. Replace the reusable active/inactive group relation with a current-state projection of first-class group memberships. Reconcile each existing active relation into one current group membership with deterministic, retry-safe identity. Preserve historical source events and replay compatibility; do not invent historical membership periods that cannot be proved.
3. Add an actor-bearing custom-group removal use case at the appropriate Membership consistency boundary. Validate custom-group, actor and target identities; permit self-removal and last-member removal; make exact retries event-free; and end only the selected group membership. Do not route group removal through club-member or role-removal commands.
4. Replace conversation cleanup fan-out with a Messaging-owned member subscription ledger. Canonical follow facts record which current group memberships authorized the subscription. Membership sends one idempotent revocation when a group membership ends; Messaging serializes subscription changes and revocation in the same member-owned stream and records a durable completion receipt. Arrival order must not affect the result: delayed work authorized by an ended group membership is rejected, while a follow authorized by another current group membership or a newly created group membership can succeed.
5. Route manual follow and successful root/reply auto-follow through the same authoritative subscription operation. Product callers must not supply trusted authorization provenance. Stop deriving projected follow state independently from `MessageSent`; canonical subscription facts become the source for aggregate and projection replay. Reconcile historic root/reply follow shapes once, with deterministic retry/restart behaviour, then keep legacy scans out of the live command path.
6. Apply current authorization throughout group/conversation queries, actions, notification creation and provider handoff. If the removal API promises completed cleanup, wait for the explicit Messaging revocation receipt rather than projection enumeration. Projection barriers remain for read-model visibility only. Do not hand new private deliveries to the provider after authority loss is known.
7. Refresh `MemberDashboardLive`, conversation views and membership panels on relevant read-model events so content disappears after revocation. Extend shared custom-group member rows with Remove/Leave confirmation and post-removal surfaces. Preserve ordinary member lists, actor role labels, route context, focus handling, the single tab action slot and existing empty-group administration.
8. Implement the approved domain/browser examples and focused state-machine coverage: follow then remove; remove then delayed old follow; remove/re-add/new follow; surviving access through another group membership; ordinary unfollow followed by delayed work; root/reply auto-follow; queued delivery; handler retry; aggregate restart; projection replay; historic reconciliation; delivered-copy limits; and existing system/club invariants. Run `dev check` on the exact final delivery state.

## Open Technical Decisions

None known. Membership owns group memberships. Messaging owns subscriptions and durable revocation receipts. Cross-context delivery is idempotent and eventually consistent; completion waits on a domain receipt, not projection enumeration. The detailed event and command names belong in the architecture decision, but they must preserve this ownership and ordering model.

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

Read access and email sending cross asynchronous boundaries. “Immediate” cannot mean recalling already delivered messages, but it does require current authority at each new action/handoff and durable revocation before removal reports completion. Multi-group conversation editing remains out of scope; a subscription remains effective when at least one recorded authorizing group membership is current, and ending one group membership must not remove authorization supplied by another.

Historic group and follow facts predate first-class group memberships. Reconciliation must be deterministic, idempotent and conservative where history cannot prove an active authorization. Preserve immutable source events and verify replay from origin before removing compatibility code. Archive/rename needs remain separate and are not implicit consequences of an empty group.
