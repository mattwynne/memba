# Live projection query migration matrix

This inventory is the implementation map for iteration 067. It records the
repository state before migration and the required query boundaries without
freezing package function names, concrete interest types, reconnect hooks, or
module placement. The interest names below are logical descriptions for task
003 to prove, not a proposed public package API.

The source notification is the post-commit message established by ADR 0021:

```elixir
{:read_model_changed,
 %{
   projector: projector,
   source_event: event,
   metadata: metadata,
   changes: changes
 }}
```

The target contract is ADR 0027: one registered query returns one coherent view
model for one ordinary assign, the LiveView owns the subscription, a matching
notification causes an authorized reread, and only that query assign is
replaced. Staff streams remain outside this contract.

## Route and migration inventory

The `:club_member` live session in `MembaWeb.Router` has fourteen routes served
by exactly seven modules. All seven have projection-backed display or
authorization data and therefore migrate. There is no whole-page exception;
the exceptions are the transient state that remains owned by each LiveView.
The session supplies the host-selected `club_id` and `club_id_source`, while
path and query parameters supply the selected group, person, message, or tab.

| Module | Routes | Decision | Coherent query result boundary |
| --- | --- | --- | --- |
| `MembaWeb.MemberDashboardLive` | `/conversations`; `/members`; `/groups/:group_id`; `/groups/:group_id/members`; `/groups/:group_id/members/add/:person_id` | Migrate | One dashboard view model under one assign for the selected club and group. Do not split member, group, permission, and conversation data into independently refreshed query assigns. |
| `MembaWeb.MemberGroupLive.New` | `/groups/new` | Migrate | One group-creation context result containing the freshly authorized selected club and current member. |
| `MembaWeb.MySettingsLive` | `/my/settings`; `/my/settings/profile`; `/my/settings/clubs`; `/my/settings/emails` | Migrate | One settings view model containing the selected club, current Person, current active club memberships, and email-address rows. |
| `MembaWeb.MemberMessageLive.New` | `/messages/new` (optional `group_id` query parameter) | Migrate | One compose-context result containing the selected club/member, authorized audience group, recipient count, and audience display data. |
| `MembaWeb.MemberMessageLive.Show` | `/messages/:message_id` (optional `group_id` query parameter) | Migrate | One authorized conversation-detail result containing the conversation, author names, follow state, and delivery data. |
| `MembaWeb.MemberMessageDeliveryLive.Show` | `/messages/:message_id/delivery` (optional `group_id` query parameter) | Migrate | One authorized delivery-detail result. It may share loading code with conversation detail, but binds its own one result assign and must include current receipt status. |
| `MembaWeb.MemberInvitationLive.New` | `/members/invitations/new` (optional `group_id` query parameter used by return navigation) | Migrate | One invitation context result containing the freshly authorized selected club/member and active-member count. |

## Fresh authorization and lifecycle rule

The HTTP pipeline verifies active club membership before entering the member
LiveView session. `IdentityAuth` then places `current_identity` and
`current_identity_clubs` on the socket. Those club rows are a mount-time
snapshot and are not fresh authority for a later query refresh.

Every initial query and refresh must instead begin with the authenticated,
normalized identity email retained by the LiveView and:

1. call `Accounts.list_active_clubs_for_email/1` again and resolve the routed
   `club_id` from that fresh set;
2. resolve the current Person/member again from current Person and Membership
   projections rather than trusting an old `current_member`;
3. rerun page-specific `Authorization` checks;
4. rerun authoritative current group participation and conversation access
   checks where those surfaces depend on them; and
5. return the existing `:forbidden` or `:not_found` distinction so the LiveView
   can clear or leave the private surface instead of retaining the old result.

The connected binding must subscribe before its initial read. A notification
that arrives while the first result and its interests are being installed must
cause conservative reconciliation. Fresh mount and reconnect read current
projections. This mitigates mount/reconnect races; PubSub remains non-durable
and does not promise recovery of a lost broadcast to an uninterrupted process.

## Per-LiveView read and state matrix

### `MembaWeb.MemberDashboardLive`

