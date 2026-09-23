# Leave custom groups and remove their members

Date: 2026-09-13
Status: implementing

The approved removal controls, confirmations, and post-removal surfaces remain unchanged. This revision simplifies the underlying behaviour and implementation model.

## Goal

Group members and club admins can remove people from a custom group, and members can leave. Removal immediately ends group participation without changing club membership or roles. Follow preferences remain available if the person later rejoins, while messages posted during their absence create no delivery for them.

## Background / Context

This iteration depends on [063](../063-add-custom-group-members/plan.md), including the creation and club-departure safeguards from 062. It exposes the matching removal operation using the same custom-group manager policy. Empty groups remain available for later repopulation.

This plan explicitly supersedes iteration 062's earlier acceptance statement that any active club member may email a custom group without joining it. The current-participation rule is authoritative: only current custom-group participants may create a root conversation by inbound email, including when the group is empty. Rejected attempts create no conversation and no recipient deliveries, and use the existing message-not-posted response.

A club membership is the enduring relationship between a person and a club. For this iteration, group participation is simply the person's current inclusion in a group. Ending that participation controls access and new activity for the group; it does not end club membership, alter club roles, or delete the person's conversation follow preferences.

Each conversation currently belongs to exactly one group. The model should not prevent later support for conversations associated with more than one group, but this iteration does not combine authorization from multiple groups or introduce machinery for that future possibility.

## Related Problems

- [Retired groups need archiving](../../problems/2026-09-12-retired-custom-groups-need-archiving.md): intentionally unresolved. Last-member departure leaves the group unchanged, not archived or deleted.
- [Renaming](../../problems/2026-09-12-custom-groups-cannot-be-renamed.md): intentionally unresolved.
- [CQRS/event-sourcing drift](../../problems/2026-06-17-cqrs-event-sourcing-design-drift.md): intentionally not expanded in this slice. The iteration uses the existing group participation and messaging boundaries instead of adding a new cross-context lifecycle protocol.

## Scope

### In scope

- Custom-group members can remove other members or themselves; club admins can remove any custom-group member without belonging to that group.
- Group-specific Leave/Remove controls and confirmation, preserving club membership and roles.
- Current group participation controls reading, posting, web replies, email replies, and follow actions.
- Stale screens and stale actions fail with the existing generic authorization error once participation has ended.
- Message email recipients are fixed when each root message or reply is posted. Later removal does not cancel deliveries already created or queued for that message.
- Follow preferences survive a person's absence from a group. No delivery is created for that person for messages posted while absent; rejoining creates no backlog; messages posted after rejoining use the person's still-current follow preferences normally.
- Last-member departure, unchanged empty groups, and normal admin repopulation through the existing addition behaviour from 063.
- One conversation belongs to one group in the current product scope.

### Out of scope

- Archiving or deleting groups, expiring links, role changes, club removal UI, public or self-join groups, removal notifications, special empty-group email rejection, technical-failure screens, or a new app-wide error system.
- First-class admission-lifecycle group-membership identities, person-owned subscription authorization ledgers, revocation receipts, authorization unions, generations, cutoffs, or conversation cleanup fan-out.
- Multi-group conversation behaviour. The data model may remain extensible, but no combined access or delivery rules are implemented now.
- Cancelling or changing recipients for deliveries created when a message was posted.
- Provider crash recovery, ambiguous provider acceptance, and duplicate-handoff handling.

## Iteration Type

Behaviour-facing. Rule: current custom-group participation controls group activity, while removal leaves club status and follow preferences unchanged.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

- `acceptance-tests/features/custom_group_membership.feature`: removal by a group member or outside club admin, ordinary non-member refusal, club status preservation, and system-group guards.
- `acceptance-tests/features/custom_group_lifecycle.feature`: immediate access loss, fixed delivery recipients, no delivery or backlog while absent, follow preference resumption after rejoining, and last-member departure/repopulation.

Iteration-064 scenarios keep a runner-debt tag until that runner genuinely exercises the behaviour. Domain-covered removal, delivery, follow, and empty-group scenarios retain only `@todo-ui`; the stale-view scenario retains both tags until it uses a real LiveView/browser session and the inbound webhook adapter. The superseded iteration-062 outsider-root scenario in `custom_group_conversations.feature` is updated to the current participant-only rule. Other 062/063 scenarios and tags are unchanged.

## Allowed acceptance feature changes

- `acceptance-tests/features/custom_group_membership.feature`: implement the existing iteration-064 removal and system-guard examples and remove or narrow their runner-debt tags when supported.
- `acceptance-tests/features/custom_group_lifecycle.feature`: implement the revised iteration-064 access, delivery-fixation, follow-preference, and empty-group examples and remove or narrow their runner-debt tags when supported.

Preserve existing 062/063 scenarios and current Everyone, Admin, and reply regressions. Do not rewrite acceptance language around internal event ordering or delivery-provider mechanics.

## Designs

The approved designs remain the implementation source; this revision requires no visual redesign:

