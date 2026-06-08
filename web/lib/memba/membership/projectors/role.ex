defmodule Memba.Membership.Projectors.Role do
  @moduledoc """
  Projects club role, role permission, role assignment, and flattened member permission read models.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Membership.App,
    repo: Memba.Repo,
    name: "Memba.Membership.Projectors.Role",
    consistency: :strong

  import Ecto.Query

  alias Memba.Membership.Events.ClubRoleDefined
  alias Memba.Membership.Events.ClubRolePermissionGranted
  alias Memba.Membership.Events.MemberRemoved
  alias Memba.Membership.Events.MemberRoleAssigned
  alias Memba.Membership.Events.MemberRoleRemoved
  alias Memba.Membership.Projections.MemberPermission, as: MemberPermissionProjection
  alias Memba.Membership.Projections.Role, as: RoleProjection
  alias Memba.Membership.Projections.RoleAssignment, as: RoleAssignmentProjection
  alias Memba.Membership.Projections.RolePermission, as: RolePermissionProjection

  project(%ClubRoleDefined{} = event, fn multi ->
    now = DateTime.utc_now(:microsecond)

    Ecto.Multi.insert(
      multi,
      :membership_role,
      %RoleProjection{
        club_id: event.club_id,
        role_id: event.role_id,
        role_key: event.role_key,
        name: event.name,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: [
        set: [
          club_id: event.club_id,
          role_key: event.role_key,
          name: event.name,
          updated_at: now
        ]
      ],
      conflict_target: :role_id
    )
  end)

  project(%ClubRolePermissionGranted{} = event, fn multi ->
    now = DateTime.utc_now(:microsecond)

    multi
    |> Ecto.Multi.insert(
      :membership_role_permission,
      %RolePermissionProjection{
        club_id: event.club_id,
        role_id: event.role_id,
        permission: event.permission,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: :nothing,
      conflict_target: [:role_id, :permission]
    )
    |> Ecto.Multi.run(:membership_member_permissions_from_role_permission, fn repo, _changes ->
      active_assignments =
        repo.all(
          from(assignment in RoleAssignmentProjection,
            where: assignment.role_id == ^event.role_id,
            where: assignment.active == true
          )
        )

      Enum.each(active_assignments, fn assignment ->
        increment_member_permission(repo, assignment, event.permission)
      end)

      {:ok, length(active_assignments)}
    end)
  end)

  project(%MemberRoleAssigned{} = event, fn multi ->
    now = DateTime.utc_now(:microsecond)

    multi
    |> Ecto.Multi.insert(
      :membership_role_assignment,
      %RoleAssignmentProjection{
        club_id: event.club_id,
        membership_id: event.membership_id,
        person_id: event.person_id,
        role_id: event.role_id,
        active: true,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: [
        set: [
          club_id: event.club_id,
          person_id: event.person_id,
          active: true,
          updated_at: now
        ]
      ],
      conflict_target: [:membership_id, :role_id]
    )
    |> Ecto.Multi.run(:membership_member_permissions_from_role_assignment, fn repo, _changes ->
      permissions = role_permissions(repo, event.role_id)

      assignment = %RoleAssignmentProjection{
        club_id: event.club_id,
        membership_id: event.membership_id,
        person_id: event.person_id,
        role_id: event.role_id,
        active: true
      }

      Enum.each(permissions, fn permission ->
        increment_member_permission(repo, assignment, permission)
      end)

      {:ok, permissions}
    end)
  end)

  project(%MemberRoleRemoved{} = event, fn multi ->
    now = DateTime.utc_now(:microsecond)

    multi
    |> Ecto.Multi.update_all(
      :membership_role_assignment,
      role_assignment_query(event.membership_id, event.role_id),
      set: [active: false, updated_at: now]
    )
    |> Ecto.Multi.run(:membership_member_permissions_from_removed_role_assignment, fn repo,
                                                                                      _changes ->
      permissions = role_permissions(repo, event.role_id)

      Enum.each(permissions, fn permission ->
        decrement_member_permission(repo, event, permission)
      end)

      {:ok, permissions}
    end)
  end)

  project(%MemberRemoved{} = event, fn multi ->
    now = DateTime.utc_now(:microsecond)

    multi
    |> Ecto.Multi.update_all(
      :membership_role_assignments,
      membership_role_assignments_query(event.membership_id),
      set: [active: false, updated_at: now]
    )
    |> Ecto.Multi.delete_all(
      :membership_member_permissions,
      member_permissions_by_membership_query(event.membership_id)
    )
  end)

  defp role_permissions(repo, role_id) do
    repo.all(
      from(permission in RolePermissionProjection,
        where: permission.role_id == ^role_id,
        order_by: [asc: permission.permission],
        select: permission.permission
      )
    )
  end

  defp increment_member_permission(repo, assignment, permission) do
    now = DateTime.utc_now(:microsecond)

    repo.insert_all(
      MemberPermissionProjection,
      [
        %{
          club_id: assignment.club_id,
          membership_id: assignment.membership_id,
          person_id: assignment.person_id,
          permission: permission,
          grant_count: 1,
          inserted_at: now,
          updated_at: now
        }
      ],
      on_conflict: [inc: [grant_count: 1], set: [updated_at: now]],
      conflict_target: [:club_id, :person_id, :membership_id, :permission]
    )
  end

  defp decrement_member_permission(repo, event, permission) do
    now = DateTime.utc_now(:microsecond)

    repo.update_all(
      member_permission_query(event.club_id, event.person_id, event.membership_id, permission),
      inc: [grant_count: -1],
      set: [updated_at: now]
    )

    repo.delete_all(
      from(member_permission in MemberPermissionProjection,
        where: member_permission.club_id == ^event.club_id,
        where: member_permission.person_id == ^event.person_id,
        where: member_permission.membership_id == ^event.membership_id,
        where: member_permission.permission == ^permission,
        where: member_permission.grant_count <= 0
      )
    )
  end

  defp role_assignment_query(membership_id, role_id) do
    from(assignment in RoleAssignmentProjection,
      where: assignment.membership_id == ^membership_id,
      where: assignment.role_id == ^role_id
    )
  end

  defp membership_role_assignments_query(membership_id) do
    from(assignment in RoleAssignmentProjection,
      where: assignment.membership_id == ^membership_id
    )
  end

  defp member_permissions_by_membership_query(membership_id) do
    from(member_permission in MemberPermissionProjection,
      where: member_permission.membership_id == ^membership_id
    )
  end

  defp member_permission_query(club_id, person_id, membership_id, permission) do
    from(member_permission in MemberPermissionProjection,
      where: member_permission.club_id == ^club_id,
      where: member_permission.person_id == ^person_id,
      where: member_permission.membership_id == ^membership_id,
      where: member_permission.permission == ^permission
    )
  end

  @impl Commanded.Projections.Ecto
  def after_update(event, metadata, changes) do
    Memba.ReadModelChanges.publish(__MODULE__, event, metadata, changes)
  end
end