| Field | Current repository evidence | Required migration |
| --- | --- | --- |
| Route/session inputs | Session `club_id` and `club_id_source`; path `group_id`; targeted-add path `person_id`; `live_action` selects Conversations, Members, or targeted add. | Pass route identity into the dashboard query while retaining URL section and targeted-add coordination in the LiveView. Route changes reread the same coherent query. |
| Reads and ordinary assigns | `MemberDashboardPresentation.load/4` uses the mount-captured active clubs, `Membership.list_active_members_of_club/1`, discoverable and authoritative participating groups, `Authorization.authorize_manage_members/2`, group members, `Messaging.list_conversations_for_group/1`, conversation access, Person-backed names/initials, represented members' projected role labels, member counts, and group email data. It currently spreads `selected_club`, `current_member`, `groups`, `selected_group`, access flags, `members`, counts, `messages`, `message_rows`, admission candidates, and permission flags across ordinary assigns. | Return that display and authorization data as one dashboard result. Interests include the selected club; exact selected-club authority for the current Person; club-member, discoverable-group, current-person participation, selected-group-member, selected-group-conversation, and represented-member role-assignment collections; represented Person/group/conversation/role identities; current-person permission/access identities; and dependent delivery data only if the final dashboard model actually displays it. The query deliberately does not register the current Person's all-active-clubs collection. Represented-member role interests refresh labels and badges independently of the current actor's manage-members authorization interests. |
| Current subscription/predicate | Calls `load/4` before subscribing. It then refreshes every dashboard result for any `MemberEmailDelivery` notification, regardless of club/message, and for same-club `Group`, `GroupMembership`, `Membership`, `Role`, or `ConversationGroupAccess` notifications. `handle_params/3` also reloads. `Message`, `Person`, and `Club` notifications are not handled. | Subscribe before the connected read and replace only the dashboard result when logical interests match. Add collection interests so a previously absent member/group/conversation can enter and a represented row can leave. Remove the current unscoped delivery refresh unless delivery data remains a real dashboard dependency. |
| Fresh authorization/access transition | Refresh currently reuses `current_identity_clubs`. `:forbidden` raises the existing forbidden treatment; an invalid/missing selected group uses the existing not-found treatment. A route patch already rereads selected-group access. | Rebuild active clubs, current member, manage-members permission, group participation, and selected-group access from the authenticated email on every refresh. Preserve forbidden versus not-found treatment and never retain member or conversation rows after access fails. |
| LiveView-owned transient state | `active_section` and route IDs; targeted member resolution/focus/success preservation; picker open/query/form state; admission/removal operation state; access-request state; command feedback, flash, and navigation. | Query refresh must not replace these. Targeted member authorization remains coordinated by the route/LiveView around the coherent dashboard result. |

### `MembaWeb.MemberGroupLive.New`

| Field | Current repository evidence | Required migration |
| --- | --- | --- |
| Route/session inputs | Session `club_id` and `club_id_source`; route params are retained for navigation. | Bind one group-creation context for the routed club. |
| Reads and ordinary assigns | `group_context/3` finds the selected club in mount-captured clubs, finds the current member via `Membership.list_active_members_of_club/1`, and calls `Authorization.authorize_manage_members/2`. Ordinary display assigns are `selected_club` and `current_member`. | The result contains freshly derived selected club/member and manage-members authorization. It depends on selected Club identity, club membership/current Person identity, and current-person role/permission interests. |
| Current subscription/predicate | No `ReadModelChanges` subscription. Preview and submit call command/query APIs directly. | Install subscribe-before-read live binding so delivered membership, Person, Club, or role/permission changes recheck access. The group-name preview is not a projection result assign. |
| Fresh authorization/access transition | Mount failure uses the existing forbidden treatment. Submit-time aggregate authorization loss shows “You no longer have permission…” and navigates to the club group home; authorization-state mismatch keeps the form available to retry. | A query access error must clear/leave this private form using the existing forbidden/private-surface semantics. Task 003 must prove the precise connected transition without changing the established submit-time behavior. |
| LiveView-owned transient state | `route_params`; generated `group_id`; name form input/errors; group-name/email preview; retry key; command result, flash, and navigation. | Never replace these during context refresh. Group projection changes may affect a later explicit preview validation, but must not silently overwrite typed input or preview state. |

### `MembaWeb.MySettingsLive`

| Field | Current repository evidence | Required migration |
| --- | --- | --- |
| Route/session inputs | Session `club_id`; `live_action` selects profile, clubs, or emails. | Bind one settings result while the LiveView continues to own tab routing. |
| Reads and ordinary assigns | `Membership.get_club/1`, `Membership.get_person_by_email/1`, `Membership.list_active_club_memberships_for_person/1`, and `Membership.list_person_email_addresses/1` populate `selected_club`, `current_person`, `current_person_clubs`, and `current_person_email_addresses`. | Return all four as one coherent settings model. Interests include selected Club identity, current Person identity and email collection, and the current Person's active club-membership collection (including represented Club identities). |
| Current subscription/predicate | Reads selected club and current Person before subscribing, so this is not a complete subscribe-before-query binding. It handles only Person projector email-address event families for the current Person and refreshes only email rows. Club membership chips, Person basics, selected Club, and access are not refreshed. | Subscribe before the complete read. Exact Person and collection interests update email rows and Person display together; club membership collection interests detect a newly joined or departed club. |
| Fresh authorization/access transition | Mount failure uses forbidden treatment. The selected club is fetched by ID but open-page active membership is not rechecked. | Freshly resolve active clubs and current Person from the authenticated email. Losing selected-club membership must clear/leave the private member surface with existing forbidden semantics; do not keep settings data merely because the route plug authorized the original request. |
| LiveView-owned transient state | `active_tab`; add-email form contents; validation/error state; verification delivery feedback, flash, and command navigation. | A query refresh replaces only the settings model and preserves the selected tab and in-progress add-email form/errors. |

### `MembaWeb.MemberMessageLive.New`