- `design-system/templates/club-group-members.html`: Leave/Remove controls and confirmations, ordinary member lists, and the empty-group state.
- `design-system/templates/club-group-non-member.html`: former-member placeholder and outside-admin management view.
- `design-system/explorations/custom-groups-prototype.html`: approved transitions, including last-member leave.

Controls must identify the affected group and must not suggest club removal. Reuse normal member rows and the active-tab action pattern. After leaving, a regular member remains on the group's restricted surface; an admin retains membership management without Conversations. Until 065, the placeholder continues to use the Admin email only. Do not add an archive prompt, removal email, follow-reset UI, or custom infrastructure-failure state.

The designs' promise to stop getting group emails “straight away” means messages posted after departure do not create a delivery for that person. It does not retract or cancel a delivery fixed when an earlier message was posted.

## Acceptance Criteria

- Bob can remove Alice from Board even if Alice is a club admin. Alice remains a club member and admin and can still manage Board membership, but cannot read, post, follow, or reply in Board while outside it.
- Dan can remove a Board member while remaining outside Board. Eve cannot remove anyone while outside Board because she is not a club admin.
- Members can leave, including the last member. An empty group keeps its name, address, conversation history, and place in the club's group list.
- Once participation ends, fresh requests and stale screens/actions for Board reading, posting, web replies, email replies, and follow changes receive the existing generic authorization error.
- For each message, the email recipient set is fixed when that message is posted. Removing someone afterward does not cancel a delivery already created or queued for that message.
- A person outside the group receives no delivery for messages posted while absent, even if they still follow that conversation.
- Leaving and removal preserve follow preferences. Rejoining provides history but no backlog for messages posted during the absence. Future messages in conversations the person still follows resume normal delivery after rejoining.
- Removal changes only group participation. Club membership, club roles, Everyone/Admin policies, and last-Admin protection remain unchanged.
- Empty custom groups use the ordinary current-participation rule: an outsider's inbound post is rejected with the usual authorization treatment, creates no conversation, and creates no deliveries.

## Open Business Decisions

None known. The agreed decisions are: empty groups remain; participation gates current activity; posted-message recipients are fixed; follows survive absence without backlog; removal never changes club membership or roles; and provider crash/duplicate-handoff handling is excluded.

## Implementation Plan

1. Keep the existing current group-participation model. Add the actor-bearing custom-group removal use case at the existing Membership consistency boundary, preserving exact retry behaviour, custom-group restrictions, actor/target authorization, and system-group safeguards. Removal changes only the target's participation in that group.
2. Apply the existing current-participant check consistently to conversation reads, new posts, web replies, inbound email replies, and follow/unfollow actions. Ensure stale LiveViews and direct/stale requests use the existing generic authorization error rather than retaining access or introducing new error UI.
3. Preserve conversation follow preferences when participation ends; remove the departure-triggered follow-cleanup workflow from the iteration design. A follow preference alone does not grant access or make an absent person eligible for delivery.
4. At root-message or reply posting, calculate recipients from that message's audience and then-current group participation and follow rules, and persist/create those deliveries as the fixed recipient set. Do not re-evaluate group participation to cancel those deliveries later. Do not create deliveries or later backlog for people who were absent at posting time.
5. Reuse the approved member-list controls, confirmations, and post-removal surfaces. Refresh open group/conversation views from existing membership projection events so removed people lose visible content promptly; server-side authorization remains decisive.
6. Implement the iteration-064 domain/browser examples and focused tests for actor/target authorization, stale reads/actions, web and email replies, recipient fixation, absence without backlog, follow resumption after rejoin, last-member departure, empty-group repopulation, and club/system-group invariants.

## Open Technical Decisions

None known. Conversation-to-group lookup must continue to use the current one-group association while avoiding an unnecessary permanent schema invariant that would block a later multi-group design. This iteration does not design that future behaviour.

## New Capability

People can stop participating in a custom group, and authorized people can remove them, without changing anyone's club standing, destroying group history, or erasing follow preferences.

## Validation Plan

- Run targeted domain tests for every actor/target combination, including removing a club admin and the last group participant.
- Exercise stale conversation views and direct read, post, web-reply, email-reply, and follow attempts after removal; verify the existing generic authorization error and no unauthorized content or message creation.
- Post a message before removal and verify its already-created/queued delivery remains; post while the person is absent and verify no delivery is created for them.
- Leave while following a conversation, post during the absence, rejoin, and verify no backlog. Post a later reply and verify the preserved follow preference resumes delivery.
- Preserve system-group, club-membership, role, and last-Admin tests; run both acceptance runners and `dev check` during implementation.
- For this planning-only revision, run Markdown/link/Gherkin formatting checks and `git diff --check`; do not run `dev check`.

## Risks / Follow-ups

- Delivery fixation must happen at posting time. Code that lazily discovers recipients during dispatch could accidentally suppress an already-created delivery after removal or produce delivery for someone who was absent when the message was posted.
- Current authorization depends on promptly available group-participation state, but stale clients must still be rejected server-side and shown the existing generic error.
- The one-conversation/one-group rule describes current scope, not an eternal constraint. Multi-group authorization and delivery semantics require a separate future product and architecture decision.
- Archive and rename needs remain separate and are not implicit consequences of an empty group.
