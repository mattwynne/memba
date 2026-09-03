# Vision — groups and conversation access

**Date:** 2026-09-02
**Status:** Product vision for iterative delivery — not an implementation plan

## Purpose

Memba currently treats every club message as a conversation for the whole club. This
vision lets a club organise members into smaller sets—such as a Board or Funding
Committee—and gives those sets appropriate access to conversations.

The aim is a coherent long-term model, not a commitment to deliver every capability
at once. Each iteration should make one useful, safe step toward it.

## Core idea

A **group** is a named, club-scoped set of active members. A group can:

- give its members access to conversations;
- grant app-defined permissions, where appropriate; and
- have a stable email address for posting to its conversations.

A **role** is a group used to confer one or more permissions. Some groups, such as
Board, may have no permissions beyond access to their conversations. We do not need
to force a sharper distinction between groups and roles yet.

A person may belong to several groups in the same club. Club administration does not
give someone implicit access to every group: an administrator joins a private group
in order to participate in it.

## System groups

Every club has an implicit **Everyone** group containing all of its active members.
Today’s club-wide messages and inbound club email are the Everyone group’s
conversations. This keeps the existing club-wide experience as a normal case of the
new model rather than a permanent exception.

Membership-administration roles are also groups. They may grant club-management
permissions, but those permissions do not themselves grant access to other groups’
private conversations.

## Conversation access

A conversation has an access rule for each relevant group:

| Access | Meaning |
| --- | --- |
| None | Members of the group have no access through that group. |
| Read | Members of the group can read the conversation. |
| Write | Members of the group can read and post to the conversation. |

Write includes read. A member’s effective access is the strongest access granted by
any group they belong to. Initially, “none” should mean the absence of an access
grant, not an explicit denial that can override another group’s grant.

The model must allow more than one group to have access to a conversation. For
example, Board could write to a budget conversation while Funding Committee can
read it. The first user experience need not expose that flexibility.

## Public reading

**Public** means that anyone on the web can read a conversation on the club’s public
page. It is not a group and never grants writing rights.

Public/private visibility is set when a conversation starts:

1. A club has a default public-reading setting.
2. A group may inherit the club default or set its own default.
3. A new conversation takes the default from the group it starts with.

For now, its visibility is fixed once the conversation exists. Changing a live
conversation from private to public, or the reverse, is a separate future feature.
Changing a club or group default affects only future conversations.

## Email posting

Each group should eventually have a stable inbound email address—for example,
`board@nclt.groups.memba.io`. The final address format is a delivery-design decision;
the important rule is that the address identifies a club and a group.

Inbound email follows the same access rule as in-app posting:

- Memba accepts a new group-addressed message only when the sender is an active
  member of the addressed group. The new conversation grants that group write access.
- A message sent to a group address begins a conversation using that group’s default
  visibility and access.
- A reply is accepted only when its sender belongs to a group with write access to
  the existing conversation; replies retain that conversation’s access and visibility.
- Non-members of the addressed group cannot post, even if they are members of the
  club or hold a club-management role.

Public readers cannot post by email or in the application merely because a
conversation is public.

## Initial behaviour and future shape

The initial group-conversation experience can remain deliberately narrow:

- A new conversation starts with one group.
- That group receives write access.
- Other groups have no access.
- The conversation inherits the group’s public/private default.

The underlying relationship should still support several group access grants from
the outset. Later iterations can add a creation flow that gives multiple groups
read or write access, without redesigning existing conversations.

## Candidate delivery path

This is a proposed sequence, not a committed plan.

1. **Establish Everyone as the normal audience.** Preserve existing club-wide
   behaviour while expressing it through the implicit Everyone group.
2. **Private named group conversations.** Let an authorised club member define a
   named group, assign active members, and start a private conversation for that
   group. Start with one writable group per conversation.
3. **Group email posting.** Route group-addressed email into group conversations and
   require the sender to belong to the addressed group.
4. **Public-read defaults.** Add club and group defaults and render public
   conversations on the public club page.
5. **Shared conversations.** Allow a new or existing conversation to grant read or
   write access to more than one group.
6. **Richer permission bundles and group management.** Grow the set of permissions
   and the interfaces for creating and administering groups only as real club
   workflows require them.

Each slice should preserve privacy by default and avoid making the club-wide
Everyone audience a special case.

## Explicitly out of scope for now

- Changing a conversation’s public/private visibility after it starts.
- External or unauthenticated people posting to group addresses.
- Explicit deny rules that override access granted through another group.
- A UI for starting conversations with several groups at once.
- Deciding the final email-address syntax.
- A general-purpose custom group/role editor or a complete permission catalogue.

## Questions for later discovery

- Which permission lets a member create groups, manage group membership, and start
  conversations for a group?
- Who may change group access to an existing conversation once shared conversations
  are introduced?
- Which first real club workflow should validate private named groups: Board,
  Funding Committee, trip leaders, or another cohort?
- How should public conversations be listed, linked, indexed, and moderated on a
  public club page?
