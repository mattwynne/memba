# Generic group-scoped club home

Date: 2026-09-06
Status: ready

## Goal

Replace the hard-coded Everyone dashboard with a generic group-scoped club home.
A member can choose any group they belong to; the selected group scopes its
conversations, member list, and new-message composition.

Today this presents Everyone to every active member and Admin to Admin-group
members. The presentation must work unchanged for future named groups, without
a special screen or branch for a group name/key.

## Background / Context

Iterations 056 and 057 made groups a club-scoped conversation audience with
active group membership, group email slugs, conversation access grants, and
group-aware Messaging queries. The existing web dashboard nevertheless always
loads the deterministic Everyone group. Admin conversations can be created and
replied to by email, but deliberately have no web presentation.

The existing design preview, [`design-system/templates/club-groups.html`](../../../design-system/templates/club-groups.html), supplies the final information
architecture: a group rail, group header, and group-scoped Conversations and
Members tabs. Its displayed Board, committees, open groups, and group-management
actions illustrate later capabilities; this iteration only needs the rail and
scoped view for groups the current member already belongs to.

## Related Problems

- [`docs/problems/2026-06-23-interface-too-fancy-for-simple-app-use.md`](../../problems/2026-06-23-interface-too-fancy-for-simple-app-use.md): **partially addresses.** The group rail and explicit selected-group context establish a clearer member-app information architecture. This iteration does not settle the broader mobile and desktop visual-direction problem.
- No captured problem directly covers group discovery or group-scoped presentation.

## Scope

### In scope

- A group rail that lists each active group membership held by the signed-in
  active member in the selected club, with Everyone and Admin merely current
  examples—not UI special cases.
- An authorised selected-group URL, group header, member count, group email
  address when present, and the existing Conversations / Members tabs scoped to
  the selected group.
- Conversation and member-list queries that return only conversations readable
  through, and active members of, the selected group.
- Group-aware web composition: New message and the empty-state action create a
  conversation for the selected group. There is no audience picker and no
  multi-group composition.
- Privacy-preserving route and action authorisation: a group that the current
  member does not actively belong to is omitted from the rail and produces the
  ordinary not-found response when addressed directly. Detail, reply, follow,
  and compose actions must retain the same access boundary.
- A remembered selected group per browser (using the design's local-selection
  convention): the club home opens the last selected accessible group, otherwise
  Everyone. An explicit authorised group URL wins over the remembered value.
- Preserve `/conversations` and `/members` as Everyone fallback routes and
  existing club-wide behaviour.
- Public Membership query APIs that return group presentation summaries and
  group memberships without exposing Membership projections to the web layer.
- Validate the selected group belongs to its supplied club before group-aware
  sending or rendering, closing the current code-health risk that the generic
  send boundary accepts independently supplied club and group IDs.

### Out of scope

- Creating, renaming, deleting, joining, leaving, or managing groups and group
  memberships; “Open to join,” “New group,” and group settings in the design
  remain absent.
- An audience picker, cross-posting, multi-group composition, or changing
  access grants on an existing conversation.
- Public group/conversation visibility, group visibility defaults, or a public
  group page.
- Changing group-email policies, email routing/slugs, follower delivery, or
  reply-by-email behaviour.
- General club switching / other-club navigation.
- Read/unread activity state.

## Iteration Type

Behaviour-facing. The changed rule is: a member can discover only groups they
belong to and can read, list members of, and start a conversation in the
selected group; non-members learn nothing about that group's web surface.

## Acceptance Scenarios / Feature Files

BDD decision: **Required.** This slice changes visible information architecture,
private-group discovery, access control, conversation scope, and composition
recipient scope.

Planning adds [`acceptance-tests/features/group_conversations.feature`](../../../acceptance-tests/features/group_conversations.feature), tagged
`@iteration-100 @todo-domain @todo-ui`. Its scenarios define:

- ordinary and Admin members seeing only their own groups;
- a future named group being rendered with no group-specific UI;
- selected-group conversation and member-list scope;
- group-scoped web composition and recipient/access privacy;
- not-found treatment for a guessed private-group link; and
- last-selected-group and Everyone fallback behaviour.

The runner-debt tags are intentional while delivery adds the domain and browser
steps. They must be removed or narrowed only when each runner can execute the
relevant examples. Matt approved the scenario language as domain language on
2026-09-06.

## Allowed acceptance feature changes

- `acceptance-tests/features/group_conversations.feature`: add the group
  navigation, scoping, composition, privacy, and remembered-selection scenarios
  above; during implementation, replace or narrow `@todo-domain` and
  `@todo-ui` only as the corresponding step support becomes executable.

Existing `member_message_deliverability.feature` and
`club_message_replies.feature` continue to cover Everyone and email-based
Admin message behaviour. They need no semantic rewrite for this slice.

## Designs

Design needed and available: [`design-system/templates/club-groups.html`](../../../design-system/templates/club-groups.html).

Implement the group rail, selected state, group header, group address/member
metadata, scoped section tabs, and New message action as the reusable final
shape. Deliberately omit the preview's “Open to join” division, New group,
group settings, and cross-posted conversation tags because the corresponding
capabilities do not exist yet. DesignSync was not available in this Pi session;
the checked-in template is sufficient for this slice.

## Acceptance Criteria

- An active member sees a deterministic, stable list of exactly their active
  groups in the current club; group names, IDs, and keys do not drive
  presentation-specific branches.
- Everyone remains visible to all active club members; Admin is visible only to
  active Admin-group members.
- Selecting an authorised group makes the header, conversations, member count,
  member rows, section links, empty state, and New message action refer to that
  group.
- The group conversation list contains only conversations with read or write
  access granted to the selected group; the member list contains only active
  members of that group.
- A new web message carries the selected group as its audience, is delivered to
  its active group members, and creates that group's conversation access grant.
- A person who is not an active member of a group cannot see it in the rail or
  access it by its URL, message detail, reply/follow action, or compose action;
  the URL response is not found and does not disclose group data.
- The selected group URL is authoritative when authorised. Otherwise, a browser
  returns to its last selected accessible group; with no saved or no-longer-
  authorised selection it falls back to Everyone.
- Existing Everyone routes and flows retain their current observable behaviour.
- Group-aware presentation and sending reject a group/club mismatch before
  loading, composing, or dispatching a message.
- `dev check` passes on the delivered implementation.

## Open Business Decisions

None known.

Confirmed decisions:

- The UI is generic for any group; Everyone and Admin are present-day data, not
  the UI's domain model.
- A member sees only groups they already belong to.
- Non-member access to a private group is not found, not access denied.
- New message uses the selected group; there is no audience picker.
- Last selected group is remembered per browser, with Everyone as fallback.

## Implementation Plan

1. Inspect the current group projections and Messaging group queries from
   iterations 056–057. Add a public Membership query for the active groups of a
   given active member in a given club. It must return plain presentation
   summaries (group ID, name, key, optional email slug/address information, and
   active member count) in stable display order, and validate club/group/person
   relationships within Membership rather than leaking projection schemas.
2. Refactor `MembaWeb.MemberDashboardPresentation` so it resolves the signed-in
   active club membership once, authorises a selected group through the new
   Membership API, and loads the selected group's active members and readable
   conversations. Keep all current row presentation—including participant names
   and role badges—working against the selected member set. Return the same
   not-found result for missing, foreign-club, or non-member group selection.
3. Add canonical group-scoped member routes for Conversations and Members using
   an opaque group ID, while retaining `/conversations` and `/members` as
   Everyone routes. Ensure tabs, message links, invitation affordances, and
   return navigation preserve the selected group where applicable.
4. Adapt `MemberDashboardLive` and `PageHTML.club` to render the generic rail,
   group header, selected state, accessible metadata, and selected-group
   Conversations / Members panels from assigns. Follow the referenced design's
   desktop/mobile layout and accessible nav/tab semantics. Do not render its
   open-to-join or group-administration controls.
