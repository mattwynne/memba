# Iteration 027 Implementation Review

## Decision: **ACCEPT** with bounded-safe fixes recommended

## Confidence: **High**

## ADR Conformance: **PASS**

The implementation correctly adheres to ADR 050 (Club Membership Administrator Role). All key architectural decisions are implemented as specified:

- ✅ Event-sourced role/permission model with four events and four commands
- ✅ Club aggregate owns role creation and permission grants
- ✅ Membership aggregate owns role assignments
- ✅ Default role creation during onboarding conversion via application service
- ✅ Flattened permission projection for efficient checks
- ✅ Last-administrator invariant enforced in aggregate
- ✅ Staff authorization remains separate from club permissions

---

## ADR Violations

**None.** The implementation conforms to ADR 050 and does not conflict with other established ADRs.

---

## Blocking Issues

**None.** The implementation passes all automated tests, covers the planned scope, and works correctly for the current iteration's constraints (single role, single permission).

---

## Bounded-Safe Fixes

### 1. Permission projection rebuild on role unassignment

**File:** `web/lib/memba/membership/projections/club_member_permission_projection.ex`

**Issue:** The `ClubRoleUnassigned` handler deletes permissions based solely on the role's permission list, without checking if other role assignments grant the same permission. This will cause incorrect permission removal when multiple roles grant overlapping permissions (planned for future iterations).

**Current code:**
```elixir
def project(%ClubRoleUnassigned{} = event, _metadata, multi) do
  query = """
  DELETE FROM club_member_permissions
  WHERE club_id = $1::uuid
    AND membership_id = $2::uuid
    AND permission IN (
      SELECT permission
      FROM club_role_permissions
      WHERE role_id = $3::uuid
    )
  """
  # ... deletes without checking if permission exists via other assignments
end
```

**Fix:** Rebuild the member's entire permission set after unassignment to ensure correctness:

```elixir
def project(%ClubRoleUnassigned{} = event, _metadata, multi) do
  Multi.run(multi, {:rebuild_permissions, event}, fn repo, _changes ->
    # Delete all current permissions for this member
    repo.delete_all(
      from p in ClubMemberPermission,
        where: p.club_id == ^event.club_id and p.membership_id == ^event.membership_id
    )

    # Rebuild from all current assignments
    rebuild_query = """
    INSERT INTO club_member_permissions (club_id, membership_id, person_id, permission, inserted_at)
    SELECT DISTINCT
      cra.club_id,
      cra.membership_id,
      m.person_id,
      crp.permission,
      $1::timestamp
    FROM club_role_assignments cra
    JOIN club_role_permissions crp ON crp.role_id = cra.role_id
    JOIN memberships m ON m.membership_id = cra.membership_id
    WHERE cra.club_id = $2::uuid
      AND cra.membership_id = $3::uuid
    """

    case repo.query(rebuild_query, [DateTime.utc_now(), event.club_id, event.membership_id]) do
      {:ok, _result} -> {:ok, :rebuilt}
      error -> error
    end
  end)
end
```

**Rationale:** This ensures permissions are correctly derived from all active role assignments, preventing permission loss when unassigning one of multiple roles that grant the same permission. The performance impact is minimal (single-member rebuild) and prevents future bugs.

### 2. Test coverage for overlapping role permissions

**File:** `web/test/memba/membership/projections/club_member_permission_projection_test.exs`

**Issue:** No test coverage for the scenario where a member has multiple roles granting the same permission.

**Fix:** Add test case:

```elixir
describe "ClubRoleUnassigned with overlapping permissions" do
  test "preserves permission when member has other role granting same permission" do
    # Setup: Create two roles, both granting "club.manage_members"
    # Assign both roles to same member
    # Unassign one role
    # Assert: member still has "club.manage_members" via the remaining role
  end
end
```

---

## Judgement-Worthy Non-Blocking Code-Health Findings

### 1. Hard-coded role name for last-administrator check

**Files:** `web/lib/memba/membership/membership.ex` (line ~250)

**Smell:** String literal "Membership Administrator" used to identify admin role in business logic

**Code:**
```elixir
defp validate_not_last_administrator(club_id, membership_id, role_id, command) do
  case Memba.Membership.get_role_name(club_id, role_id) do
    "Membership Administrator" ->  # Magic string
      # Check count...
```

**Why it needs judgement:** This creates implicit coupling between aggregate validation and role naming. If role names become user-customizable or if the admin role is identified by other means (role type enum, permission-based check, system flag), this will break. Options:

- Add a `role_type` field (`:system_admin`, `:custom`) and check type instead of name
- Check if role has the `club.manage_members` permission (permission-based semantics)
- Add a `is_system_role` boolean flag

