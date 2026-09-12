# 24. Use Club as the membership and Admin consistency boundary

Date: 2026-09-12

## Status

accepted

## Context

Iteration 059 repairs the invariant that every populated club must have an Admin. The previous membership lifecycle routed activation/removal through membership-id streams while Admin role assignments lived on the Club stream. That split meant first-member Admin assignment and membership activation could not be decided or appended atomically, and projection-backed preflight checks could race.

ADR 0011's caller-generated typed UUID decision remains correct. The part that routed membership lifecycle by `membership_id`, and the part that put duplicate active-membership prevention in a projection preflight, no longer protects the invariant.

## Decision

Use `Memba.Membership.Club` as the consistency boundary for active club membership lifecycle, role assignment, role removal, final-member protection, and Admin continuity.

New writes use explicit command/event vocabulary:

- `AddClubMember` / `RemoveClubMember`
- `ClubMemberAdded` / `ClubMemberRemoved`
- `AssignClubRoleToMember` / `RemoveClubRoleFromMember`
- `ClubRoleAssignedToMember` / `ClubRoleRemovedFromMember`

`AddClubMember` routes by `club_id`. When the Club has zero active club memberships, one aggregate decision emits `ClubMemberAdded` plus `ClubRoleAssignedToMember` for the deterministic Admin role in one append. Later additions emit only `ClubMemberAdded`.

`ClubRoleAssignedToMember.assignment_source` records `"automatic_first_club_member"` or `"explicit_command"`. `assigned_by_person_id` remains available for explicit user actions.

Historic `MemberAdded`, `MemberRemoved`, `MemberRoleAssigned`, and `MemberRoleRemoved` events remain immutable and replayable. New writes do not emit them. Projectors and policies handle both families where compatibility is needed.

## Supersedes

This ADR partially supersedes [ADR 0011](0011-use-caller-generated-uuid-aggregate-identities.md):

- supersedes routing ordinary membership activation/removal by `membership_id`;
- supersedes projection-backed duplicate active-membership preflight as the write invariant; and
- preserves caller-generated typed UUID identities for clubs, people, memberships, messages, and invitations.

## Consequences

The Club aggregate can decide first-member Admin authority, exact idempotent retry, duplicate active membership, inactive role targets, final-member removal, and last-Admin removal from event history instead of projections.

System-group membership remains a downstream, policy-maintained domain consequence used by group queries and messaging. `GroupMemberAdded` and `GroupMemberRemoved` events for Everyone and Admin are not the source of Admin authority and are not part of the atomic first-member claim.

This decision does not make the Club aggregate the intended owner of an unbounded future matrix of arbitrary group memberships. The consistency boundary chosen here covers active club memberships and club-role assignments because those facts participate in the immediate Admin-continuity invariant. The consistency boundary for future arbitrary group membership must be decided around the invariants and concurrency needs of an individual Group.