| Field | Current repository evidence | Required migration |
| --- | --- | --- |
| Route/session inputs | Session `club_id` and `club_id_source`; optional query `group_id`; retained `route_params`. Everyone is the default audience. | Bind one authorized compose-context result for the selected club/audience. |
| Reads and ordinary assigns | `compose_context/4` resolves the selected club from mount-captured clubs, reads active club members to identify the current member, reads active groups for that member, selects the requested/default group, reads active group members, and derives recipient count and audience copy. Ordinary assigns are `selected_club`, `current_member`, `audience_group`, `active_member_count`, and `message_audience`. | Return those values as one result. Interests include selected Club, club-member/current Person identity, current-person participating-group collection, selected Group identity, selected-group-member collection, and represented Persons whose primary-email eligibility affects the recipient count. |
| Current subscription/predicate | Completes `compose_context/4` before subscribing. Same-club `Group`, `GroupMembership`, and `Membership` notifications broadly reload. Person/Club changes are omitted. | Subscribe before read and match scoped interests. Group-member collection entry/exit updates the count even when that Person was not in the prior result; Person email changes for represented recipients can also change recipient eligibility. |
| Fresh authorization/access transition | Reload currently reuses `current_identity_clubs`. Any reload error clears compose context and navigates to the selected group or `/conversations`; mount distinguishes forbidden from not found. Send submission separately reloads context and domain commands perform authoritative checks. | Freshly derive active clubs/member/group participation before every refresh. Preserve the clear-then-navigate access-loss behavior and initial forbidden/not-found distinction. |
| LiveView-owned transient state | Message form subject/body; `compose_state`; sent message ID; send/body errors; retry state; route params, flash, and navigation. | Query refresh must not reset typed text or send/retry state. |

### `MembaWeb.MemberMessageLive.Show`

| Field | Current repository evidence | Required migration |
| --- | --- | --- |
| Route/session inputs | Session `club_id` and `club_id_source`; path `message_id`; optional query `group_id` for return navigation. | Bind one authorized conversation-detail result. |
| Reads and ordinary assigns | `MemberMessageDetail.load/3` resolves a selected active club, current Person/member, root message and club ownership, authoritative conversation access, conversation messages, author Person summaries, exact conversation follow state, and member delivery receipts/summaries. `Messaging.list_member_email_deliverys/1` reads the member receipt projection and left-joins the independently committed staff delivery projection for `reason`. These are currently spread over `selected_club`, `message`, `sender_name`, `current_member`, follow flags, `conversation_entries`, and delivery assigns. | Return the complete detail model under one assign. Interests include selected Club; exact current membership, selected-club authority for the current Person, and current group participation; exact conversation and its message collection; represented author Person identities; exact current-member follow identity; exact message delivery collections contributed by both `MemberEmailDelivery` status and `MembaStaffEmailDelivery` reason rows; and exact plus conversation-wide access identities that authorize the result. The query deliberately does not register the Person's all-active-clubs collection. Another member joining/leaving the same club or group cannot alter this result, so the detail query does not register club-member or group-member collections. |
| Current subscription/predicate | Loads before subscribing. Exact `MemberEmailDelivery` changes refresh when `message_id` matches, but `MembaStaffEmailDelivery` reason changes are not handled; `Message` refreshes when `conversation_id` matches; follow refreshes by conversation; same-club Membership/GroupMembership changes refresh only when `person_id` is current member; ConversationGroupAccess refreshes the exact conversation. | Subscribe before read. Keep exact identity matching, plus collection scope for a newly posted reply. Treat both delivery projectors as independent contributors: either notification rereads the joined result, and the later commit notification converges it regardless of projector commit order. Recompute interests when messages/authors or delivery rows change. |
| Fresh authorization/access transition | Loader uses mount-captured active clubs. Access notifications rerun the loader and navigate to the selected group or `/conversations` on any error. Other matching detail notifications currently raise forbidden/not-found on reread errors. | Every relevant refresh reruns fresh active-club, current-member, group-participation, and conversation-access checks. Any access failure must remove the private result and preserve the existing leave-private-surface behavior rather than retaining stale conversation content. |
| LiveView-owned transient state | Reply form/body/errors/state; follow command feedback; expanded receipt groups; route params, flash, and navigation. | Preserve all of these when the detail result is replaced. |

### `MembaWeb.MemberMessageDeliveryLive.Show`

| Field | Current repository evidence | Required migration |
| --- | --- | --- |
| Route/session inputs | Session `club_id` and `club_id_source`; path `message_id`; optional query `group_id`. | Bind one authorized delivery-detail result. |
| Reads and ordinary assigns | Reuses `MemberMessageDetail.load/3`, including selected club/current member, message and access, author names, conversation entries/follow data, and member receipt rows/count/summary/groups. `Messaging.list_member_email_deliverys/1` joins each member receipt to the separately projected staff delivery row whose `reason` is rendered for delivery problems. The delivery template primarily consumes message metadata and receipt presentation. | Return a coherent authorized delivery model under one assign. Shared loader code is acceptable, but this binding owns exact message-delivery collection and delivery-identity interests for both the member status and staff reason projections, and only exposes data justified by the delivery surface. |
| Current subscription/predicate | Loads before subscribing. It handles only same-club Membership, GroupMembership, and exact ConversationGroupAccess access changes. It handles neither `MemberEmailDelivery` status nor `MembaStaffEmailDelivery` reason notifications, so an open delivery page does not refresh as either webhook-driven projection commits. | Subscribe before read. Exact message-delivery invalidation from either independently committed projector must update receipt rows, reasons, grouping, counts, and percentages. A refresh after the first projector commits need not contain the other's later commit; the second projector's notification must trigger another exact-message reread so the joined result converges in either order. Preserve access invalidations and represented Person identities. |
| Fresh authorization/access transition | Access refresh reuses mount-captured active clubs and navigates to the selected group or `/conversations` on error. Initial mount distinguishes forbidden/not found. | Freshly derive active club/member/group/conversation access on every refresh and preserve the existing leave-private-surface transition. |
| LiveView-owned transient state | Route params, native `<details>` disclosure state where the browser retains it, flash, back-link context, and navigation. | Query replacement must not introduce LiveView state that resets unrelated disclosure/navigation state. |