The current approach works but assumes role names are stable identifiers. Future role customization iterations should revisit this.

### 2. Raw SQL in permission projections

**Files:** `web/lib/memba/membership/projections/club_member_permission_projection.ex`

**Smell:** Raw SQL queries instead of Ecto query syntax or changesets

**Why it needs judgement:** Trade-off between performance and maintainability. Raw SQL is faster for bulk inserts with complex joins, but:

- Less type-safe (no compile-time query validation)
- Harder to test query logic in isolation
- Requires manual parameter escaping vigilance
- Database-specific (though Postgres-only is acceptable for Memba)

The current implementation is defensible for projection performance, but sets a precedent. Consider whether complex projections should use Ecto.Multi with `Repo.insert_all/3` and composed queries instead.

### 3. Untyped permission identifiers

**Files:** Throughout codebase (`"club.manage_members"` string literal)

**Smell:** Permission identifiers are strings without compile-time safety

**Why it needs judgement:** Typos in permission strings (`"club.manage_member"` vs `"club.manage_members"`) won't be caught until runtime. Options:

- Module constants: `@permission_manage_members "club.manage_members"`
- Ecto enum type with database CHECK constraint
- Centralized permission registry module

The dotted-string format is extensible and simple, but future iterations adding many permissions might benefit from typed identifiers. Current approach is acceptable for the single-permission case.

### 4. Silent idempotency via ON CONFLICT DO NOTHING

**Files:** `web/lib/memba/membership/projections/club_member_permission_projection.ex`

**Smell:** Projection conflicts are silently ignored

**Why it needs judgement:** The `ON CONFLICT DO NOTHING` clause provides idempotency but hides duplicate projections. This is standard practice for event-sourced projections, but means:

- Bugs in projection logic won't raise errors
- No visibility into replay/reproject frequency
- Difficult to detect projection drift

Consider adding metrics or logging for conflict cases to surface unexpected duplicates. Not a bug, but worth monitoring.

### 5. Multi-command orchestration without compensation

**Files:** `web/lib/memba/membership/application/approve_club_request_application.ex`

**Smell:** Three sequential commands without transactional rollback

**Code:**
```elixir
with :ok <- Router.dispatch(%CreateClubRole{...}),
     :ok <- Router.dispatch(%GrantClubRolePermission{...}),
     :ok <- Router.dispatch(%AssignClubRole{...}) do
  :ok
end
```

**Why it needs judgement:** If `GrantClubRolePermission` or `AssignClubRole` fails, the membership and partial role state persists without compensation. This is a known limitation of event-sourced systems. Options:

- Add Commanded process manager for saga-style compensation
- Emit a single composite event instead of three commands (reduces flexibility)
- Accept eventual consistency and manual recovery

Risk is low (role creation rarely fails), but worth documenting for future complex workflows. The current approach is acceptable for this iteration's scope.

---

## Suggested Fixes

### Immediate (bounded-safe):

1. **Replace permission deletion with rebuild** in `club_member_permission_projection.ex` per fix #1 above
2. **Add test for overlapping role permissions** per fix #2 above

### Future iteration (judgement-worthy):

1. Consider role type/category field instead of name-based admin checks
2. Evaluate Ecto vs raw SQL trade-offs for future projections
3. Add permission constant registry if permission count grows beyond 3-5
4. Add projection conflict monitoring/metrics
5. Document multi-command orchestration limitations for complex workflows

---

## Validation Notes

### Automated coverage: ✅ Excellent
- All ExUnit tests pass
- All 62 acceptance scenarios pass (421 steps)
- Domain events, aggregates, projections, and authorization covered
- Last-administrator invariant tested
- Permission checks tested with both person_id and membership_id

### Plan conformance: ✅ Complete
- All 16 delivery steps implemented
- `@todo-domain`/`@todo-ui` tags removed from feature file
- Default role created during onboarding conversion
- Staff authorization remains separate from club permissions

### ADR conformance: ✅ Pass
- All ADR 050 decisions implemented correctly
- Event sourcing patterns followed
- Projection architecture matches established patterns
- No conflicts with existing ADRs

### Code quality: ✅ Good
- Naming conventions consistent
- Error handling appropriate for event-sourced aggregates
- Test organization clear
- Migrations include proper indexes and constraints

---

## Recommendation

**Accept** this implementation with the two bounded-safe fixes applied before merge. The permission rebuild fix prevents future bugs and is low-risk. The judgement-worthy items are noted for future iterations but should not block this merge.

The implementation successfully delivers the planned capability: club requesters become Membership Administrators upon approval, can assign the role to other members, and the system enforces the last-administrator invariant. The foundation is solid for future role customization work.