5. Add a small LiveView client hook or equivalent browser-local mechanism that
   remembers a successful rail selection by club, restores it only when no
   explicit group route is requested, and lets the server fall back safely to
   Everyone when a saved group is absent or unauthorised. The server remains the
   authority for every final selection.
6. Generalise the member compose entry and submit path to carry an authorised
   audience group from the selected group route. The compose confirmation and
   error paths must retain that group. Retain the current Everyone default when
   entered through existing routes; do not expose an audience selector.
7. At the Messaging boundary, resolve/verify the audience group under the
   supplied club before recipient lookup and command construction. Make this
   invariant fail closed for mismatched group/club IDs, and cover it with a
   regression test so a future caller cannot create a cross-club conversation.
8. Review all member-facing conversation detail, in-app reply, follow/unfollow,
   receipt/delivery, and direct action paths. Authorise the current person via
   an active group with the conversation's required access level, not merely
   via club membership or current rail state. Preserve correct access for a
   future conversation shared with several groups.
9. Add focused Membership, Messaging, dashboard-presentation, LiveView/router,
   and browser tests for generic custom-group fixtures, selection scope,
   no-disclosure not-found behaviour, remembered selection, group-aware compose,
   existing Everyone regression, and club/group mismatch rejection. Implement
   the planned Cucumber step support, remove/narrow runner-debt tags as each
   runner becomes executable, and run `dev check`.

## Open Technical Decisions

None expected to block implementation.

- Use opaque group IDs for canonical scoped routes so a group display name or
  future routing-email change never breaks a saved or shared app link.
- Use browser-local persistence only as a convenience. It is not an access
  grant; the server authorises the route on every request and falls back to
  Everyone when the selection is stale.
- Query effective group access through public Membership and Messaging APIs.
  Do not query another context's projection schemas from the web layer.

## New Capability

Members can use one club-home pattern for their club-wide and private-group work:
choose a group they belong to, see its people and conversations, and send a
message to it. The same UI supports future named groups as soon as they exist
and the member is assigned, without a new group-specific screen.

## Validation Plan

- Before implementation, run the acceptance configuration checks to verify
  `@todo-domain` and `@todo-ui` exclude the planning scenarios from default
  domain and browser runners.
- Unit-test Membership group-list summaries, active counts, ordering, and
  club/person/group authorisation without projection-schema leakage.
- Test Messaging's group/club invariant and group-recipient composition,
  including future named-group fixtures and Everyone regression.
- Test LiveView routes and rendering for group rail membership filtering,
  selected conversation/member scope, not-found no-disclosure, direct links,
  stale remembered selection, and selected-group compose persistence.
- Exercise the scenario examples through both Cucumber runners after their step
  support is present and runner-debt tags are removed/narrowed.
- Manually demo an ordinary member and an Admin member in one club: switch
  groups, visit a copied group link as each person, compose an Admin message,
  refresh/reopen the club home, and verify the ordinary member never sees the
  Admin group or conversation.
- Run `dev check` on the committed delivered implementation.

## Risks / Follow-ups

- The current group model has only Everyone and Admin. This slice must prove
  its generic behaviour with a named-group fixture while avoiding a hidden
  requirement for a group-management UI.
- Message detail and in-app actions were built while web views were Everyone-
  only; missing one direct path could expose an Admin/private conversation.
  Review the full action surface, not only the dashboard list.
- Browser-local remembered selection must never be mistaken for authorisation,
  and group removal between visits must fall back without revealing a group.
- The group/club mismatch identified in `docs/code-health.md` is especially
  important once web composition can supply a non-Everyone audience. The
  invariant repair belongs in this slice because it is necessary to safely
  honour the selected audience.
- Group management, joining/open groups, shared conversations, group defaults,
  and group settings remain separate future iterations.