### `MembaWeb.MemberInvitationLive.New`

| Field | Current repository evidence | Required migration |
| --- | --- | --- |
| Route/session inputs | Session `club_id` and `club_id_source`; optional `group_id` is retained for return navigation. | Bind one invitation-context result for the routed club. |
| Reads and ordinary assigns | `invitation_context/3` resolves selected club from mount-captured clubs, reads active club members to identify the current member and count members, and calls `Authorization.authorize_manage_members/2`. Ordinary assigns are `selected_club`, `current_member`, and `active_member_count`. | Return those values as one result. Interests include selected Club, club-member collection (entry/exit changes count), current Person, and current-person role/permission identity. |
| Current subscription/predicate | No `ReadModelChanges` subscription; authorization and count are mount-only. | Install subscribe-before-read binding. Membership additions/removals update count even for previously absent rows; current-member membership/role changes trigger a fresh access decision. |
| Fresh authorization/access transition | Mount failure uses forbidden treatment. Submit relies on the invitation domain/application path and does not refresh the page authorization context first. | Freshly derive active clubs/member/manage-members permission. A delivered access loss must clear/leave the invitation surface with the existing forbidden/private-surface semantics; task 003 must prove the exact connected transition. |
| LiveView-owned transient state | Invitation email form, validation errors, pending/resend decision, delivery feedback, flash, route params, and return navigation. | Preserve typed email and command feedback across successful context refreshes. |

## Projector/event to logical-interest mapping

“Old scope” and “new scope” refer to the collection/identity scope visible in
the source event. Current event families do not move a record between clubs or
groups in one event, so most exact scopes are identical. Where a valid event
does not carry the exact interest needed by a query, the adapter must emit an
evidenced, documented conservative key rather than
silently omit invalidation. A missing required identity in a known event is not
a new valid variant: recover it where the historical event and committed data
permit, or surface a contract violation. Do not use synthetic partial maps to
justify fallback branches. Audit the fallback column against the actual event
structs and projector paths before implementing it. Duplicate or out-of-order
notifications are possible; for example, the Club projector also publishes
no-op compatibility events that specialized projectors publish.

