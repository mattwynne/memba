# Minimal role and permission model

This note records the design decision for task 002 of the Membership
Administrator role iteration. It turns the implementation-plan bullets into a
small event-sourced model that later tasks can implement without introducing a
member-facing role editor or custom-role UI in this slice.

## Design goals

- Keep authorization checks permission-based: callers ask whether a member has
  `club.manage_members` in a club, not whether they hold a hard-coded role name.
- Keep the Membership Administrator role as the first role bundle, while leaving
  room for future club-specific custom roles.
- Keep Memba staff authorization separate from club-scoped membership
  authorization. Staff flows may initialize or repair role state without making
  staff implicit club administrators.
- Preserve the event-sourced Membership boundary from ADR 0002 and ADR 0007.
- Use caller-supplied identities where new aggregate identities are needed, per
  ADR 0011.

## Permission primitives

Permissions are app-defined string identifiers, not user-created rows or
aggregates. The first identifier is:

- `club.manage_members` — managing club membership and membership-management
  role assignments for a club.

Implementation should centralize permission identifiers in Membership code
(for example, a small `Memba.Membership.Permissions` module) so commands and
queries validate against a stable allow-list. Events and projections should store
the permission as the stable string identifier.

## Club role definitions

A role is a club-scoped permission bundle.

Proposed role fields:

- `role_id` — caller-generated typed ID. Add a new typed ID prefix for roles
  when implementing this, and use a deterministic role ID for the default
  Membership Administrator role so initialization/backfill can be idempotent.
- `club_id` — owning club.
- `name` — display name, initially `Membership Administrator`.
- `role_key` — optional stable app key for built-in roles. Use
  `membership_administrator` for the default role; leave future custom roles
  with no app key unless a later product decision says otherwise.

The default role is therefore a normal role definition with a stable key, not an
opaque boolean on a member.

## Role permissions

Role-to-permission grants are separate facts from role definition. For this
iteration, the default role receives one permission:

- role `membership_administrator` grants `club.manage_members`.

This separation is intentional. Later custom roles can grant the same permission
without changing authorization queries, and later fine-grained permissions can be
added without changing the role-assignment shape.

## Role assignments

Role assignments link an active club membership to a role.

Proposed assignment fields/events should carry:

- `club_id`;
- `membership_id`;
- `person_id`;
- `role_id`;
- optional actor/cause metadata where useful for audit, such as
  `assigned_by_person_id`, `removed_by_person_id`, or a system/staff cause.

Assignments should be made to memberships, while also storing `person_id` in
events/projections for query efficiency. A new membership period should not
implicitly inherit a role assignment from an older removed membership with a
different `membership_id`.

Only active members can receive role assignments. Because the current
`Membership` aggregate owns one membership stream and the active-membership
uniqueness rule already lives in the public Membership API, the public API should
validate active membership through the Membership projection before dispatching a
role-assignment command.

## Write-side aggregate choice

Use the existing club aggregate stream as the club-scoped role-management
boundary for this first slice.

Rationale:

- role definitions, role-permission grants, and role assignments are all
  club-scoped facts;
- the last-administrator invariant is club-scoped and is easier to enforce when
  role assignments for a club pass through one stream;
- the design avoids introducing multiple assignment aggregates whose independent
  streams could not enforce the zero-administrator invariant without a separate
  process manager or weaker projection-only check;
- club existence is already represented by the `Club` aggregate, and adding
  role state there keeps the write-side model minimal for one default role and
  one permission.

The club aggregate should track enough role state to enforce command rules:

- known role IDs and built-in role keys for the club;
- permissions granted to each role;
- role assignments by `{membership_id, role_id}`;
- the number of active assigned memberships that currently contribute
  `club.manage_members`, so removing the last Membership Administrator can be
  rejected.

Membership activity still comes from the Membership projection before dispatch.
When member-removal authorization is implemented, removing a member whose role
assignment is the last source of `club.manage_members` for the club should be
rejected before the membership is removed.

## Event vocabulary

Later implementation tasks can choose exact command module names, but the event
facts should stay decoupled:

- `ClubRoleDefined`
- `ClubRolePermissionGranted`
- `ClubRolePermissionRevoked` (available for future custom role work; not
  required by the first default-role path unless needed for tests)
- `MemberRoleAssigned`
- `MemberRoleRemoved`

Default Membership Administrator initialization should emit role-definition and
permission-grant facts rather than hiding both in an opaque flag. Assigning the
approved requester should emit a role-assignment fact after membership creation.

## Projection model

Use normalized projections plus a flattened permission projection.

Normalized projections:

- `membership_roles`
  - `role_id` primary key;
  - `club_id`;
  - `name`;
  - `role_key`;
  - timestamps;
  - unique `(club_id, role_key)` where `role_key` is present.
- `membership_role_permissions`
  - `club_id`;
  - `role_id`;
  - `permission`;
  - unique `(role_id, permission)`.
- `membership_role_assignments`
  - `club_id`;
  - `membership_id`;
  - `person_id`;
  - `role_id`;
  - `active`;
  - unique `(membership_id, role_id)`.

Flattened permission projection:

- `membership_member_permissions`
  - `club_id`;
  - `membership_id`;
  - `person_id`;
  - `permission`;
  - `grant_count`;
  - unique `(club_id, person_id, membership_id, permission)`.

`grant_count` keeps the flattened projection correct when future custom roles
grant the same permission to the same member. Assigning a role increments the
flattened row for each permission currently granted to the role. Removing an
assignment decrements and deletes the row when the count reaches zero. Granting a
new permission to a role should add/increment flattened rows for all active
assignments to that role.

The flattened projection should represent currently active membership
permissions. When `MemberRemoved` is projected, rows for that `membership_id`
should be removed so a removed member no longer authorizes as a club member.

## Public query/API shape

Expose permission checks through the Membership public API, not direct projection
access from other contexts:

```elixir
Memba.Membership.member_has_permission?(club_id, person_id, "club.manage_members")
```

Exact names can change during implementation. The important contract is that the
query accepts club/person scope plus a permission identifier and reads from the
flattened Membership permission projection.

## Authorization shape

For club-member role administration, public commands should require an actor
person ID and check `club.manage_members` through the permission query before
dispatching the role-assignment change.

Staff-owned screens remain platform-authorized staff operations. They can call
staff/system-oriented Membership APIs for setup, repair, and onboarding
conversion, but staff status must not be projected as club membership authority.

## Out-of-scope for this design slice

- A custom role editor.
- Fine-grained permissions beyond `club.manage_members`.
- Member-facing invitation UI.
- Making Memba staff implicit members or implicit Membership Administrators.
- Cross-context access to Membership projection tables.
