# Add active club members to custom groups

Date: 2026-09-13
Status: merged

Stakeholder review complete; Fabro plan validation pending.

## Goal

Any custom-group member, or any active club admin, can add an existing active club member. Joining grants the whole history and a welcome email, without a second group-admin role.

## Background / Context

Depends on [061](../061-discover-club-groups/plan.md) and [062](../062-create-custom-groups/plan.md). Groups and creator membership now exist; admins outside a custom group can inspect its Members view without reading discussions. This slice adds the admission operation, including an outside admin adding themselves.

Club invitations remain separate. Public group discovery is not an invitation or self-join permission. Membership grants read/write participation; the club Admin role grants management authority without implicit conversation access.

## Related Problems

- [Membership admins inviting club members](../../problems/2026-06-08-membership-admins-cannot-invite-members.md): preserves the existing separate invitation capability; group membership must not grant club invitation authority.
- [CQRS/event-sourcing drift](../../problems/2026-06-17-cqrs-event-sourcing-design-drift.md): constraint, not broad remediation. Authorize admission in the Club consistency boundary and keep welcome email composition outside aggregates/projectors.
- [Renaming](../../problems/2026-09-12-custom-groups-cannot-be-renamed.md) and [archiving](../../problems/2026-09-12-retired-custom-groups-need-archiving.md): deliberately unresolved.

## Scope

### In scope

- Custom-group additions by a current group member or club admin.
- Outside admins can add themselves or someone else without joining implicitly.
- Add-member picker limited to existing active club members who are not already in the group.
- Whole-history access, normal future group messages and a welcome email with a group link.
- System-group guards, authoritative permission/target checks, fresh membership state and duplicate-add idempotency.

### Out of scope

Group removal/leave controls (064), Request access (065), club invitations, separate group-admin roles, historical email replay, removal notifications, rename/slug editing, archiving/deletion, or special internal-failure UI/retry flows. Existing generic technical-error behaviour is reused.

## Iteration Type

Behaviour-facing. Rule: group members and club admins may admit active club members to a custom group; admission gives participation and history, not additional club authority.

## Acceptance Scenarios / Feature Files

BDD decision: Required.

- `acceptance-tests/features/custom_group_membership.feature`: addition, outsider denial, active-club eligibility, admin self-add/add-other and system-group safeguards. Tag this slice's rules/scenarios `@iteration-063 @todo-domain @todo-ui`; the shared file also contains future 064 removal examples.
- `acceptance-tests/features/custom_group_lifecycle.feature`: joining/history/welcome and explicit re-add after club departure, tagged 063. Retain the separate 062 departure and 064 removal/follow-reset examples.

Matt reviewed the rules and HTML prototype during planning.

## Allowed acceptance feature changes

- `acceptance-tests/features/custom_group_membership.feature`: implement the 063 examples and narrow/remove their runner-debt tags. Do not enable or erase 064 examples.
- `acceptance-tests/features/custom_group_lifecycle.feature`: implement the 063 joining/history/welcome example and narrow/remove its runner-debt tags. Preserve existing departure and future 064 examples.

Preserve all iteration tags and existing `club_member_invitations.feature` and `club_membership_administration.feature` semantics.

## Designs

- `design-system/templates/club-group-members.html`: ordinary member rows, Add member action and picker.
- `design-system/templates/club-group-non-member.html`: outside-admin Members view and Add yourself action.
- `design-system/emails/group-welcome.html`: welcome email, with authenticated group link and no replay of old mail.
- `design-system/explorations/custom-groups-prototype.html`: reviewed final interactions.

Omit removal/leave controls until 064. Group Members shows Add member in the sole contextual tab action position. Outside admin sees no Conversations or New message until actually added; Add yourself is explained as opting into history and emails. Use normal member rows even for one member. No invented joined dates or group-admin badges. Keep club invitation flow separate; custom-group Add member does not create people. Local designs are sufficient; cloud sync remains pending.