| Projector / source events | Logical interests emitted | Old scope | New scope | Entry/exit and consumers | Valid broad scope / invalid payload |
| --- | --- | --- | --- | --- | --- |
| `Membership.Projectors.Club`: changing `ClubCreated`, `ClubUpdated`; compatibility no-ops `GroupCreated`, `GroupEmailSlugAssigned`, `ClubRoleDefined`, `ClubRolePermissionGranted`, current/legacy role assignment and removal | Club identity for `club_id` only for create/update. Every compatibility handler returns the unchanged `Ecto.Multi`, so its valid publication is ignored rather than duplicating invalidations owned by Group or Role projectors. | Create/update use `club_id`; an updated event does not carry the old name/slug, but identity is unchanged. Creation has no old row. Compatibility events write no Club, Group, Role, RolePermission, RoleAssignment, or MemberPermission row in this projector. | Same `club_id` for create/update; no changed scope for compatibility no-ops. | Club names/slugs on every result that represents that club. Creation can enter global/staff lists, which are out of scope here. Compatibility publications cause no bound-query reread; the specialized projector's later publication describes any actual write. | `ClubCreated`/`ClubUpdated` require `club_id`. Before returning `:ignore`, Group compatibility events still require club/group IDs; Role definition/permission events require club/role IDs; assignment/removal events require club/membership/person/role IDs. Missing required identity or an unsupported event is a contract violation, not a broad refresh. |
| `Membership.Projectors.Membership`: `ClubMemberAdded`, `ClubMemberRemoved`, legacy `MemberAdded`, legacy `MemberRemoved` | Club-member collection for `club_id`; membership identity; exact selected-club authority relationship for `(club_id, person_id)`; and the all-active-clubs collection for the affected Person. Every valid current event and recovered legacy event emits all four keys. | Add: no active row, but event carries destination `club_id`, `membership_id`, `person_id`. Remove: same carried club/person scope is the departing scope. | Add: same club collection and Person's active-clubs collection now contain the row, and the exact Person/club relationship exists. Remove: the row leaves both collections and the exact relationship no longer exists. | Detects a previously absent club member entering dashboards/counts/settings and represented/current members leaving. Dashboard and conversation detail consume exact selected-club authority, so the same Person changing Membership in another club does not refresh them. Settings will consume the Person-wide collection because it displays all active clubs. Other selected-club queries consume the exact relationship as they migrate. Membership events do not change the Person projection, so they do not invalidate a represented Person identity. | None for a missing person identity. Recover a genuinely historical omission from committed changes or the membership row where possible; if a known Membership notification has a club ID but no recoverable person ID, surface a contract violation, not a scoped or global fallback. Do not treat an unknown/partial map as another projector event. |
| `Membership.Projectors.Person`: `PersonCreated`, `PersonEmailAddressAdded`, `PersonEmailAddressVerified`, `PersonEmailAddressesReplaced`, `PersonPrimaryEmailAddressChanged`, `PersonEmailAddressRemoved` | Exact Person identity and that Person's email-address collection. | No club scope exists. Email events carry Person but generally do not carry a complete prior email collection; old club/group scopes are unavailable. | Same Person identity; new email collection must be reread. | Updates represented names/initials where currently available, settings email rows, authenticated-person resolution, and recipient eligibility/counts for represented group members. A new Person enters member/group results through separate membership events. | No broad fallback: each handled Person event carries `person_id`, and queries register represented/current Person identities. A known event without that identity or an unsupported event is a contract violation, not a new partial variant. |
| `Membership.Projectors.Group`: `GroupCreated`, `GroupEmailSlugAssigned` | Club group/discoverable-group collection for `club_id`; exact Group identity for `group_id`. | Creation has no prior row; email-slug assignment has the same group identity and no old slug in the event. | `club_id` and `group_id` carried by both events. | `GroupCreated` lets a previously absent discoverable/participating group enter dashboard and compose choices; identity changes update selected-group display/email. | No missing-ID fallback: both Group events carry `club_id` and `group_id`. Missing required identity or an unsupported event is a contract violation. |
| `Membership.Projectors.GroupMembership`: `GroupMemberAdded`, `GroupMemberRemoved` | Group-member collection for `group_id`; current-person participating-group collection for `(club_id, person_id)`; exact group-participation authorization relationship. | Add: no active row but destination club/group/person is carried. Remove: the carried club/group/person is the departing scope. | Same club/group scope after add; no active row after removal. | Detects absent members entering counts/lists and represented members leaving; changes discoverability, compose authorization, dashboard surfaces, and conversation authorization for the affected person. Group-membership events do not change the Person projection, so they do not invalidate a represented Person identity. | No missing-ID fallback: both GroupMembership events carry club, group and person identities. A malformed known event is a contract violation. |
| `Membership.Projectors.Role`: `ClubRoleDefined`, `ClubRolePermissionGranted`, exact assignment/removal events, and membership-removal compatibility events | Definition emits exact Role identity plus the club-role collection because it changes a Role row. Permission grant emits only the club-permission collection because it changes RolePermission and may reconcile MemberPermission rows for many active memberships. Exact assignment/removal and current/legacy membership removal emit only exact member-role and member-permission relationships for the affected `(club_id, membership_id, person_id)`. | Exact `ClubRoleAssignedToMember`/`ClubRoleRemovedFromMember` and legacy role assignment/removal events carry `club_id`, `membership_id`, `person_id`, and `role_id`; assignment has no active assignment, while removal identifies the one departing assignment. `ClubMemberRemoved` carries club/membership/person but no `role_id`; legacy `MemberRemoved` requires only membership and may omit club/person. | Definition inserts/updates Role. Permission grant inserts RolePermission and can rebuild permissions for multiple members, but does not change Role. Exact assignment/removal changes one RoleAssignment plus that membership's flattened permissions, but does not change Role. Both membership-removal events deactivate all assignments and remove permissions for only that membership. | Exact role assignment/removal refreshes the affected represented member's labels/badges and, when that member is the current actor, rechecks exact authorization. Membership removal invalidates only that membership's labels and permissions. Definition refreshes club role consumers; permission grant deliberately fans out to same-club permission consumers, never another club. | `ClubMemberRemoved` and historic `MemberRemoved` remove every role for one membership; never invent `role_id` or emit club-wide permission scope. The legacy event may genuinely omit club/person, so recover these from the retained membership row. If scope is unrecoverable, surface the contract violation. Definition, permission and exact assignment events require all real identifying fields even when an ID is not emitted as an invalidation. |
| `Messaging.Projectors.Message`: `MessageSent` for roots and replies | Exact message identity; conversation-message collection for derived `conversation_id` (`event.conversation_id` or root `message_id`); club conversation collection. | New message has no prior row. The event carries club and exact/derivable conversation, but no audience `group_id`. | Same club and derived conversation now contain the new message. | A new root can enter the dashboard's root-time-ordered conversation collection and enters conversation detail. A reply enters conversation detail and updates dashboard-derived reply count, latest replier, and participants, but does **not** reorder dashboard rows: ordering and displayed `sent_at` remain the root's `inserted_at`. Author Person identity is registered after reread. | `MessageSent` genuinely lacks audience group: emit the club-conversation collection alongside exact conversation/message keys. Its club/message identities are required; an absent one is a contract violation, not a fallback variant. |
| `Messaging.Projectors.ConversationGroupAccess`: `ConversationAccessGrantedToGroup`, `ConversationAccessRevokedFromGroup` | Exact conversation-access identity; group conversation collection for `group_id`; exact Conversation identity for conversation-wide authorization. | Grant is an upsert: the relationship may be absent, or an existing conversation/group grant may already have a lower/different access level; the event identifies the relationship but does not carry that prior level. Revoke carries `club_id`, `group_id`, and `conversation_id` for the departing relationship. | Grant uses the carried relationship with its new access level; revoke leaves it. | A new grant or access-level replacement can make a conversation enter/leave a selected group's readable dashboard collection; revoke removes it. Every change forces fresh access for conversation/delivery detail. The access projector does not change the Group projection, so an unselected represented Group identity does not invalidate the query. | Both events identify the club, group and conversation. A grant may replace a prior access level, so invalidate the group collection, exact access identity, and conversation-wide authorization without knowing the old level. Missing required identities are invalid; do not add partial-relationship fallbacks. |
| `Messaging.Projectors.ConversationFollow`: `ConversationFollowed`, `ConversationUnfollowed`, and auto-following `MessageSent` | Exact follow identity `(conversation_id, member_id)`. | Same conversation/member; prior following value is not needed. For root `MessageSent`, conversation derives from message ID. | Same conversation/member with the new following value. | Updates only that member's follow state on conversation detail. It does not change the conversation projection, grant access or create delivery eligibility. | Follow/unfollow events carry both identities; auto-following `MessageSent` supplies sender and a root/explicit conversation ID. When `sender_follows_conversation: false`, its projection is a no-op and must not invalidate follow state. Missing required identities are invalid, not partial-scope variants. |
| `Messaging.Projectors.MemberEmailDelivery`: `EmailDeliveryCreated`, `EmailDeliveryDelivered`, `EmailDeliveryDelayed`, `EmailDeliveryBounced`, `EmailDeliverySpamComplaint`; replay-only no-op `EmailDeliveryOpened` | Exact message-delivery collection for `message_id`; exact delivery identity for `delivery_id`; member receipt-status contributor. | Creation has no prior receipt. Status events keep the same message/delivery scope; prior status is not carried. | Same message/delivery with inserted or updated member-facing status. | Receipt rows enter on creation and move between derived status groups/counts on status changes. Its rows are the left side of the joined result consumed by conversation and delivery detail. | Each handled delivery event requires `message_id` and `delivery_id`. `EmailDeliveryOpened` is a replay-only no-op: do not create a new delivery-status transition. No evidence here supports a missing-message delivery event; do not retain row-lookup or broad-family fallback without a real historical example. A known malformed event is a contract violation. |
| `Memba.Messaging.Projectors.MembaStaffEmailDelivery`: `EmailDeliveryCreated`, `EmailDeliveryDelivered`, `EmailDeliveryDelayed`, `EmailDeliveryBounced`, `EmailDeliverySpamComplaint`; replay-only no-op `EmailDeliveryOpened` | Exact message-delivery collection for `message_id`; exact delivery identity for `delivery_id`; staff deliverability/reason contributor to the member query. | Creation has no prior staff row. Status handlers update by `delivery_id`; the prior status/reason is not carried, but current events do carry `message_id`. | The same delivery has inserted/updated detailed status and `reason`; `Messaging.list_member_email_deliverys/1` left-joins that reason by delivery ID. | Reason changes affect conversation detail's shared delivery model and delivery detail's rendered recipient reason. This projector and `MemberEmailDelivery` commit and publish independently: either notification refreshes the exact-message result, and the later notification must refresh again so status and reason converge regardless of commit order. | Each handled delivery event carries `message_id` and `delivery_id`; either independently committed projector invalidates the exact-message result. `EmailDeliveryOpened` is a replay-only no-op. Do not invent row-lookup/global fallback for missing IDs without historical evidence; surface a malformed known event instead. |

