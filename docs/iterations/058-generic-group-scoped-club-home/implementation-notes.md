# Implementation notes

## 001 Existing group projection and Messaging query inspection

### Membership read models

- `Memba.Membership.Projections.Group` stores one club-scoped group definition
  keyed by `group_id`, with `club_id`, optional immutable `email_slug`, optional
  `group_key`, and `name`. Database constraints make `group_key` and
  `email_slug` unique within a club when present.
- `Memba.Membership.Projections.GroupMembership` stores one current-state row
  per `(group_id, membership_id)`, denormalising `club_id` and `person_id` and
  toggling `active` on removal/re-addition. The active club/group and
  club/person indexes already support both selected-group member lookup and a
  future person-to-groups query.
- Both projectors use `Commanded.Projections.Ecto` with `consistency: :strong`
  and publish committed changes through `Memba.ReadModelChanges`.
- Groups have no separate active flag or deletion lifecycle. In the current
  model, “active group” means a projected group reached through an active group
  membership whose underlying club membership is also active.

### Existing public Membership queries

- `get_group/1` and `get_group_by_email_slug/2` return plain maps rather than
  projection structs. The slug lookup is club-scoped; the ID lookup is not.
- `list_active_members_of_group/1` joins group memberships to the matching
  underlying membership by membership, club, and person IDs. It requires both
  rows to be active, joins the person and primary email projections, preserves
  the existing role summaries, and orders members by name then person ID.
- `active_member_of_group?/2` uses the same three-column relationship and both
  active flags for a group/person authorization check.
- There is no public query that lists the active groups for a supplied
  club/member/person combination. Existing group queries also do not return
  active member counts or validate a group ID and current member against an
  independently supplied club ID in one boundary call. Those are the seams for
  tasks 002–003; web code must continue to avoid Membership projection aliases.

### Messaging access projection and queries

- `Memba.Messaging.Projections.ConversationGroupAccess` stores one current
  grant per `(conversation_id, group_id)`, including `club_id` and either
  `"read"` or `"write"`. The strong projector upserts grants, deletes revoked
  grants, and publishes committed read-model changes.
- `list_conversations_for_group/1` joins the supplied group to access grants for
  roots, reply counts, latest replies, and participants. Every join also
  matches the message and grant `club_id`; both read and write grants are
  readable. It preserves the club-query presentation shape and orders roots by
  insertion time then message ID, newest first.
- `list_conversation_messages_for_group/2` resolves a root from either a root
  or reply ID, then requires a same-club read-capable grant before returning the
  root and replies.
- `group_has_conversation_access?/3` applies the read/write implication rule,
  while reply authorization finds every same-club write-granted group and
  accepts an active member of any one of them. This already supports a future
  conversation shared with several groups.
- Group-scoped Messaging read queries deliberately do not authorize a person;
  their public documentation leaves that decision to the caller. Current web
  dashboard/detail callers pass the deterministic Everyone group, so Admin
  conversations remain hidden pending the later iteration tasks.
- `send_club_message/2` currently accepts `club_id` and
  `audience_group_id` independently and resolves recipients from the group ID
  alone. It does not first verify through Membership that the group belongs to
  the supplied club. This is the fail-closed invariant gap reserved for tasks
  016–017, not part of this inspection task.

### Architecture constraints carried forward

- ADR 0007 requires Messaging and web callers to use Membership's public query
  API instead of importing Membership projection schemas.
- ADR 0009 keeps these tables as query-side projections rather than domain
  write models.
- ADRs 0021–0022 require committed read-model publication and projection
  barriers where later behaviour needs synchronization; the existing strong
  group and access projectors already participate in those mechanisms.