## Acceptance Criteria

- Every active group member can add another active member of that club, regardless of their club-admin role.
- Any active club admin can manage additions in any custom group, including self-add, without reading conversations or joining as a side effect of adding someone else.
- A regular club member outside the group cannot self-add, add another person or use a forged action to bypass the rule.
- Pending invitees, former members and members of another club are not eligible. The action never creates or restores club membership.
- New membership gives the whole history and write participation immediately; the welcome email links to the authenticated group page. Old conversation emails are not resent.
- Repeating an already-applied addition does not create another membership transition or repeat its welcome. A genuine later re-add sends a new welcome but does not restore old follows cleared on departure.
- Everyone and Admin retain automatic/role-based membership. The custom-group API cannot grant a club-admin role or bypass system-group rules.
- Existing group recipients exclude nonmember admins; additions and permissions refresh in open views.

## Open Business Decisions

None known. Deliver the welcome to the member's existing verified primary email; use the existing provider-neutral mailer/sender conventions and group-branded content. No new preferences or special delivery-status screen is introduced.

## Implementation Plan

1. Add a public authenticated custom-group admission use case and actor-bearing command handled by `Membership.Club`. Evaluate actor active club membership, actor group membership or existing admin permission, target active membership and custom-group identity against current aggregate state. Preserve trusted system-group commands rather than exposing them directly to web callers.
2. Reuse `GroupMemberAdded` and the existing projection. Make duplicate addition an idempotent no-op and carry sufficient actor/new-transition information for the welcome use case. Respect the departure/rejoin cleanup introduced in 062; no projection-only mutation or restoration shortcut.
3. Extend `MemberDashboardPresentation`, shared member components and the group Members surface with the picker and admin self-add. Use explicit component attributes/slots, not a copied full-page template. Query candidates through Membership's public API, reauthorize on submit and render fresh membership after a successful transition.
4. Add a small provider-neutral group-welcome composer using `Memba.EmailTemplates` and the existing `Memba.Mailer` handoff conventions. Send only after a confirmed new membership transition, not on projection replay, duplicate requests or ordinary group reads. Keep provider side effects out of aggregates/projectors; committed membership must not be represented as rolled back if delivery fails. Reuse default operational/error handling; do not build a notification framework, bespoke retry UI or delivery-status feature.
5. Implement the tagged admission/history scenarios, including outside-admin self-add, duplicate additions, inactive/cross-club targets and system-group bypass attempts. Test replay does not resend welcomes, already-open views update, and existing invitation/role behaviour is unchanged. Run `dev check` on the exact delivery state.

## Open Technical Decisions

No new aggregate is needed. Use explicit per-use-case command results or new-event metadata to distinguish a new addition from an idempotent no-op; never infer that distinction by racing a projection preflight. Use the existing mailer abstraction and primary-email API instead of a new provider dependency. The welcome route is a normal group URL requiring sign-in, not a token granting membership.

## New Capability

A group can grow through its own members without involving a club admin; an admin can join or populate it explicitly without gaining hidden access beforehand.

## Validation Plan

- Planning parser and runner-debt checks; stakeholder review completed during discovery and prototype review.
- Aggregate tests for actor/target/club identity, current permission, duplicates and concurrent changes.
- Membership/Messaging integration for history and normal email eligibility with no replay of historic conversation emails.
- Mailer tests for content, recipient, group link, a new transition versus duplicate/replay, using the test adapter rather than real email.
- Browser demo: Bob adds Carol; Dan adds Eve without joining; Dan adds himself; ordinary outsider cannot add anyone; role/system regressions.
- Both Cucumber runners and full `dev check` on the final delivery state.

## Risks / Follow-ups

The raw group commands currently serve trusted policies/backfills and are not a safe web authorization API. Do not expose them unchanged. Welcome delivery cannot undo membership: avoid conflating domain success and provider outcome. Leave/removal and their controls are intentionally deferred to 064; club-departure safety already exists from 062.