### Query-to-interest coverage

This table makes the preceding event map actionable while leaving concrete
types to task 003.

| Planned binding | Collection scopes (including absent-row entry) | Represented/exact identities | Authorization interests |
| --- | --- | --- | --- |
| Dashboard | Club members; discoverable groups; current-person participating groups; selected-group members; selected-group conversations; represented members' role assignments | Selected Club/Group, represented Persons, roles, and conversations/messages | Exact selected-club current-Person relationship (not the Person-wide active-clubs collection), current membership, current-person club permissions (separate from represented-member label/badge interests), selected-group participation, conversation access |
| Group creation | Current identity's active clubs and selected club membership | Selected Club and current Person/member | Current-person club role/permission |
| Settings | Current Person's active club memberships and email addresses | Current Person, selected and represented Clubs | Selected-club current membership |
| Message compose | Club members; current-person participating groups; selected-group members | Selected Club/Group and represented current/recipient Persons | Current club membership and selected-group participation |
| Conversation detail | Conversation messages; exact message delivery collections from both member-status and staff-reason projections; no club-member, group-member, or Person-wide active-clubs collection | Selected Club, current membership, current Person, conversation/root message, represented message authors, exact follow, exact delivery IDs | Exact selected-club current-Person relationship, exact current group participation, exact conversation access, and conversation-wide authorization |
| Delivery detail | Exact message delivery collection from both independently committed delivery projections; conversation messages only if retained in the view model | Selected Club, conversation/root message, represented authors/recipients, exact delivery IDs | Current club/group membership and exact conversation access |
| Invitation | Club members | Selected Club and current Person/member | Current-person club role/permission |

### Accepted-consumer projector audit

The complete production interest sets for the dashboard and conversation
detail are exercised against representative valid notifications from every
recognized projector family. The intersections below are the expected exact
matches; “ignore” means the notification has no intersection with that
query's interests.

| Projector family | Dashboard intersection and result | Conversation-detail intersection and result |
| --- | --- | --- |
| Club | `club` refreshes the represented selected Club. | `club` refreshes the represented selected Club. |
| Membership | A selected-club current-Person change intersects `club_members` and `person_club`; another selected-club Person intersects only `club_members`; the current Person in another club is ignored. | A selected-club current-Person change intersects only `person_club`; another selected-club Person and the current Person in another club are ignored. |
| Person | Exact represented `person` refreshes; another Person is ignored. | Exact current/author `person` refreshes; another Person is ignored. |
| Group | `club_groups` and represented `group` refresh. | Ignored because detail does not display a Group projection row. |
| GroupMembership | Current selected-group participation intersects `group_members`, `person_groups`, and exact `group_participation`. | Only exact current `group_participation` intersects; another participant is ignored. |
| Role | Same-club permission fan-out intersects `club_permissions`; definitions and exact represented/current relationships retain their narrower keys. | Ignored because detail has no Role or permission dependency. |
| Message | A new reply intersects exact `conversation`, `conversation_messages`, and the deliberate `club_conversations` scope required because `MessageSent` has no audience group. | A new reply intersects exact `conversation` and `conversation_messages`. |
| ConversationGroupAccess | Intersects selected `group_conversations`, exact `conversation_access`, and conversation-wide `conversation` authorization. | Intersects exact `conversation_access` and deliberate conversation-wide `conversation` authorization. |
| ConversationFollow | Ignored because dashboard does not display follow state. | Exact current-member `conversation_follow` refreshes; another member's follow is ignored. |
| MemberEmailDelivery | Ignored because dashboard displays no delivery result. | Exact `message_deliveries` and represented `delivery` refresh the joined member status. |
| MembaStaffEmailDelivery | Ignored because dashboard displays no delivery result. | Exact `message_deliveries` and represented `delivery` refresh the independently committed staff reason. |

## Focused proof and remaining gaps

The listed evidence is current proof, not proof of the future package binding.
Tests that call a helper to inject `{:read_model_changed, ...}` directly are
synthetic even when they first mutate a projection.

| Binding | Existing focused evidence | Remaining proof required by iteration 067 |
| --- | --- | --- |
| Dashboard | `member_dashboard_live_test.exs` covers synthetic group discovery, group-membership access loss, route-patch rechecks, current-actor role loss, conversation-access removal, member rows/counts, routing, and **initial-render** role badges for represented members. It does not prove an already-open dashboard updates those badges. `member_dashboard_admission_live_test.exs` has the strongest integration proof: a real admission command commits projectors, PubSub reaches another member's already-open dashboard, and the view gains access/rows/count without navigation. | Implement the shared binding and one-result assign; prove subscribe-before-read/bind reconciliation and reconnect; prove club-member add/remove and reorder/derived counts; prove Person changes; prove live represented-member role assignment/removal and role-label changes update badges independently of current-actor permission invalidation; prove unrelated club/query isolation and transient-state preservation. The stakeholder scenario in `live_club_member_list.feature` is still `@todo`: Bob's open club member list must show Alice after she becomes a club member. This is distinct from the existing custom-group admission proof. |
| Group creation | `member_group_live/new_test.exs` covers route/mount authorization, preview behavior, submit-time permission loss, authorization-state mismatch, and keeping form input/retry state on failures. | No open-page projection subscription exists. Prove delivered membership/role loss uses fresh authority, Club/Person display refresh where relevant, and successful unrelated context refresh leaves generated identity, typed name, preview, and errors untouched. |
| Settings | `my_settings_live_test.exs` covers tab routing and a matching Person email notification while an unrelated Person notification is ignored; email commands update rows. Notification proof is synthetic. | Prove one-result replacement, live active-club membership chips, Person basics, selected-club membership loss, exact Person isolation, form/error preservation, bind race, and reconnect. |
| Message compose | `member_message_live/new_test.exs` covers a synthetic group-membership access-loss notification and private-metadata removal. `new_send_test.exs` covers submission-time authorization rechecks, form preservation across validation/failure/retry, and fail-closed behavior while departure projections lag. | Prove live member-count entry/exit, Person/email recipient eligibility, Group/Club changes, fresh active clubs rather than mount-captured clubs, one-result replacement without resetting the form/send state, bind race, and reconnect. |
| Conversation detail | `member_message_live/show_test.exs` covers access loss after group-membership removal and conversation-access revocation plus follow UI; `show_reply_test.exs` covers reply refresh and follow commands. Existing notification helpers are mostly synthetic even where a command also ran. Current exact delivery handling covers `MemberEmailDelivery`, not the independently committed `MembaStaffEmailDelivery` reason contributor. | Prove all contributing projectors through query interests: new replies, represented author changes, exact follow, exact member receipt status, exact staff delivery reason, and two-projector convergence in either commit order; also prove unrelated conversation/club/message isolation, fresh authorization, transient reply/disclosure preservation, bind race, and reconnect. |
| Delivery detail | `member_message_delivery_live/show_test.exs` covers initial receipt/reason presentation and access-loss navigation after group-membership removal or conversation-access revocation. | There is no proof—and no current handler—that webhook-driven `MemberEmailDelivery` or `MembaStaffEmailDelivery` commits update an already-open delivery page. Add exact-message live status/reason/group/count proof, independent-projector convergence in either commit order, unrelated-message isolation, fresh authorization, bind race, and reconnect. |
| Invitation | `member_invitation_live/new_test.exs` covers routed/mount authorization and form shape; `send_test.exs` covers invite/resend/active-member rules. | No open-page subscription exists. Prove member count entry/exit, delivered membership/role revocation with fresh authority, form preservation, unrelated club isolation, bind race, and reconnect. |

## Explicitly deferred and out-of-scope surfaces

### Staff LiveView session

Every route in `live_session :memba_staff` remains unchanged. Stream-backed
staff modules keep Phoenix streams and any existing `ReadModelChanges`
subscription or hand-written refresh. Iteration 067 does not add a stream
adapter and does not convert these pages to ordinary query-result assigns.

| Staff route(s) | Module | Current collection mechanism | 067 decision |
| --- | --- | --- | --- |
| `/admin/clubs` | `MembaWeb.Admin.ClubsLive.Index` | `stream(:clubs, ...)` | Deferred unchanged. |
| `/admin/requests`; `/admin/requests/:request_id` | `MembaWeb.Admin.RequestsLive.Index` | `stream(:active_requests, ...)`, `stream_delete/3` | Deferred unchanged. |
| `/admin/people` | `MembaWeb.Admin.PeopleLive.Index` | `stream(:people, ...)` | Deferred unchanged. |
| `/admin/clubs/:club_id` | `MembaWeb.Admin.ClubsLive.Show` | `stream(:people, ...)` and `stream(:members, ...)` | Deferred unchanged. |
| `/admin/clubs/:club_id/invitations/new` | `MembaWeb.Admin.ClubMemberInvitationsLive.New` | Form/ordinary assigns; staff surface, not a member LiveView | Out of scope unchanged. |
| `/admin/clubs/:club_id/people/new` | `MembaWeb.Admin.PeopleLive.New` | Form/ordinary assigns; staff surface | Out of scope unchanged. |
| `/admin/clubs/:club_id/people/:person_id/edit` | `MembaWeb.Admin.PeopleLive.Edit` | Form/ordinary assigns; staff surface | Out of scope unchanged. |
| `/admin/deliveries` | `MembaWeb.Admin.DeliveriesLive.Index` | `stream(:deliveries, ...)`; hand-written `ReadModelChanges` refresh | Deferred unchanged. |
| `/admin/messages` | `MembaWeb.Admin.MessagesLive.Index` | `stream(:messages, ...)` | Deferred unchanged. |
| `/admin/messages/:message_id` | `MembaWeb.Admin.MessagesLive.Show` | `addressed_recipients`, `delivery_records`, and `member_email_deliverys` streams; hand-written `ReadModelChanges` refresh | Deferred unchanged. |

The stream-backed deferred modules are therefore
`Admin.ClubsLive.Index`, `Admin.RequestsLive.Index`,
`Admin.PeopleLive.Index`, `Admin.ClubsLive.Show`,
`Admin.DeliveriesLive.Index`, `Admin.MessagesLive.Index`, and
`Admin.MessagesLive.Show`.

### Other surfaces

| Category | Examples/evidence | 067 decision |
| --- | --- | --- |
| Public | `MembaWeb.PublicClubPageLive`, home/about/get-started/terms/privacy routes | Out of scope; public club pages and static/public content do not adopt the member live-query binding. |
| Auth and onboarding | `MembaWeb.AuthLive.SignIn`, `MembaWeb.AuthLive.Onboard`, auth callbacks | Out of scope; identity/session workflows are not projection-backed member display queries. |
| Controllers and static/email rendering | Invitation/profile callbacks, email verification, stop-follow controller, webhook controllers, page controllers, email templates | Out of scope; the plan excludes non-LiveView consumers and email rendering. |
| Other non-member LiveViews/dev tooling | LiveDashboard, mailbox preview, test-support endpoints | Out of scope. |
| Staff forms using ordinary assigns | Staff invitation and Person new/edit modules listed above | Still out of scope because scope is selected by member surface, not merely by assign mechanism. |

## Task 003 handoff constraints

- Prove dashboard and conversation detail first, including route/access
  transitions and notification arrival across initial interest installation,
  before freezing the generic package API.
- Preserve one coherent dashboard result.
- Keep Memba projector/event translation and fresh authorization in the app;
  the local package must not import Memba or Commanded.
- Treat the interest labels in this document as responsibilities and evidence,
  not frozen data structures.
- Correction for task 008A: use a broader interest only for a valid event
  whose shape cannot identify a narrower collection, such as `MessageSent`
  without audience group, role/permission fan-out, membership-removal
  compatibility events without `role_id`, and exact Person events with no
  club scope. Do not add missing-identity or delivery-row-lookup fallbacks
  without evidence of a valid historical event; a malformed known notification
  is a contract violation, not a reason to refresh unrelated queries.
- Treat `MemberEmailDelivery` status and `MembaStaffEmailDelivery` reason as
  independently committed contributors to the same joined detail result; each
  notification must refresh so the later commit converges in either order.
- Do not infer durability from PubSub and do not extend this work to streams.
